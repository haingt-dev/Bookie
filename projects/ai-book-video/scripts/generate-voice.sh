#!/usr/bin/env bash
# generate-voice.sh — Generate voiceover từ script text bằng viXTTS (self-hosted)
# Usage: ./scripts/generate-voice.sh <book-slug>
# Generates voiceover per-scene with gap adjustment (no audio stretching).
# Adjusts silence between sentences/paragraphs to approach SRT target timing.
# Auto-syncs SRT timestamps to match actual audio duration.
# Prerequisites: viXTTS server running (./scripts/vixtts-server.sh start)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
VIXTTS_API_URL="${VIXTTS_API_URL:-http://127.0.0.1:8020}"
SPEAKER_NAME="${VIXTTS_SPEAKER:-fonos}"
SILENCE_SENTENCE=0.15     # 150ms between sentences (same paragraph)
SILENCE_PARAGRAPH=0.4     # 400ms between paragraphs/sections
FADE_DURATION=0.02        # minimal fade to prevent clicks
MIN_BATCH_CHARS=100       # batch sentences shorter than this with neighbor

# Gap adjustment bounds (seconds) — used instead of atempo stretch
GAP_SENTENCE_MIN=0.05
GAP_SENTENCE_MAX=0.40
GAP_PARAGRAPH_MIN=0.15
GAP_PARAGRAPH_MAX=1.00
GAP_WEIGHT_PARA=2.5       # paragraph gaps get 2.5x share of budget
VIXTTS_TEMPERATURE="${VIXTTS_TEMPERATURE:-0.85}"
VIXTTS_REPETITION_PENALTY="${VIXTTS_REPETITION_PENALTY:-2.0}"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================
# FUNCTIONS
# ============================================================

apply_voice_settings() {
  local temp="$1" rep="$2"
  local settings
  settings=$(curl -s "$VIXTTS_API_URL/get_tts_settings" | \
    jq --argjson temp "$temp" --argjson rep "$rep" \
       '.enable_text_splitting = false | .temperature = $temp | .repetition_penalty = $rep')
  curl -s -X POST "$VIXTTS_API_URL/set_tts_settings" \
    -H "Content-Type: application/json" \
    -d "$settings" > /dev/null
}

