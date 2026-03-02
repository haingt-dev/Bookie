#!/usr/bin/env bash
# generate-voice.sh — Generate voiceover từ script text bằng viXTTS (self-hosted)
# Usage: ./scripts/generate-voice.sh <book-slug>
# Prerequisites: viXTTS server running (./scripts/vixtts-server.sh start)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
VIXTTS_API_URL="${VIXTTS_API_URL:-http://127.0.0.1:8020}"
SPEAKER_NAME="${VIXTTS_SPEAKER:-bookie-hai}"
SILENCE_SENTENCE=0.15     # 150ms between sentences (same paragraph)
SILENCE_PARAGRAPH=0.4     # 400ms between paragraphs/sections
FADE_DURATION=0.02        # minimal fade to prevent clicks
MIN_BATCH_CHARS=100       # batch sentences shorter than this with neighbor
VIXTTS_TEMPERATURE="${VIXTTS_TEMPERATURE:-0.85}"             # XTTS default — pitch/intonation variation
VIXTTS_REPETITION_PENALTY="${VIXTTS_REPETITION_PENALTY:-2.0}" # XTTS default — natural prosody patterns

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Validate input ---
if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <book-slug>${NC}"
  echo "Example: $0 atomic-habits"
  exit 1
fi

SLUG="$1"
SCRIPT_FILE="$PROJECT_DIR/scripts/$SLUG/script.md"
OUTPUT_DIR="$PROJECT_DIR/assets/$SLUG/audio"
OUTPUT_FILE="$OUTPUT_DIR/voiceover.wav"

if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo -e "${RED}Error: Script file not found: $SCRIPT_FILE${NC}"
  echo "Đã chạy init-video.sh chưa? Đã viết script chưa?"
  exit 1
fi

# --- Check viXTTS server ---
echo -e "${YELLOW}Checking viXTTS server at $VIXTTS_API_URL...${NC}"
if ! curl -s --max-time 5 "$VIXTTS_API_URL/speakers" 2>/dev/null | grep -q "\["; then
  echo -e "${RED}Error: viXTTS server not reachable at $VIXTTS_API_URL${NC}"
  echo ""
  echo "Start the server:"
  echo "  ./scripts/vixtts-server.sh start"
  exit 1
fi
echo -e "${GREEN}Server connected${NC}"
echo -e "  Speaker: ${GREEN}$SPEAKER_NAME${NC}"

# Tune viXTTS settings: disable internal splitting + expressiveness params
TTS_SETTINGS=$(curl -s "$VIXTTS_API_URL/get_tts_settings" | \
  jq --argjson temp "$VIXTTS_TEMPERATURE" \
     --argjson rep "$VIXTTS_REPETITION_PENALTY" \
     '.enable_text_splitting = false | .temperature = $temp | .repetition_penalty = $rep')
curl -s -X POST "$VIXTTS_API_URL/set_tts_settings" \
  -H "Content-Type: application/json" \
  -d "$TTS_SETTINGS" > /dev/null
echo -e "  Text splitting: ${GREEN}disabled${NC} (handled by script)"
echo -e "  Temperature: ${GREEN}$VIXTTS_TEMPERATURE${NC} | Repetition penalty: ${GREEN}$VIXTTS_REPETITION_PENALTY${NC}"

# --- Extract plain text from script.md ---
echo -e "${YELLOW}📝 Extracting script text...${NC}"

extract_script_text() {
  local file="$1"
  
  # Remove markdown formatting, keep blank lines as paragraph markers
  sed \
    -e '/^## Notes/,$d' \
    -e '/^#/d' \
    -e '/^>/d' \
    -e '/^\*\*Visual\*\*/d' \
    -e '/^---$/d' \
    -e '/^\*\*\[SHORT\]\*\*/d' \
    -e '/^```/,/^```/d' \
    -e '/^\*\*Target length\*\*/d' \
    -e '/^\*\*Tác giả\*\*/d' \
    -e '/^\*\*Thể loại\*\*/d' \
    -e '/^\*\*Ngày tạo\*\*/d' \
    -e 's/\*\*//g' \
    -e 's/\*//g' \
    -e 's/\[SHORT\]//g' \
    "$file" | cat -s | sed -e '1{/^$/d}' -e '${/^$/d}'
}

PLAIN_TEXT=$(extract_script_text "$SCRIPT_FILE")

