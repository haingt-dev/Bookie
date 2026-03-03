#!/usr/bin/env bash
# generate-subtitle.sh — Generate SRT subtitles from script markdown
# Pipeline: Script (markdown) → SRT (perfect text + estimated timing)
#           Then optionally sync timestamps with actual audio duration
#
# Usage:
#   ./scripts/generate-subtitle.sh <book-slug>           # Script → SRT draft
#   ./scripts/generate-subtitle.sh <book-slug> --sync     # Sync SRT with audio

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
MAX_CHARS=55                  # Max chars per subtitle line before splitting
CHARS_PER_SEC=15              # Vietnamese reading speed estimate
GAP_SENTENCE=0.1              # 100ms gap between sentences
GAP_PARAGRAPH=0.3             # 300ms gap between paragraphs

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Validate input ---
if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <book-slug> [--sync]${NC}"
  echo "Example: $0 atomic-habits          # Script → SRT draft"
  echo "         $0 atomic-habits --sync    # Sync SRT with audio"
  echo ""
  echo "Input:  scripts/<slug>/script.md"
  echo "Output: output/<slug>/subtitles.srt"
  exit 1
fi

SLUG="$1"
MODE="draft"
if [[ "${2:-}" == "--sync" ]]; then
  MODE="sync"
fi

SCRIPT_FILE="$PROJECT_DIR/scripts/$SLUG/script.md"
OUTPUT_DIR="$PROJECT_DIR/output/$SLUG"
OUTPUT_SRT="$OUTPUT_DIR/subtitles.srt"
INPUT_WAV="$PROJECT_DIR/assets/$SLUG/audio/voiceover.wav"

# --- Extract plain text from script.md (reused from generate-voice.sh) ---
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
    -e '/^<!-- voice:.*-->$/d' \
    "$file" | cat -s | sed -e '1{/^$/d}' -e '${/^$/d}'
}

# ============================================================
# MODE: --sync — Scale SRT timestamps to match audio duration
# ============================================================
if [[ "$MODE" == "sync" ]]; then
  if [[ ! -f "$OUTPUT_SRT" ]]; then
    echo -e "${RED}Error: SRT file not found: $OUTPUT_SRT${NC}"
    echo "Chạy generate-subtitle.sh $SLUG trước (không có --sync) để tạo SRT draft."
    exit 1
  fi

  if [[ ! -f "$INPUT_WAV" ]]; then
    echo -e "${RED}Error: Audio file not found: $INPUT_WAV${NC}"
    echo "Chạy generate-voice.sh $SLUG trước."
    exit 1
  fi

  if ! command -v ffprobe &> /dev/null; then
    echo -e "${RED}Error: ffprobe not found. Install ffmpeg.${NC}"
    exit 1
  fi

  echo -e "${YELLOW}Syncing SRT timestamps with audio...${NC}"

  # Get actual audio duration
  AUDIO_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$INPUT_WAV" 2>/dev/null)
  if [[ -z "$AUDIO_DURATION" ]]; then
    echo -e "${RED}Error: Could not read audio duration${NC}"
    exit 1
  fi

  echo -e "  Audio: $INPUT_WAV (${GREEN}${AUDIO_DURATION}s${NC})"

  # Get last timestamp from SRT to determine SRT total duration
  SRT_DURATION=$(grep -oP '\d+:\d+:\d+,\d+' "$OUTPUT_SRT" | tail -1 | \
    awk -F'[,:]+' '{print ($1 * 3600) + ($2 * 60) + $3 + ($4 / 1000)}')

  if [[ -z "$SRT_DURATION" ]] || (( $(echo "$SRT_DURATION == 0" | bc -l) )); then
    echo -e "${RED}Error: Could not determine SRT duration${NC}"
    exit 1
  fi

  echo -e "  SRT estimated duration: ${YELLOW}${SRT_DURATION}s${NC}"
  SCALE=$(echo "scale=6; $AUDIO_DURATION / $SRT_DURATION" | bc -l)
  echo -e "  Scale factor: ${GREEN}${SCALE}x${NC}"

  # Scale all timestamps in the SRT file
  python3 -c "
import re, sys

scale = float(sys.argv[1])
srt_path = sys.argv[2]

def parse_ts(ts_str):
    h, m, rest = ts_str.split(':')
    s, ms = rest.split(',')
    return int(h) * 3600 + int(m) * 60 + int(s) + int(ms) / 1000.0

def format_ts(seconds):
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int(round((seconds % 1) * 1000))
    return f'{h:02d}:{m:02d}:{s:02d},{ms:03d}'

with open(srt_path, 'r', encoding='utf-8') as f:
    content = f.read()

def scale_timestamp(match):
    start_str, end_str = match.group(1), match.group(2)
    start = parse_ts(start_str) * scale
    end = parse_ts(end_str) * scale
    return f'{format_ts(start)} --> {format_ts(end)}'

result = re.sub(
    r'(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})',
    scale_timestamp,
    content
)

with open(srt_path, 'w', encoding='utf-8') as f:
    f.write(result)

# Verify
lines = result.strip().split('\n')
ts_lines = [l for l in lines if '-->' in l]
if ts_lines:
    last_end = ts_lines[-1].split('-->')[1].strip()
    print(f'  Scaled {len(ts_lines)} entries')
    print(f'  New SRT end: {last_end}')
" "$SCALE" "$OUTPUT_SRT"

  echo ""
  echo -e "${GREEN}SRT synced with audio!${NC}"
  echo -e "  Output: $OUTPUT_SRT"
  echo ""
  echo -e "Next steps:"
  echo -e "  1. Copy SRT to Remotion: cp $OUTPUT_SRT remotion/public/subtitles.srt"
  echo -e "  2. Render video: cd remotion && npx remotion render BookVideo"
  exit 0