# split_into_units <text> <min_chars> <output_dir>
# Splits text into TTS-friendly units, writes unit-XXX.txt files.
# Also writes voice-overrides.txt and paragraph-breaks.txt.
# Prints the total unit count to stdout.
split_into_units() {
  local text="$1"
  local min_chars="$2"
  local output_dir="$3"
  local unit_num=0
  local paragraph_breaks=""
  local pending_voice=""

  local para=""
  local para_num=0
  local paragraphs=()
  local para_voices=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^\<\!--\ voice:\ (.+)\ --\>$ ]]; then
      pending_voice="${BASH_REMATCH[1]}"
      continue
    fi
    # Skip scene markers
    if [[ "$line" =~ ^\<\!--\ scene: ]]; then
      continue
    fi
    if [[ -z "$line" ]]; then
      if [[ -n "$para" ]]; then
        paragraphs+=("$para")
        para_voices+=("$pending_voice")
        pending_voice=""
        para=""
      fi
    else
      [[ -n "$para" ]] && para="$para "
      para="${para}${line}"
    fi
  done <<< "$text"
  if [[ -n "$para" ]]; then
    paragraphs+=("$para")
    para_voices+=("$pending_voice")
  fi

  for i in "${!paragraphs[@]}"; do
    para="${paragraphs[$i]}"
    local voice="${para_voices[$i]}"
    para_num=$((para_num + 1))
    local is_first_in_para=1

    local sentences=()
    local remaining="$para"
    while [[ -n "$remaining" ]]; do
      local best_pos=-1
      for terminator in ". " "! " "? " ".\n" "!\n" "?\n"; do
        local pos="${remaining%%"$terminator"*}"
        if [[ "$pos" != "$remaining" ]]; then
          local this_pos=${#pos}
          if [[ $best_pos -eq -1 ]] || [[ $this_pos -lt $best_pos ]]; then
            best_pos=$this_pos
          fi
        fi
      done
      if [[ $best_pos -ge 0 ]]; then
        local sentence="${remaining:0:$((best_pos + 1))}"
        sentence=$(echo "$sentence" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [[ -n "$sentence" ]] && sentences+=("$sentence")
        remaining="${remaining:$((best_pos + 2))}"
      else
        remaining=$(echo "$remaining" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [[ -n "$remaining" ]] && sentences+=("$remaining")
        remaining=""
      fi
    done

    local batched=()
    local buffer=""
    for sentence in "${sentences[@]}"; do
      if [[ -n "$buffer" ]]; then
        buffer="$buffer $sentence"
        if [[ ${#buffer} -ge $min_chars ]]; then
          batched+=("$buffer")
          buffer=""
        fi
      elif [[ ${#sentence} -lt $min_chars ]]; then
        buffer="$sentence"
      else
        batched+=("$sentence")
      fi
    done
    if [[ -n "$buffer" ]]; then
      if [[ ${#batched[@]} -gt 0 ]]; then
        batched[-1]="${batched[-1]} $buffer"
      else
        batched+=("$buffer")
      fi
    fi

    for unit_text in "${batched[@]}"; do
      unit_num=$((unit_num + 1))
      printf -v padded "%03d" "$unit_num"
      echo "$unit_text" > "$output_dir/unit-$padded.txt"
      if [[ $is_first_in_para -eq 1 ]] && [[ -n "$voice" ]]; then
        echo "${unit_num}:${voice}" >> "$output_dir/voice-overrides.txt"
      fi
      if [[ $is_first_in_para -eq 1 ]] && [[ $para_num -gt 1 ]]; then
        paragraph_breaks="${paragraph_breaks}${unit_num}\n"
      fi
      is_first_in_para=0
    done
  done

  echo -e "$paragraph_breaks" | sed '/^$/d' > "$output_dir/paragraph-breaks.txt"
  echo "$unit_num"
}

# generate_audio <text> <output_wav> <label> [target_sec]
# Full pipeline: text → units → TTS → gap-adjusted concat → wav
# If target_sec is provided, adjusts silence gaps to approach target duration.
generate_audio() {
  local text="$1"
  local output_wav="$2"
  local label="${3:-section}"
  local target_sec="${4:-}"

  local work_dir=$(mktemp -d)
  local parts_dir=$(mktemp -d)

  # Split text into units
  local n_units
  n_units=$(split_into_units "$text" "$MIN_BATCH_CHARS" "$work_dir")
  echo -e "    ${label}: ${GREEN}${n_units}${NC} units"

  # Load voice overrides
  declare -A overrides=()
  if [[ -f "$work_dir/voice-overrides.txt" ]]; then
    while IFS=: read -r num settings; do
      [[ -n "$num" ]] && overrides[$num]="$settings"
    done < "$work_dir/voice-overrides.txt"
  fi

  local cur_temp="$VIXTTS_TEMPERATURE"
  local cur_rep="$VIXTTS_REPETITION_PENALTY"

  # Generate each unit
  for unit_file in "$work_dir"/unit-*.txt; do
    local uname=$(basename "$unit_file" .txt)
    local utext=$(cat "$unit_file")
    local uout="$parts_dir/$uname.wav"
    local uidx=$(echo "$uname" | sed 's/unit-0*//')

    # Apply voice override
    if [[ -n "${overrides[$uidx]:-}" ]]; then
      local ovr="${overrides[$uidx]}"
      if [[ "$ovr" == "reset" ]]; then
        cur_temp="$VIXTTS_TEMPERATURE"
        cur_rep="$VIXTTS_REPETITION_PENALTY"
      else
        while IFS=',' read -ra pairs; do
          for pair in "${pairs[@]}"; do
            local key=$(echo "${pair%%=*}" | xargs)
            local val=$(echo "${pair##*=}" | xargs)
            case "$key" in
              temp) cur_temp="$val" ;;
              rep) cur_rep="$val" ;;
            esac
          done
        done <<< "$ovr"
      fi
      apply_voice_settings "$cur_temp" "$cur_rep"
    fi

    # TTS call
    curl -s -X POST "$VIXTTS_API_URL/tts_to_audio/" \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg text "$utext" --arg speaker "$SPEAKER_NAME" \
        '{"text": $text, "speaker_wav": $speaker, "language": "vi"}')" \
      -o "$uout"

    if [[ ! -s "$uout" ]]; then
      echo -e "${RED}Error: TTS failed for $uname${NC}"
      rm -rf "$work_dir" "$parts_dir"
      return 1
    fi

    # Fade in/out
    local udur=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$uout")
    local fade_out=$(echo "$udur - $FADE_DURATION" | bc)
    ffmpeg -y -i "$uout" \
      -af "afade=t=in:d=$FADE_DURATION,afade=t=out:st=$fade_out:d=$FADE_DURATION" \
      "${uout%.wav}-f.wav" 2>/dev/null
    mv "${uout%.wav}-f.wav" "$uout"
  done

  # --- Measure unit durations + count gap slots ---
  local sample_rate=$(ffprobe -v quiet -show_entries stream=sample_rate -of csv=p=0 "$parts_dir/unit-001.wav")

  declare -A pbreaks=()
  if [[ -f "$work_dir/paragraph-breaks.txt" ]]; then
    while IFS= read -r num; do
      [[ -n "$num" ]] && pbreaks[$num]=1
    done < "$work_dir/paragraph-breaks.txt"
  fi

  local total_speech=0
  local n_sentence_gaps=0
  local n_paragraph_gaps=0
  local unit_count=0
  for part in "$parts_dir"/unit-*.wav; do
    unit_count=$((unit_count + 1))
    local dur=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$part")
    total_speech=$(echo "$total_speech + $dur" | bc)
    if [[ $unit_count -gt 1 ]]; then
      if [[ -n "${pbreaks[$unit_count]:-}" ]]; then
        n_paragraph_gaps=$((n_paragraph_gaps + 1))
      else
        n_sentence_gaps=$((n_sentence_gaps + 1))
      fi
    fi
  done

  # --- Calculate gap durations (budget-aware if target_sec provided) ---
  local gap_s="$SILENCE_SENTENCE"
  local gap_p="$SILENCE_PARAGRAPH"

  if [[ -n "$target_sec" ]] && [[ $((n_sentence_gaps + n_paragraph_gaps)) -gt 0 ]]; then
    read -r gap_s gap_p <<< "$(python3 -c "
total_speech = $total_speech
target = float('$target_sec')
n_s = $n_sentence_gaps
n_p = $n_paragraph_gaps
w_para = $GAP_WEIGHT_PARA

gap_budget = target - total_speech
weighted_slots = n_s * 1.0 + n_p * w_para

if gap_budget > 0 and weighted_slots > 0:
    unit = gap_budget / weighted_slots
    gs = unit * 1.0
    gp = unit * w_para
else:
    # Negative budget or no slots: use minimums
    gs = $GAP_SENTENCE_MIN
    gp = $GAP_PARAGRAPH_MIN

# Clamp
gs = max($GAP_SENTENCE_MIN, min($GAP_SENTENCE_MAX, gs))
gp = max($GAP_PARAGRAPH_MIN, min($GAP_PARAGRAPH_MAX, gp))
print(f'{gs:.3f} {gp:.3f}')
")"
  fi

  # --- Concat with calculated gaps ---
  local concat_list="$parts_dir/concat.txt"
  local sil_idx=0
  local idx=0
  for part in "$parts_dir"/unit-*.wav; do
    idx=$((idx + 1))
    if [[ $idx -gt 1 ]]; then
      local this_gap="$gap_s"
      if [[ -n "${pbreaks[$idx]:-}" ]]; then
        this_gap="$gap_p"
      fi
      sil_idx=$((sil_idx + 1))
      local sil_file="$parts_dir/sil-$sil_idx.wav"
      ffmpeg -y -f lavfi -i "anullsrc=r=$sample_rate:cl=mono" -t "$this_gap" -c:a pcm_s16le "$sil_file" 2>/dev/null
      echo "file '$sil_file'" >> "$concat_list"
    fi
    echo "file '$part'" >> "$concat_list"
  done

  ffmpeg -y -f concat -safe 0 -i "$concat_list" -c copy "$output_wav" 2>/dev/null

  # Report gap info
  local total_gaps=$(echo "$n_sentence_gaps * $gap_s + $n_paragraph_gaps * $gap_p" | bc)
  echo -e "      speech=${total_speech}s gaps=${total_gaps}s (sent=${gap_s}s×${n_sentence_gaps} para=${gap_p}s×${n_paragraph_gaps})"

  rm -rf "$work_dir" "$parts_dir"
}

# ============================================================
# VALIDATION
# ============================================================

if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <book-slug>${NC}"
  echo "Example: $0 atomic-habits"
  exit 1
fi

SLUG="$1"
SCRIPT_FILE="$PROJECT_DIR/books/$SLUG/script.md"
OUTPUT_DIR="$PROJECT_DIR/books/$SLUG/audio"
OUTPUT_FILE="$OUTPUT_DIR/voiceover.wav"

if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo -e "${RED}Error: Script file not found: $SCRIPT_FILE${NC}"
  exit 1
fi

# --- Check viXTTS server ---
echo -e "${YELLOW}Checking viXTTS server at $VIXTTS_API_URL...${NC}"
if ! curl -s --max-time 5 "$VIXTTS_API_URL/speakers" 2>/dev/null | grep -q "\["; then
  echo -e "${RED}Error: viXTTS server not reachable at $VIXTTS_API_URL${NC}"
  echo "  Start: ./scripts/vixtts-server.sh start"
  exit 1
fi
echo -e "${GREEN}Server connected${NC} (speaker: $SPEAKER_NAME)"
apply_voice_settings "$VIXTTS_TEMPERATURE" "$VIXTTS_REPETITION_PENALTY"
echo -e "  Settings: temp=${GREEN}$VIXTTS_TEMPERATURE${NC} rep=${GREEN}$VIXTTS_REPETITION_PENALTY${NC}"

mkdir -p "$OUTPUT_DIR"

# ============================================================
# Per-scene generation with gap adjustment
# ============================================================
TIMING_FILE="$PROJECT_DIR/books/$SLUG/output/section-timing.json"
if [[ ! -f "$TIMING_FILE" ]]; then
  echo -e "${RED}Error: section-timing.json not found${NC}"
  echo "  Run first: make subtitle BOOK=$SLUG"
  exit 1
fi

echo -e "${YELLOW}Generating voiceover (per-scene, gap-adjusted)...${NC}"

# Extract per-scene text using Python
SCENE_WORK=$(mktemp -d)
trap "rm -rf $SCENE_WORK" EXIT

python3 -c "
import re, sys, json, os

script_path = sys.argv[1]
timing_path = sys.argv[2]
out_dir = sys.argv[3]

with open(script_path, 'r', encoding='utf-8') as f:
    content = f.read()
with open(timing_path, 'r', encoding='utf-8') as f:
    timing = json.load(f)

# Build target durations map
targets = {t['scene']: t['durationSec'] for t in timing}

# Parse scene markers
scene_re = re.compile(r'<!-- scene: (scene-\d+), pace: (\w+) -->')
markers = list(scene_re.finditer(content))

for i, m in enumerate(markers):
    scene_id = m.group(1)
    start = m.end()
    if i + 1 < len(markers):
        end = markers[i + 1].start()
    else:
        notes = re.search(r'^## Notes', content[start:], re.MULTILINE)
        end = start + notes.start() if notes else len(content)

    raw = content[start:end]

    # Clean but KEEP voice markers for TTS pipeline
    lines = []
    in_code = False
    for line in raw.split('\n'):
        s = line.strip()
        if s.startswith('\`\`\`'):
            in_code = not in_code
            continue
        if in_code:
            continue
        # Keep voice markers
        if re.match(r'^<!-- voice:', s):
            lines.append(s)
            continue
        # Skip other markers/metadata
        if s.startswith('#') or s.startswith('>') or s == '---':
            continue
        if s.startswith('**Visual**') or re.match(r'^\*\*\[SHORT\]\*\*$', s):
            continue
        if re.match(r'^<!-- scene:', s):
            continue
        if re.match(r'^\*\*(Target|Tác|Thể|Ngày)', s):
            continue
        # Clean inline formatting
        s = s.replace('**', '').replace('*', '').replace('[SHORT]', '').strip()
        lines.append(s)

    text = '\n'.join(lines).strip()
    text = re.sub(r'\n{3,}', '\n\n', text)

    if not text:
        continue

    scene_dir = os.path.join(out_dir, scene_id)
    os.makedirs(scene_dir, exist_ok=True)
    with open(os.path.join(scene_dir, 'text.txt'), 'w') as f:
        f.write(text)
    with open(os.path.join(scene_dir, 'target_sec'), 'w') as f:
        f.write(str(targets.get(scene_id, 30)))

print(f'Extracted {len(markers)} scenes')
" "$SCRIPT_FILE" "$TIMING_FILE" "$SCENE_WORK"

# Process each scene
SCENE_FINALS=()
SCENE_ACTUALS=()
SAMPLE_RATE=""

for scene_dir in $(find "$SCENE_WORK" -mindepth 1 -maxdepth 1 -type d | sort); do
    scene_id=$(basename "$scene_dir")
    scene_text=$(cat "$scene_dir/text.txt")
    target_sec=$(cat "$scene_dir/target_sec")

    echo -e "  ${YELLOW}$scene_id${NC} (target: ${target_sec}s)"

    # Generate audio with gap adjustment (no stretch)
    FINAL_WAV="$scene_dir/final.wav"
    generate_audio "$scene_text" "$FINAL_WAV" "$scene_id" "$target_sec"

    # Measure actual duration
    ACTUAL_SEC=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$FINAL_WAV")

    # Get sample rate from first scene
    if [[ -z "$SAMPLE_RATE" ]]; then
      SAMPLE_RATE=$(ffprobe -v quiet -show_entries stream=sample_rate -of csv=p=0 "$FINAL_WAV")
    fi

    # Report delta
    DELTA=$(python3 -c "
a, t = float('$ACTUAL_SEC'), float('$target_sec')
d = a - t
pct = (d / t) * 100 if t > 0 else 0
print(f'{d:+.2f}s ({pct:+.1f}%)')
")
    SCENE_STATUS=$(python3 -c "
a, t = float('$ACTUAL_SEC'), float('$target_sec')
pct = abs(a - t) / t * 100 if t > 0 else 0
if pct <= 5: print('OK')
elif pct <= 15: print('acceptable')
else: print('NEEDS_SCRIPT_EDIT')
")
    if [[ "$SCENE_STATUS" == "NEEDS_SCRIPT_EDIT" ]]; then
      echo -e "      ${RED}${ACTUAL_SEC}s (delta: ${DELTA}) — script edit recommended${NC}"
    elif [[ "$SCENE_STATUS" == "acceptable" ]]; then
      echo -e "      ${YELLOW}${ACTUAL_SEC}s (delta: ${DELTA})${NC}"
    else
      echo -e "      ${GREEN}${ACTUAL_SEC}s (delta: ${DELTA})${NC}"
    fi

    # Track for voice-timing.json
    SCENE_ACTUALS+=("$scene_id:$ACTUAL_SEC:$target_sec:$SCENE_STATUS")
    SCENE_FINALS+=("$FINAL_WAV")
done

# Concat all scenes with scene-level silence (0.8s)
echo -e "${YELLOW}Concatenating ${#SCENE_FINALS[@]} scenes...${NC}"

CONCAT_DIR=$(mktemp -d)
SCENE_GAP=0.8
SIL_SCENE="$CONCAT_DIR/sil-scene.wav"
ffmpeg -y -f lavfi -i "anullsrc=r=$SAMPLE_RATE:cl=mono" -t "$SCENE_GAP" -c:a pcm_s16le "$SIL_SCENE" 2>/dev/null

CONCAT_LIST="$CONCAT_DIR/concat.txt"
for i in "${!SCENE_FINALS[@]}"; do
    if [[ $i -gt 0 ]]; then
      echo "file '$SIL_SCENE'" >> "$CONCAT_LIST"
    fi
    echo "file '${SCENE_FINALS[$i]}'" >> "$CONCAT_LIST"
done

ffmpeg -y -f concat -safe 0 -i "$CONCAT_LIST" -c copy "$OUTPUT_FILE" 2>/dev/null
rm -rf "$CONCAT_DIR"

# Write voice-timing.json
VOICE_TIMING="$PROJECT_DIR/books/$SLUG/output/voice-timing.json"
python3 -c "
import json, sys
entries = []
for item in sys.argv[1:]:
    parts = item.split(':')
    scene, actual, target, status = parts[0], float(parts[1]), float(parts[2]), parts[3]
    entries.append({
        'scene': scene,
        'targetSec': round(target, 2),
        'actualSec': round(actual, 2),
        'deltaSec': round(actual - target, 2),
        'status': status
    })
with open('$VOICE_TIMING', 'w') as f:
    json.dump(entries, f, indent=2)
print(f'  Written: $VOICE_TIMING ({len(entries)} scenes)')
" "${SCENE_ACTUALS[@]}"

# Summary
if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo -e "${RED}Failed to generate voiceover${NC}"
    exit 1
fi

DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT_FILE" 2>/dev/null)
DUR_INT=${DURATION%.*}
MINUTES=$((DUR_INT / 60))
SECONDS=$((DUR_INT % 60))
FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

# Count scenes needing script edit
NEEDS_EDIT=0
for entry in "${SCENE_ACTUALS[@]}"; do
  [[ "$entry" == *:NEEDS_SCRIPT_EDIT ]] && NEEDS_EDIT=$((NEEDS_EDIT + 1))
done

echo ""
echo -e "${GREEN}Voiceover generated (gap-adjusted, natural voice)!${NC}"
echo -e "  Output: $OUTPUT_FILE"
echo -e "  Duration: ${MINUTES}m ${SECONDS}s | Size: $FILE_SIZE"
if [[ $NEEDS_EDIT -gt 0 ]]; then
  echo -e "  ${RED}$NEEDS_EDIT scene(s) >15% off target — consider editing script${NC}"
fi

# Auto-sync SRT to match actual audio duration
SRT_FILE="$PROJECT_DIR/books/$SLUG/output/subtitles.srt"
if [[ -f "$SRT_FILE" ]]; then
  echo ""
  echo -e "${YELLOW}Auto-syncing SRT to actual audio...${NC}"
  "$SCRIPT_DIR/generate-subtitle.sh" "$SLUG" --sync
fi

echo ""
echo -e "Next steps:"
echo -e "  1. Sync assets: make sync BOOK=$SLUG"
echo -e "  2. Preview:     make studio"
