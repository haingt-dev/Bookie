#!/usr/bin/env bash
# generate-subtitle.sh — Generate SRT subtitles from chunks.md + section-timing.json
# Chunk-based approach: uses ground truth text (no Whisper ASR errors for Vietnamese)
#
# Usage:
#   ./scripts/generate-subtitle.sh <book-slug>            # Chunks → SRT
#   ./scripts/generate-subtitle.sh <book-slug> --sync     # Scale SRT timestamps to match audio

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
MAX_CHARS=55                  # Max chars per subtitle line

# Pace-aware gap config (must match generate-voice.sh)
GAP_SLOW_SENTENCE=0.40
GAP_SLOW_PARAGRAPH=0.80
GAP_NORMAL_SENTENCE=0.15
GAP_NORMAL_PARAGRAPH=0.40
GAP_FAST_SENTENCE=0.08
GAP_FAST_PARAGRAPH=0.20

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Validate input ---
if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <book-slug> [--sync]${NC}"
  echo "Example: $0 atomic-habits          # Chunks → SRT"
  echo "         $0 atomic-habits --sync   # Scale SRT to match audio"
  echo ""
  echo "Requires: make voice BOOK=<slug> first"
  exit 1
fi

SLUG="$1"
MODE="chunks"
if [[ "${2:-}" == "--sync" ]]; then
  MODE="sync"
fi

OUTPUT_DIR="$PROJECT_DIR/books/$SLUG/output"
OUTPUT_SRT="$OUTPUT_DIR/subtitles.srt"
INPUT_WAV="$PROJECT_DIR/books/$SLUG/audio/voiceover.wav"
CHUNKS_FILE="$PROJECT_DIR/books/$SLUG/chunks.md"
DISPLAY_FILE="$PROJECT_DIR/books/$SLUG/chunks-display.md"
TIMING_FILE="$PROJECT_DIR/books/$SLUG/output/section-timing.json"

# ============================================================
# MODE: --sync — Scale SRT timestamps to match audio duration
# ============================================================
if [[ "$MODE" == "sync" ]]; then
  if [[ ! -f "$OUTPUT_SRT" ]]; then
    echo -e "${RED}Error: SRT file not found: $OUTPUT_SRT${NC}"
    echo "  Run: make subtitle BOOK=$SLUG"
    exit 1
  fi

  if [[ ! -f "$INPUT_WAV" ]]; then
    echo -e "${RED}Error: Audio file not found: $INPUT_WAV${NC}"
    echo "  Run: make voice BOOK=$SLUG"
    exit 1
  fi

  if ! command -v ffprobe &> /dev/null; then
    echo -e "${RED}Error: ffprobe not found. Install ffmpeg.${NC}"
    exit 1
  fi

  echo -e "${YELLOW}Syncing SRT timestamps with audio...${NC}"

  AUDIO_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$INPUT_WAV" 2>/dev/null)
  if [[ -z "$AUDIO_DURATION" ]]; then
    echo -e "${RED}Error: Could not read audio duration${NC}"
    exit 1
  fi

  echo -e "  Audio: $INPUT_WAV (${GREEN}${AUDIO_DURATION}s${NC})"

  SRT_DURATION=$(grep -oP '\d+:\d+:\d+,\d+' "$OUTPUT_SRT" | tail -1 | \
    awk -F'[,:]+' '{print ($1 * 3600) + ($2 * 60) + $3 + ($4 / 1000)}')

  if [[ -z "$SRT_DURATION" ]] || (( $(echo "$SRT_DURATION == 0" | bc -l) )); then
    echo -e "${RED}Error: Could not determine SRT duration${NC}"
    exit 1
  fi

  echo -e "  SRT estimated duration: ${YELLOW}${SRT_DURATION}s${NC}"
  SCALE=$(echo "scale=6; $AUDIO_DURATION / $SRT_DURATION" | bc -l)
  echo -e "  Scale factor: ${GREEN}${SCALE}x${NC}"

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
  exit 0
fi

# ============================================================
# Generate SRT from chunks.md + section-timing.json
# ============================================================
if [[ ! -f "$CHUNKS_FILE" ]]; then
  echo -e "${RED}Error: chunks.md not found: $CHUNKS_FILE${NC}"
  echo "  Run first: /split-script $SLUG"
  exit 1
fi