fi

# ============================================================
# MODE: draft — Script → SRT with estimated timing
# ============================================================
if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo -e "${RED}Error: Script file not found: $SCRIPT_FILE${NC}"
  echo "Đã chạy init-video.sh chưa? Đã viết script chưa?"
  exit 1
fi

echo -e "${YELLOW}Generating SRT from script...${NC}"
echo -e "  Input: $SCRIPT_FILE"

PLAIN_TEXT=$(extract_script_text "$SCRIPT_FILE")

if [[ -z "$PLAIN_TEXT" ]]; then
  echo -e "${RED}Error: No text extracted from script. Is the script empty?${NC}"
  exit 1
fi

WORD_COUNT=$(echo "$PLAIN_TEXT" | wc -w)
echo -e "  Extracted ${GREEN}$WORD_COUNT${NC} words"

mkdir -p "$OUTPUT_DIR"

# --- Generate SRT from text ---
python3 -c "
import sys, re

text = sys.argv[1]
srt_path = sys.argv[2]
max_chars = int(sys.argv[3])
chars_per_sec = float(sys.argv[4])
gap_sentence = float(sys.argv[5])
gap_paragraph = float(sys.argv[6])

def format_ts(seconds):
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int(round((seconds % 1) * 1000))
    return f'{h:02d}:{m:02d}:{s:02d},{ms:03d}'

# Step 1: Split text into paragraphs (separated by blank lines)
paragraphs = []
current_para = []
for line in text.split('\n'):
    stripped = line.strip()
    if stripped == '':
        if current_para:
            paragraphs.append(' '.join(current_para))
            current_para = []
    else:
        current_para.append(stripped)
if current_para:
    paragraphs.append(' '.join(current_para))

# Step 2: Split each paragraph into sentences, then into subtitle segments
segments = []  # list of (text, is_paragraph_start)

for para_idx, para in enumerate(paragraphs):
    is_first_in_para = True

    # Split at sentence boundaries: . ! ? followed by space or end
    sentences = re.split(r'(?<=[.!?])\s+', para)

    for sentence in sentences:
        sentence = sentence.strip()
        if not sentence:
            continue

        if len(sentence) <= max_chars:
            segments.append((sentence, is_first_in_para and para_idx > 0))
            is_first_in_para = False
            continue

        # Sentence too long — split at comma first
        parts = re.split(r',\s+', sentence)
        buffer = ''
        for part in parts:
            candidate = (buffer + ', ' + part) if buffer else part
            if len(candidate) <= max_chars:
                buffer = candidate
            else:
                if buffer:
                    segments.append((buffer, is_first_in_para and para_idx > 0))
                    is_first_in_para = False
                # If single part still too long, split at word boundary
                if len(part) > max_chars:
                    words = part.split()
                    word_buf = ''
                    for w in words:
                        cand = (word_buf + ' ' + w) if word_buf else w
                        if len(cand) <= max_chars:
                            word_buf = cand
                        else:
                            if word_buf:
                                segments.append((word_buf, is_first_in_para and para_idx > 0))
                                is_first_in_para = False
                            word_buf = w
                    if word_buf:
                        buffer = word_buf
                    else:
                        buffer = ''
                else:
                    buffer = part
        if buffer:
            segments.append((buffer, is_first_in_para and para_idx > 0))
            is_first_in_para = False

if not segments:
    print('Error: No segments produced', file=sys.stderr)
    sys.exit(1)

# Step 3: Assign estimated timing
srt_lines = []
current_time = 0.0

for i, (seg_text, is_para_start) in enumerate(segments):
    # Add gap before this segment
    if i > 0:
        if is_para_start:
            current_time += gap_paragraph
        else:
            current_time += gap_sentence

    duration = len(seg_text) / chars_per_sec
    start = current_time
    end = current_time + duration

    srt_lines.append(f'{i + 1}')
    srt_lines.append(f'{format_ts(start)} --> {format_ts(end)}')
    srt_lines.append(seg_text)
    srt_lines.append('')

    current_time = end

with open(srt_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(srt_lines))

total_duration = current_time
print(f'  Generated {len(segments)} subtitle segments', flush=True)
print(f'  Estimated duration: {total_duration:.2f}s ({int(total_duration // 60)}m {int(total_duration % 60)}s)', flush=True)
" "$PLAIN_TEXT" "$OUTPUT_SRT" "$MAX_CHARS" "$CHARS_PER_SEC" "$GAP_SENTENCE" "$GAP_PARAGRAPH"

# --- Summary ---
if [[ -f "$OUTPUT_SRT" ]]; then
  ENTRY_COUNT=$(grep -c '^[0-9]\+$' "$OUTPUT_SRT" || echo "0")
  WORD_COUNT=$(grep -v '^[0-9]' "$OUTPUT_SRT" | grep -v '^\s*$' | grep -v -- '-->' | wc -w)
  FILE_SIZE=$(du -h "$OUTPUT_SRT" | cut -f1)

  echo ""
  echo -e "${GREEN}SRT draft generated!${NC}"
  echo -e "  Output: $OUTPUT_SRT"
  echo -e "  Entries: $ENTRY_COUNT | Words: $WORD_COUNT | Size: $FILE_SIZE"
  echo ""
  echo -e "Next steps:"
  echo -e "  1. Generate voice: ./scripts/generate-voice.sh $SLUG"
  echo -e "  2. Sync timestamps: ./scripts/generate-subtitle.sh $SLUG --sync"
  echo -e "  3. Copy to Remotion: cp $OUTPUT_SRT remotion/public/subtitles.srt"
  echo -e "  4. Render video: cd remotion && npx remotion render BookVideo"
else
  echo -e "${RED}Failed to generate subtitles${NC}"
  exit 1
fi
