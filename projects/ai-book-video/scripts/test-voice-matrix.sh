#!/usr/bin/env bash
# test-voice-matrix.sh — Test matrix: speakers × emotional tones × temperature
#
# Generate 30 WAV files to compare voice quality across combinations.
# Output: assets/test-sach/voice-matrix/{speaker}/{tone}-t{temp}.wav + matrix.md
#
# Usage: ./scripts/test-voice-matrix.sh
# Prerequisites: viXTTS server running (./scripts/vixtts-server.sh start)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/assets/test-sach/voice-matrix"

# --- Configuration ---
VIXTTS_API_URL="${VIXTTS_API_URL:-http://127.0.0.1:8020}"

SPEAKERS=("bookie-hai" "fonos")
TEMPERATURES=("0.3" "0.65" "0.85")
TEMP_LABELS=("t03" "t065" "t085")
TONES=("calm" "excited" "reflective" "heavy" "motivational")

# Speed and repetition penalty stay constant across all tests
SPEED=1.0
REPETITION_PENALTY=2.0

# --- Text samples ---
declare -A TEXTS
TEXTS[calm]="Có những cuốn sách thay đổi cách bạn nhìn thế giới, không phải bằng lý thuyết cao siêu, mà bằng những câu chuyện rất đời thường. Hôm nay mình muốn kể cho bạn nghe về một cuốn sách như vậy."
TEXTS[excited]="Và đây chính là điều khiến mình phải dừng lại đọc đi đọc lại đoạn này ba lần! Bạn có tưởng tượng được không, chỉ một thay đổi nhỏ trong thói quen buổi sáng đã tạo ra kết quả hoàn toàn khác biệt!"
TEXTS[reflective]="Đôi khi mình tự hỏi, liệu những gì mình đang theo đuổi có thực sự quan trọng không. Hay mình chỉ đang chạy theo kỳ vọng của người khác mà quên mất điều mình thật sự cần."
TEXTS[heavy]="Tác giả đã mất tất cả. Công việc, gia đình, và cả niềm tin vào bản thân. Có những giai đoạn trong đời mà bạn không cần lời khuyên, bạn chỉ cần ai đó hiểu rằng mọi thứ đang rất nặng nề."
TEXTS[motivational]="Bạn không cần phải hoàn hảo để bắt đầu. Nhưng bạn cần bắt đầu để trở nên tốt hơn. Mỗi trang sách bạn đọc, mỗi bước nhỏ bạn đi, đều đang đưa bạn đến gần hơn phiên bản tốt nhất của chính mình."

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# --- Tone descriptions (for matrix.md) ---
declare -A TONE_DESC
TONE_DESC[calm]="Binh tinh, ke chuyen — Narration nhe nhang kieu intro video"
TONE_DESC[excited]="Hao hung, nang luong — Moment aha hoac highlight sach"
TONE_DESC[reflective]="Suy tu, tram lang — Doan chiem nghiem, triet ly"
TONE_DESC[heavy]="Nang ne, nghiem tuc — Doan noi ve kho khan, that bai"
TONE_DESC[motivational]="Truyen cam hung — Closing/CTA, keu goi hanh dong"

# --- Check viXTTS server ---
echo -e "${YELLOW}Checking viXTTS server at $VIXTTS_API_URL...${NC}"
if ! curl -s --max-time 5 "$VIXTTS_API_URL/speakers" 2>/dev/null | grep -q "\["; then
  echo -e "${RED}Error: viXTTS server not reachable at $VIXTTS_API_URL${NC}"
  echo "Start the server: ./scripts/vixtts-server.sh start"
  exit 1
fi

# Verify speakers exist
AVAILABLE_SPEAKERS=$(curl -s "$VIXTTS_API_URL/speakers" 2>/dev/null)
for speaker in "${SPEAKERS[@]}"; do
  if ! echo "$AVAILABLE_SPEAKERS" | grep -q "\"$speaker\""; then
    echo -e "${RED}Error: Speaker '$speaker' not found on server${NC}"
    echo "Available: $AVAILABLE_SPEAKERS"
    echo "Add speaker: ./scripts/vixtts-server.sh add-speaker $speaker <audio-source>"
    exit 1
  fi
done
echo -e "${GREEN}Server connected. Speakers: ${SPEAKERS[*]}${NC}"

# --- Setup output directories ---
mkdir -p "$OUTPUT_DIR"
for speaker in "${SPEAKERS[@]}"; do
  mkdir -p "$OUTPUT_DIR/$speaker"
done

# --- Get base TTS settings ---
BASE_SETTINGS=$(curl -s "$VIXTTS_API_URL/get_tts_settings" | \
  jq --argjson speed "$SPEED" \
     --argjson rep "$REPETITION_PENALTY" \
     '.speed = $speed | .repetition_penalty = $rep | .enable_text_splitting = false')

