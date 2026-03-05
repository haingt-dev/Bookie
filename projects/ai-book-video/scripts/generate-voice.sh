#!/usr/bin/env bash
# generate-voice.sh — Generate voiceover from script text via viXTTS (self-hosted)
# Usage: ./scripts/generate-voice.sh <book-slug>
# Voice-first pipeline: generates natural speech with pace-aware gaps.
# Outputs authoritative section-timing.json from actual measured durations.
# Prerequisites: viXTTS server running (./scripts/vixtts-server.sh start)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
VIXTTS_API_URL="${VIXTTS_API_URL:-http://127.0.0.1:8020}"
SPEAKER_NAME="${VIXTTS_SPEAKER:-fonos}"
FADE_DURATION=0.02        # minimal fade to prevent clicks
MIN_BATCH_CHARS=100       # batch sentences shorter than this with neighbor
SCENE_GAP=0.8             # silence between scenes (seconds)

# Pace-aware gap config (seconds of silence)
# slow = dramatic pauses, fast = tight delivery
GAP_SLOW_SENTENCE=0.40
GAP_SLOW_PARAGRAPH=0.80
GAP_NORMAL_SENTENCE=0.15
GAP_NORMAL_PARAGRAPH=0.40
GAP_FAST_SENTENCE=0.08
GAP_FAST_PARAGRAPH=0.20

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

# generate_audio <text> <output_wav> <label> <pace>
# Full pipeline: text -> units -> TTS -> pace-aware gap concat -> wav
generate_audio() {
  local text="$1"
  local output_wav="$2"
  local label="${3:-section}"
  local pace="${4:-normal}"

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

  # --- Pace-aware fixed gaps (no budget calculation) ---
  local gap_s gap_p
  case "$pace" in
    slow)   gap_s="$GAP_SLOW_SENTENCE";   gap_p="$GAP_SLOW_PARAGRAPH" ;;
    fast)   gap_s="$GAP_FAST_SENTENCE";   gap_p="$GAP_FAST_PARAGRAPH" ;;
    *)      gap_s="$GAP_NORMAL_SENTENCE"; gap_p="$GAP_NORMAL_PARAGRAPH" ;;
  esac

  # --- Concat with pace-aware gaps ---
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
mkdir -p "$PROJECT_DIR/books/$SLUG/output"

# ============================================================
# Per-scene generation (voice-first: no target timing)
# ============================================================

echo -e "${YELLOW}Generating voiceover (voice-first, pace-aware gaps)...${NC}"

# Extract per-scene text + pace using Python
SCENE_WORK=$(mktemp -d)
trap "rm -rf $SCENE_WORK" EXIT

python3 -c "
import re, sys, os

script_path = sys.argv[1]
out_dir = sys.argv[2]

with open(script_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Parse scene markers
scene_re = re.compile(r'<!-- scene: (scene-\d+), pace: (\w+) -->')
markers = list(scene_re.finditer(content))

for i, m in enumerate(markers):
    scene_id = m.group(1)
    pace = m.group(2)
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
    with open(os.path.join(scene_dir, 'pace'), 'w') as f:
        f.write(pace)

print(f'Extracted {len(markers)} scenes')
" "$SCRIPT_FILE" "$SCENE_WORK"

# Process each scene
SCENE_FINALS=()
SCENE_ACTUALS=()
SAMPLE_RATE=""

for scene_dir in $(find "$SCENE_WORK" -mindepth 1 -maxdepth 1 -type d | sort); do
    scene_id=$(basename "$scene_dir")
    scene_text=$(cat "$scene_dir/text.txt")
    pace=$(cat "$scene_dir/pace")

    echo -e "  ${YELLOW}$scene_id${NC} (pace: $pace)"

    # Generate audio with pace-aware gaps (no target)
    FINAL_WAV="$scene_dir/final.wav"
    generate_audio "$scene_text" "$FINAL_WAV" "$scene_id" "$pace"

    # Measure actual duration
    ACTUAL_SEC=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$FINAL_WAV")

    # Get sample rate from first scene
    if [[ -z "$SAMPLE_RATE" ]]; then
      SAMPLE_RATE=$(ffprobe -v quiet -show_entries stream=sample_rate -of csv=p=0 "$FINAL_WAV")
    fi

    echo -e "      ${GREEN}${ACTUAL_SEC}s${NC}"

    # Track for timing output
    SCENE_ACTUALS+=("$scene_id:$ACTUAL_SEC:$pace")
    SCENE_FINALS+=("$FINAL_WAV")
done

# Concat all scenes with scene-level silence
echo -e "${YELLOW}Concatenating ${#SCENE_FINALS[@]} scenes...${NC}"

CONCAT_DIR=$(mktemp -d)
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

# Write authoritative section-timing.json (ACTUAL measured durations)
TIMING_FILE="$PROJECT_DIR/books/$SLUG/output/section-timing.json"
python3 -c "
import json, sys

scene_gap = float(sys.argv[1])
entries = []
current_ms = 0

for item in sys.argv[2:]:
    parts = item.split(':')
    scene_id, actual_sec, pace = parts[0], float(parts[1]), parts[2]

    start_ms = current_ms
    end_ms = start_ms + round(actual_sec * 1000)
    entries.append({
        'scene': scene_id,
        'pace': pace,
        'startMs': start_ms,
        'endMs': end_ms,
        'durationSec': round(actual_sec, 2),
    })
    current_ms = end_ms + round(scene_gap * 1000)

with open('$TIMING_FILE', 'w') as f:
    json.dump(entries, f, indent=2, ensure_ascii=False)
print(f'  Timing: $TIMING_FILE ({len(entries)} scenes, actual)')
" "$SCENE_GAP" "${SCENE_ACTUALS[@]}"

# Write voice-timing.json (diagnostics)
VOICE_TIMING="$PROJECT_DIR/books/$SLUG/output/voice-timing.json"
python3 -c "
import json, sys
entries = []
for item in sys.argv[1:]:
    parts = item.split(':')
    scene, actual, pace = parts[0], float(parts[1]), parts[2]
    entries.append({
        'scene': scene,
        'pace': pace,
        'actualSec': round(actual, 2),
    })
with open('$VOICE_TIMING', 'w') as f:
    json.dump(entries, f, indent=2)
print(f'  Diagnostics: $VOICE_TIMING ({len(entries)} scenes)')
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

echo ""
echo -e "${GREEN}Voiceover generated (voice-first, natural pace)!${NC}"
echo -e "  Output: $OUTPUT_FILE"
echo -e "  Duration: ${MINUTES}m ${SECONDS}s | Size: $FILE_SIZE"

echo ""
echo -e "Next steps:"
echo -e "  1. Review voice — tweak script + re-run if needed"
echo -e "  2. Generate subtitles: make subtitle BOOK=$SLUG"
echo -e "  3. Sync assets:        make sync BOOK=$SLUG"
echo -e "  4. Preview:             make studio"