if [[ -z "$PLAIN_TEXT" ]]; then
  echo -e "${RED}Error: No text extracted from script. Is the script empty?${NC}"
  exit 1
fi

WORD_COUNT=$(echo "$PLAIN_TEXT" | wc -w)
echo -e "  Extracted ${GREEN}$WORD_COUNT${NC} words"

if [[ $WORD_COUNT -lt 50 ]]; then
  echo -e "${YELLOW}⚠️  Warning: Very short script ($WORD_COUNT words). Expected 900-1050.${NC}"
fi

# --- Split into units (per-sentence with batching) ---
echo -e "${YELLOW}✂️  Splitting into units...${NC}"

UNITS_DIR=$(mktemp -d)
trap "rm -rf $UNITS_DIR" EXIT

split_into_units() {
  local text="$1"
  local min_chars="$2"
  local output_dir="$3"
  local unit_num=0
  local paragraph_breaks=""

  # Split text into paragraphs by blank lines
  local para=""
  local para_num=0
  local paragraphs=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      # Blank line = paragraph boundary
      if [[ -n "$para" ]]; then
        paragraphs+=("$para")
        para=""
      fi
    else
      [[ -n "$para" ]] && para="$para "
      para="${para}${line}"
    fi
  done <<< "$text"
  # Flush last paragraph
  [[ -n "$para" ]] && paragraphs+=("$para")

  for para in "${paragraphs[@]}"; do
    para_num=$((para_num + 1))
    local is_first_in_para=1

    # Split paragraph into sentences (. ! ? followed by space or end)
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

    # Batch short sentences with their neighbor
    local batched=()
    local buffer=""
    for sentence in "${sentences[@]}"; do
      if [[ -n "$buffer" ]]; then
        buffer="$buffer $sentence"
        # If buffer is now long enough, flush it
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
    # Flush remaining buffer
    if [[ -n "$buffer" ]]; then
      if [[ ${#batched[@]} -gt 0 ]]; then
        # Append to last batch
        batched[-1]="${batched[-1]} $buffer"
      else
        batched+=("$buffer")
      fi
    fi

    # Write each batched sentence as a unit
    for unit_text in "${batched[@]}"; do
      unit_num=$((unit_num + 1))
      printf -v padded "%03d" "$unit_num"
      echo "$unit_text" > "$output_dir/unit-$padded.txt"

      # Track paragraph breaks (first unit of each paragraph after the first)
      if [[ $is_first_in_para -eq 1 ]] && [[ $para_num -gt 1 ]]; then
        paragraph_breaks="${paragraph_breaks}${unit_num}\n"
      fi
      is_first_in_para=0
    done
  done

  # Write paragraph breaks file
  echo -e "$paragraph_breaks" | sed '/^$/d' > "$output_dir/paragraph-breaks.txt"

  echo "$unit_num"
}

TOTAL_UNITS=$(split_into_units "$PLAIN_TEXT" "$MIN_BATCH_CHARS" "$UNITS_DIR")
echo -e "  Split into ${GREEN}$TOTAL_UNITS${NC} units"

# --- Generate audio for each unit ---
echo -e "${YELLOW}🎤 Generating voiceover ($TOTAL_UNITS units)...${NC}"

mkdir -p "$OUTPUT_DIR"
AUDIO_PARTS_DIR=$(mktemp -d)
trap "rm -rf $UNITS_DIR $AUDIO_PARTS_DIR" EXIT

for unit_file in "$UNITS_DIR"/unit-*.txt; do
  unit_name=$(basename "$unit_file" .txt)
  unit_text=$(cat "$unit_file")
  output_part="$AUDIO_PARTS_DIR/$unit_name.wav"

  echo -e "  Processing $unit_name..."

  # Call viXTTS API
  curl -s -X POST "$VIXTTS_API_URL/tts_to_audio/" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg text "$unit_text" \
      --arg speaker "$SPEAKER_NAME" \
      '{
        "text": $text,
        "speaker_wav": $speaker,
        "language": "vi"
      }')" \
    -o "$output_part"

  if [[ ! -s "$output_part" ]]; then
    echo -e "${RED}Error: Failed to generate audio for $unit_name${NC}"
    exit 1
  fi

  # Apply fade-in/fade-out to smooth edges
  unit_duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$output_part")
  fade_out_start=$(echo "$unit_duration - $FADE_DURATION" | bc)
  ffmpeg -y -i "$output_part" \
    -af "afade=t=in:d=$FADE_DURATION,afade=t=out:st=$fade_out_start:d=$FADE_DURATION" \
    "${output_part%.wav}-faded.wav" 2>/dev/null
  mv "${output_part%.wav}-faded.wav" "$output_part"
done

# --- Concatenate units with variable silence ---
echo -e "${YELLOW}🔗 Concatenating audio units...${NC}"

if command -v ffmpeg &> /dev/null; then
  # Get sample rate from first unit
  FIRST_UNIT="$AUDIO_PARTS_DIR/unit-001.wav"
  SAMPLE_RATE=$(ffprobe -v quiet -show_entries stream=sample_rate -of csv=p=0 "$FIRST_UNIT")

  # Generate two silence files: sentence-level and paragraph-level
  SILENCE_SENT_FILE="$AUDIO_PARTS_DIR/silence-sentence.wav"
  SILENCE_PARA_FILE="$AUDIO_PARTS_DIR/silence-paragraph.wav"
  ffmpeg -y -f lavfi -i "anullsrc=r=$SAMPLE_RATE:cl=mono" \
    -t "$SILENCE_SENTENCE" -c:a pcm_s16le "$SILENCE_SENT_FILE" 2>/dev/null
  ffmpeg -y -f lavfi -i "anullsrc=r=$SAMPLE_RATE:cl=mono" \
    -t "$SILENCE_PARAGRAPH" -c:a pcm_s16le "$SILENCE_PARA_FILE" 2>/dev/null

  # Load paragraph break unit numbers into an associative array
  declare -A PARA_BREAKS
  if [[ -f "$UNITS_DIR/paragraph-breaks.txt" ]]; then
    while IFS= read -r num; do
      [[ -n "$num" ]] && PARA_BREAKS[$num]=1
    done < "$UNITS_DIR/paragraph-breaks.txt"
  fi

  # Build concat list with appropriate silence between units
  CONCAT_LIST="$AUDIO_PARTS_DIR/concat.txt"
  unit_idx=0
  for part in "$AUDIO_PARTS_DIR"/unit-*.wav; do
    unit_idx=$((unit_idx + 1))
    if [[ $unit_idx -gt 1 ]]; then
      # Check if this unit starts a new paragraph
      if [[ -n "${PARA_BREAKS[$unit_idx]:-}" ]]; then
        echo "file '$SILENCE_PARA_FILE'" >> "$CONCAT_LIST"
      else
        echo "file '$SILENCE_SENT_FILE'" >> "$CONCAT_LIST"
      fi
    fi
    echo "file '$part'" >> "$CONCAT_LIST"
  done

  ffmpeg -y -f concat -safe 0 -i "$CONCAT_LIST" -c copy "$OUTPUT_FILE" 2>/dev/null
else
  # Fallback: use sox if available (no variable silence)
  if command -v sox &> /dev/null; then
    sox "$AUDIO_PARTS_DIR"/unit-*.wav "$OUTPUT_FILE"
  else
    echo -e "${RED}Error: ffmpeg or sox required to concatenate audio${NC}"
    echo "Install: sudo apt install ffmpeg"
    exit 1
  fi
fi

# --- Summary ---
if [[ -f "$OUTPUT_FILE" ]]; then
  DURATION=""
  if command -v ffprobe &> /dev/null; then
    DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT_FILE" 2>/dev/null | cut -d. -f1)
    if [[ -n "$DURATION" ]]; then
      MINUTES=$((DURATION / 60))
      SECONDS=$((DURATION % 60))
      DURATION=" (${MINUTES}m ${SECONDS}s)"
    fi
  fi
  
  FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
  
  echo ""
  echo -e "${GREEN}✅ Voiceover generated successfully!${NC}"
  echo -e "  📁 Output: $OUTPUT_FILE"
  echo -e "  📊 Size: $FILE_SIZE$DURATION"
  echo ""
  echo -e "🚀 Next steps:"
  echo -e "  1. Review voiceover: play $OUTPUT_FILE"
  echo -e "  2. Generate subtitles: ./scripts/generate-subtitle.sh $SLUG"
else
  echo -e "${RED}❌ Failed to generate voiceover${NC}"
  exit 1
fi