if [[ ! -f "$TIMING_FILE" ]]; then
  echo -e "${RED}Error: section-timing.json not found: $TIMING_FILE${NC}"
  echo "  Run first: make voice BOOK=$SLUG"
  exit 1
fi

if [[ ! -f "$INPUT_WAV" ]]; then
  echo -e "${RED}Error: Audio not found: $INPUT_WAV${NC}"
  echo "  Run first: make voice BOOK=$SLUG"
  exit 1
fi

echo -e "${YELLOW}Generating SRT from chunks.md + display text...${NC}"
echo -e "  Chunks: $CHUNKS_FILE"
echo -e "  Timing: $TIMING_FILE"
if [[ -f "$DISPLAY_FILE" ]]; then
  echo -e "  Display: $DISPLAY_FILE (subtitle text source)"
else
  echo -e "  ${YELLOW}Warning: chunks-display.md not found, using chunks.md text as-is${NC}"
fi

mkdir -p "$OUTPUT_DIR"

python3 - "$CHUNKS_FILE" "$TIMING_FILE" "$OUTPUT_SRT" "$MAX_CHARS" \
  "$GAP_SLOW_SENTENCE" "$GAP_SLOW_PARAGRAPH" \
  "$GAP_NORMAL_SENTENCE" "$GAP_NORMAL_PARAGRAPH" \
  "$GAP_FAST_SENTENCE" "$GAP_FAST_PARAGRAPH" \
  "$DISPLAY_FILE" \
  << 'PYTHON_SCRIPT'
import re, sys, json, os

from math import ceil

chunks_path = sys.argv[1]
timing_path = sys.argv[2]
srt_path = sys.argv[3]
max_chars = int(sys.argv[4])
display_path = sys.argv[11]

# Gap config per pace
gap_config = {
    'slow':   {'sentence': float(sys.argv[5]),  'paragraph': float(sys.argv[6])},
    'normal': {'sentence': float(sys.argv[7]),  'paragraph': float(sys.argv[8])},
    'fast':   {'sentence': float(sys.argv[9]),  'paragraph': float(sys.argv[10])},
}

def format_ts(seconds):
    seconds = max(0, seconds)
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int(round((seconds % 1) * 1000))
    return f'{h:02d}:{m:02d}:{s:02d},{ms:03d}'

def parse_display_chunks(path):
    """Parse chunks-display.md to get display text per chunk number."""
    if not os.path.isfile(path):
        return {}
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    chunk_re = re.compile(r'^\[(\d+)\]\s+"(.+)"$', re.MULTILINE)
    return {int(m.group(1)): m.group(2) for m in chunk_re.finditer(content)}

# --- Parse chunks.md ---
with open(chunks_path, 'r', encoding='utf-8') as f:
    content = f.read()

scene_re = re.compile(r'<!-- scene: (scene-\d+), pace: (\w+) -->')
chunk_re = re.compile(r'^\[(\d+)\]\s+"(.+)"$')

markers = list(scene_re.finditer(content))
scenes = []

for i, m in enumerate(markers):
    scene_id = m.group(1)
    pace = m.group(2)
    start = m.end()
    end = markers[i + 1].start() if i + 1 < len(markers) else len(content)
    section = content[start:end]

    chunks = []
    is_paragraph_break = False

    for line in section.split('\n'):
        s = line.strip()
        if s == '---':
            is_paragraph_break = True
            continue
        cm = chunk_re.match(s)
        if cm:
            chunks.append({
                'idx': int(cm.group(1)),
                'text': cm.group(2),
                'chars': len(cm.group(2)),
                'paragraph_break': is_paragraph_break and len(chunks) > 0,
            })
            is_paragraph_break = False

    if chunks:
        scenes.append({
            'scene_id': scene_id,
            'pace': pace,
            'chunks': chunks,
        })

# --- Build display text from chunks-display.md ---
display_chunks = parse_display_chunks(display_path)
if display_chunks:
    mapped = 0
    for scene in scenes:
        for c in scene['chunks']:
            if c['idx'] in display_chunks:
                c['display_text'] = display_chunks[c['idx']]
                mapped += 1
    print(f'  Display text: {mapped} chunks mapped from chunks-display.md')
else:
    print(f'  Display text: using chunks.md (chunks-display.md not found)')

# --- Load timing ---
with open(timing_path, 'r', encoding='utf-8') as f:
    timing = json.load(f)

timing_map = {t['scene']: t for t in timing}