# --- Generate matrix ---
TOTAL=$((${#SPEAKERS[@]} * ${#TONES[@]} * ${#TEMPERATURES[@]}))
COUNT=0
FAILED=0
START_TIME=$(date +%s)

echo ""
echo -e "${BOLD}Generating $TOTAL voice samples...${NC}"
echo -e "  Speakers:     ${SPEAKERS[*]}"
echo -e "  Tones:        ${TONES[*]}"
echo -e "  Temperatures: ${TEMPERATURES[*]}"
echo ""

for speaker in "${SPEAKERS[@]}"; do
  for tone in "${TONES[@]}"; do
    for i in "${!TEMPERATURES[@]}"; do
      temp="${TEMPERATURES[$i]}"
      label="${TEMP_LABELS[$i]}"
      text="${TEXTS[$tone]}"
      outfile="$OUTPUT_DIR/$speaker/${tone}-${label}.wav"

      COUNT=$((COUNT + 1))
      echo -ne "  [${COUNT}/${TOTAL}] ${speaker}/${tone}-${label} ... "

      # Update temperature
      SETTINGS=$(echo "$BASE_SETTINGS" | jq --argjson temp "$temp" '.temperature = $temp')
      curl -s -X POST "$VIXTTS_API_URL/set_tts_settings" \
        -H "Content-Type: application/json" \
        -d "$SETTINGS" > /dev/null

      # Generate audio
      HTTP_CODE=$(curl -s -o "$outfile" -w "%{http_code}" \
        -X POST "$VIXTTS_API_URL/tts_to_audio/" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
          --arg text "$text" \
          --arg speaker "$speaker" \
          '{
            "text": $text,
            "speaker_wav": $speaker,
            "language": "vi"
          }')")

      if [[ "$HTTP_CODE" != "200" ]] || [[ ! -s "$outfile" ]]; then
        echo -e "${RED}FAILED (HTTP $HTTP_CODE)${NC}"
        FAILED=$((FAILED + 1))
        rm -f "$outfile"
      else
        SIZE=$(du -h "$outfile" | cut -f1)
        DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$outfile" 2>/dev/null | cut -d. -f1)
        echo -e "${GREEN}OK${NC} (${SIZE}, ${DURATION}s)"
      fi
    done
  done
done

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
ELAPSED_MIN=$((ELAPSED / 60))
ELAPSED_SEC=$((ELAPSED % 60))

# --- Generate matrix.md ---
MATRIX_FILE="$OUTPUT_DIR/matrix.md"
cat > "$MATRIX_FILE" << 'HEADER'
# Voice Matrix — Test Results

> Generated by `scripts/test-voice-matrix.sh`

## Settings
- **Speed**: 1.0
- **Repetition penalty**: 2.0
- **Text splitting**: disabled

## Speakers
| Speaker | Description |
|---------|-------------|
| `bookie-hai` | Voice reference cua Hai |
| `fonos` | Fonos audiobook narrator |

## Temperature Levels
| Label | Value | Character |
|-------|-------|-----------|
| `t03` | 0.3 | Monotone, stable pitch |
| `t065` | 0.65 | Balanced, natural variation |
| `t085` | 0.85 | Expressive, wide pitch range |

## Text Samples
HEADER

for tone in "${TONES[@]}"; do
  echo "" >> "$MATRIX_FILE"
  echo "### \`$tone\` — ${TONE_DESC[$tone]}" >> "$MATRIX_FILE"
  echo '```' >> "$MATRIX_FILE"
  echo "${TEXTS[$tone]}" >> "$MATRIX_FILE"
  echo '```' >> "$MATRIX_FILE"
done

cat >> "$MATRIX_FILE" << 'TABLE_HEADER'

## File Matrix

| Speaker | Tone | Temp | File | Duration |
|---------|------|------|------|----------|
TABLE_HEADER

for speaker in "${SPEAKERS[@]}"; do
  for tone in "${TONES[@]}"; do
    for i in "${!TEMPERATURES[@]}"; do
      temp="${TEMPERATURES[$i]}"
      label="${TEMP_LABELS[$i]}"
      filename="${tone}-${label}.wav"
      filepath="$OUTPUT_DIR/$speaker/$filename"

      if [[ -f "$filepath" ]]; then
        dur=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$filepath" 2>/dev/null)
        dur_display=$(LC_NUMERIC=C printf "%.1fs" "$dur")
      else
        dur_display="FAILED"
      fi

      echo "| \`$speaker\` | \`$tone\` | $temp | \`$speaker/$filename\` | $dur_display |" >> "$MATRIX_FILE"
    done
  done
done

cat >> "$MATRIX_FILE" << FOOTER

## Evaluation Notes

> Fill in after listening:

### Best combinations
- **Narration (calm/reflective)**: speaker=?, temp=?
- **Energy (excited/motivational)**: speaker=?, temp=?
- **Emotional weight (heavy)**: speaker=?, temp=?

### Overall pick
- **Speaker**: ?
- **Default temperature**: ?
- **Notes**: ?
FOOTER

# --- Summary ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
GENERATED=$((COUNT - FAILED))
echo -e "${GREEN}Done!${NC} ${GENERATED}/${TOTAL} files generated (${ELAPSED_MIN}m ${ELAPSED_SEC}s)"

if [[ $FAILED -gt 0 ]]; then
  echo -e "${RED}$FAILED files failed${NC}"
fi

echo ""
echo -e "  Output:  ${BOLD}$OUTPUT_DIR/${NC}"
echo -e "  Summary: ${BOLD}$MATRIX_FILE${NC}"
echo ""
echo -e "Next: listen and fill in evaluation notes in matrix.md"
