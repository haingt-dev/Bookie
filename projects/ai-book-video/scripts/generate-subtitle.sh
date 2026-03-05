#!/usr/bin/env bash
# generate-subtitle.sh — Generate SRT subtitles using Whisper word timestamps
# Voice-first pipeline: transcribes voiceover audio for accurate subtitle timing
#
# Usage:
#   ./scripts/generate-subtitle.sh <book-slug>            # Whisper → SRT
#   ./scripts/generate-subtitle.sh <book-slug> --sync     # Scale SRT timestamps to match audio

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
MAX_CHARS=55                  # Max chars per subtitle line
WHISPER_MODEL="${WHISPER_MODEL:-large-v3}"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Validate input ---
if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <book-slug> [--sync]${NC}"
  echo "Example: $0 atomic-habits          # Whisper transcription → SRT"
  echo "         $0 atomic-habits --sync   # Scale SRT to match audio"
  echo ""
  echo "Requires: make voice BOOK=<slug> first"
  exit 1
fi

SLUG="$1"
MODE="whisper"
if [[ "${2:-}" == "--sync" ]]; then
  MODE="sync"
fi

SCRIPT_FILE="$PROJECT_DIR/books/$SLUG/script.md"
OUTPUT_DIR="$PROJECT_DIR/books/$SLUG/output"
OUTPUT_SRT="$OUTPUT_DIR/subtitles.srt"
INPUT_WAV="$PROJECT_DIR/books/$SLUG/audio/voiceover.wav"

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
# Generate SRT via Whisper transcription + word timestamps
# ============================================================
if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo -e "${RED}Error: Script not found: $SCRIPT_FILE${NC}"
  exit 1
fi

if [[ ! -f "$INPUT_WAV" ]]; then
  echo -e "${RED}Error: Audio not found: $INPUT_WAV${NC}"
  echo "  Run first: make voice BOOK=$SLUG"
  exit 1
fi

if ! command -v uv &> /dev/null; then
  echo -e "${RED}Error: uv not found. Install: curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
  exit 1
fi

echo -e "${YELLOW}Generating SRT via Whisper (${WHISPER_MODEL})...${NC}"
echo -e "  Audio: $INPUT_WAV"
echo -e "  Model: $WHISPER_MODEL (first run downloads ~3GB)"

mkdir -p "$OUTPUT_DIR"

uv run --python 3.12 \
  --with faster-whisper \
  --with nvidia-cublas-cu12 \
  --with nvidia-cudnn-cu12 \
  python3 - \
  "$OUTPUT_SRT" "$INPUT_WAV" "$MAX_CHARS" "$WHISPER_MODEL" << 'PYTHON_SCRIPT'
import re, sys, ctypes, os, glob

# Preload CUDA libraries from pip packages (nvidia-cublas-cu12, nvidia-cudnn-cu12)
try:
    import nvidia.cublas, nvidia.cudnn
    for pkg_path in list(nvidia.cublas.__path__) + list(nvidia.cudnn.__path__):
        lib_dir = os.path.join(pkg_path, 'lib')
        if os.path.isdir(lib_dir):
            for lib in sorted(glob.glob(os.path.join(lib_dir, '*.so*'))):
                try:
                    ctypes.cdll.LoadLibrary(lib)
                except OSError:
                    pass
except ImportError:
    pass  # Will fall back to CPU if CUDA libs not available

from faster_whisper import WhisperModel

srt_path = sys.argv[1]
audio_path = sys.argv[2]
max_chars = int(sys.argv[3])
model_name = sys.argv[4]

def format_ts(seconds):
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int(round((seconds % 1) * 1000))
    return f'{h:02d}:{m:02d}:{s:02d},{ms:03d}'

# --- Transcribe with word-level timestamps ---
print(f'  Loading model: {model_name}...', flush=True)
model = WhisperModel(model_name, device='auto', compute_type='int8_float16')

print(f'  Transcribing with word timestamps...', flush=True)
segments_iter, info = model.transcribe(
    audio_path,
    language='vi',
    word_timestamps=True,
    vad_filter=True,
    hallucination_silence_threshold=1.0,
    repetition_penalty=1.1,
)

# Collect all words with timestamps
words = []
for segment in segments_iter:
    if segment.words:
        for w in segment.words:
            text = w.word.strip()
            if text and w.end - w.start > 0.01:
                words.append({'start': w.start, 'end': w.end, 'text': text})

if not words:
    print('Error: No words transcribed from audio.', file=sys.stderr)
    sys.exit(1)

print(f'  Transcribed: {len(words)} words, {words[-1]["end"]:.1f}s')

# --- Group words into subtitle segments ---
srt_segments = []
buf = []
buf_text = ''

def flush():
    global buf, buf_text
    if buf:
        srt_segments.append({
            'start': buf[0]['start'],
            'end': buf[-1]['end'],
            'text': buf_text.strip()
        })
        buf = []
        buf_text = ''

for w in words:
    word = w['text']
    candidate = f'{buf_text} {word}'.strip() if buf_text else word

    # Exceeds max chars? Flush current buffer first
    if len(candidate) > max_chars and buf:
        flush()
        buf = [w]
        buf_text = word
    else:
        buf.append(w)
        buf_text = candidate

    # Flush at sentence boundaries
    if re.search(r'[.!?…]$', word):
        flush()

flush()

# --- Post-processing: remove duplicates and anomalies ---
cleaned = []
seen_texts = set()
for seg in srt_segments:
    duration = seg['end'] - seg['start']
    text = seg['text']
    word_count = len(text.split())
    # Skip zero/near-zero duration
    if duration < 0.05:
        continue
    # Skip exact duplicate text (hallucination)
    if text in seen_texts:
        continue
    # Skip suspiciously fast segments (likely hallucination)
    if duration > 0 and word_count / duration > 15:
        continue
    seen_texts.add(text)
    cleaned.append(seg)

removed = len(srt_segments) - len(cleaned)
if removed > 0:
    print(f'  Cleaned: removed {removed} hallucinated segment(s)')
srt_segments = cleaned

if not srt_segments:
    print('Error: No subtitle segments produced.', file=sys.stderr)
    sys.exit(1)

# --- Write SRT ---
srt_lines = []
for i, seg in enumerate(srt_segments, 1):
    srt_lines.append(str(i))
    srt_lines.append(f'{format_ts(seg["start"])} --> {format_ts(seg["end"])}')
    srt_lines.append(seg['text'])
    srt_lines.append('')

with open(srt_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(srt_lines))

total = words[-1]['end']
print(f'')
print(f'  Total: {len(srt_segments)} segments, {total:.1f}s ({int(total // 60)}m {int(total % 60)}s)')
PYTHON_SCRIPT

if [[ -f "$OUTPUT_SRT" ]]; then
  ENTRY_COUNT=$(grep -c '^[0-9]\+$' "$OUTPUT_SRT" || echo "0")
  WORD_COUNT=$(grep -v '^[0-9]' "$OUTPUT_SRT" | grep -v '^\s*$' | grep -v -- '-->' | wc -w)

  echo ""
  echo -e "${GREEN}SRT generated (Whisper word timestamps)!${NC}"
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