# --- Generate subtitle entries ---
srt_entries = []
entry_num = 0
total_words = 0

for scene in scenes:
    sid = scene['scene_id']
    pace = scene['pace']
    chunks = scene['chunks']

    if sid not in timing_map:
        print(f'  WARNING: No timing for {sid}, skipping')
        continue

    t = timing_map[sid]
    scene_start_s = t['startMs'] / 1000.0
    scene_duration_s = t['durationSec']

    # Calculate total gap time within scene
    gaps = gap_config.get(pace, gap_config['normal'])
    n_sentence_gaps = 0
    n_paragraph_gaps = 0
    for ci, chunk in enumerate(chunks):
        if ci == 0:
            continue
        if chunk['paragraph_break']:
            n_paragraph_gaps += 1
        else:
            n_sentence_gaps += 1

    total_gap_time = (n_sentence_gaps * gaps['sentence'] +
                      n_paragraph_gaps * gaps['paragraph'])

    # Speech time = scene duration minus gaps
    speech_time = max(scene_duration_s - total_gap_time, 0.1)

    # Total chars in scene
    total_chars = sum(c['chars'] for c in chunks)
    if total_chars == 0:
        continue

    # Distribute timing across chunks
    cursor = scene_start_s

    for ci, chunk in enumerate(chunks):
        # Add gap before this chunk (except first)
        if ci > 0:
            if chunk['paragraph_break']:
                cursor += gaps['paragraph']
            else:
                cursor += gaps['sentence']

        # Chunk duration proportional to char count
        chunk_duration = speech_time * (chunk['chars'] / total_chars)
        chunk_start = cursor
        chunk_end = cursor + chunk_duration

        # Split chunk text into subtitle lines (balanced)
        text = chunk.get('display_text', chunk['text'])
        words = text.split()
        n_lines = max(1, ceil(len(text) / max_chars))
        target_len = len(text) / n_lines

        lines = []
        current_line = ''
        for word in words:
            candidate = f'{current_line} {word}'.strip() if current_line else word
            remaining = len(text) - sum(len(l) + 1 for l in lines) - len(candidate)
            if len(current_line) >= target_len * 0.85 and remaining > 15:
                lines.append(current_line)
                current_line = word
            else:
                current_line = candidate
        if current_line:
            lines.append(current_line)

        # Distribute chunk time across subtitle lines
        line_total_chars = sum(len(l) for l in lines)
        if line_total_chars == 0:
            continue

        line_cursor = chunk_start
        for line in lines:
            line_duration = chunk_duration * (len(line) / line_total_chars)
            line_start = line_cursor
            line_end = line_cursor + line_duration

            entry_num += 1
            total_words += len(line.split())
            srt_entries.append({
                'num': entry_num,
                'start': line_start,
                'end': line_end,
                'text': line,
            })
            line_cursor = line_end

        cursor = chunk_end

# --- Write SRT ---
srt_lines = []
for e in srt_entries:
    srt_lines.append(str(e['num']))
    srt_lines.append(f'{format_ts(e["start"])} --> {format_ts(e["end"])}')
    srt_lines.append(e['text'])
    srt_lines.append('')

with open(srt_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(srt_lines))

last_end = srt_entries[-1]['end'] if srt_entries else 0
print(f'  Scenes: {len(scenes)}')
print(f'  Total: {entry_num} segments, {last_end:.1f}s ({int(last_end // 60)}m {int(last_end % 60)}s)')
PYTHON_SCRIPT

if [[ -f "$OUTPUT_SRT" ]]; then
  ENTRY_COUNT=$(grep -c '^[0-9]\+$' "$OUTPUT_SRT" || echo "0")
  WORD_COUNT=$(grep -v '^[0-9]' "$OUTPUT_SRT" | grep -v '^\s*$' | grep -v -- '-->' | wc -w)

  echo ""
  echo -e "${GREEN}SRT generated (chunk-based, balanced lines)!${NC}"
  echo -e "  SRT: $OUTPUT_SRT ($ENTRY_COUNT entries, $WORD_COUNT words)"
  echo ""
  echo -e "Next steps:"
  echo -e "  1. Validate:    make validate BOOK=$SLUG"
  echo -e "  2. Sync assets: make sync BOOK=$SLUG"
  echo -e "  3. Preview:     make studio"
else
  echo -e "${RED}Failed to generate subtitles${NC}"
  exit 1
fi
