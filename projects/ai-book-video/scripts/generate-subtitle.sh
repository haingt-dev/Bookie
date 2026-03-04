#!/usr/bin/env bash
# generate-subtitle.sh — Generate SRT subtitles from script markdown
# Pipeline: Script (markdown) → SRT (perfect text + estimated timing)
#
# Usage:
#   ./scripts/generate-subtitle.sh <book-slug>            # Script → SRT (pace-aware, scene timing)
#   ./scripts/generate-subtitle.sh <book-slug> --sync     # Scale SRT timestamps to match audio

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
MAX_CHARS=55                  # Max chars per subtitle line before splitting

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Validate input ---
if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <book-slug> [--sync]${NC}"
  echo "Example: $0 atomic-habits          # Script → SRT (pace-aware)"
  echo "         $0 atomic-habits --sync   # Scale SRT to match audio"
  echo ""
  echo "Input:  books/<slug>/script.md"
  echo "Output: books/<slug>/output/subtitles.srt"
  exit 1
fi

SLUG="$1"
MODE="smart"
if [[ "${2:-}" == "--sync" ]]; then
  MODE="sync"
fi

SCRIPT_FILE="$PROJECT_DIR/books/$SLUG/script.md"
OUTPUT_DIR="$PROJECT_DIR/books/$SLUG/output"
OUTPUT_SRT="$OUTPUT_DIR/subtitles.srt"
OUTPUT_TIMING="$OUTPUT_DIR/section-timing.json"
INPUT_WAV="$PROJECT_DIR/books/$SLUG/audio/voiceover.wav"

# ============================================================
# MODE: --sync — Scale SRT timestamps to match audio duration
# ============================================================
if [[ "$MODE" == "sync" ]]; then
  if [[ ! -f "$OUTPUT_SRT" ]]; then
    echo -e "${RED}Error: SRT file not found: $OUTPUT_SRT${NC}"
    echo "Chạy generate-subtitle.sh $SLUG trước (không có --sync) để tạo SRT."
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
# Generate pace-aware SRT from scene markers in script
# ============================================================
if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo -e "${RED}Error: Script file not found: $SCRIPT_FILE${NC}"
  exit 1
fi

echo -e "${YELLOW}Generating pace-aware SRT from script...${NC}"
echo -e "  Input: $SCRIPT_FILE"

mkdir -p "$OUTPUT_DIR"

python3 -c "
import re, sys, json

script_path = sys.argv[1]
srt_path = sys.argv[2]
timing_path = sys.argv[3]
max_chars = int(sys.argv[4])

# --- Pace presets ---
PACE = {
  'slow':   {'cps': 12, 'gap_sent': 0.30, 'gap_para': 0.60},
  'normal': {'cps': 15, 'gap_sent': 0.15, 'gap_para': 0.40},
  'fast':   {'cps': 17, 'gap_sent': 0.10, 'gap_para': 0.30},
}
GAP_SCENE = 0.8  # silence between scenes

def format_ts(seconds):
  h = int(seconds // 3600)
  m = int((seconds % 3600) // 60)
  s = int(seconds % 60)
  ms = int(round((seconds % 1) * 1000))
  return f'{h:02d}:{m:02d}:{s:02d},{ms:03d}'

def clean_line(line):
  \"\"\"Remove markdown formatting from a line.\"\"\"
  s = line.strip()
  # Skip non-narration lines
  if not s:
      return ''
  if s.startswith('#'):
      return None
  if s.startswith('>'):
      return None
  if s.startswith('**Visual**'):
      return None
  if s == '---':
      return None
  if re.match(r'^\*\*\[SHORT\]\*\*$', s) or s == '[SHORT]':
      return None
  if re.match(r'^<!--', s):
      return None
  if re.match(r'^\*\*(Target length|Tác giả|Thể loại|Ngày tạo)\*\*', s):
      return None
  if s.startswith('\`\`\`'):
      return None
  # Clean inline formatting
  s = s.replace('**', '').replace('*', '')
  s = s.replace('[SHORT]', '').strip()
  return s if s else ''

def split_to_segments(text, max_chars):
  \"\"\"Split text into subtitle segments <= max_chars.\"\"\"
  # Split into paragraphs
  paragraphs = []
  current_para = []
  for line in text.split('\\n'):
      stripped = line.strip()
      if stripped == '':
          if current_para:
              paragraphs.append(' '.join(current_para))
              current_para = []
      else:
          current_para.append(stripped)
  if current_para:
      paragraphs.append(' '.join(current_para))

  segments = []  # (text, is_paragraph_start)
  for para_idx, para in enumerate(paragraphs):
      is_first = True
      sentences = re.split(r'(?<=[.!?])\s+', para)
      for sentence in sentences:
          sentence = sentence.strip()
          if not sentence:
              continue
          if len(sentence) <= max_chars:
              segments.append((sentence, is_first and para_idx > 0))
              is_first = False
              continue
          # Split at comma
          parts = re.split(r',\s+', sentence)
          buf = ''
          for part in parts:
              candidate = (buf + ', ' + part) if buf else part
              if len(candidate) <= max_chars:
                  buf = candidate
              else:
                  if buf:
                      segments.append((buf, is_first and para_idx > 0))
                      is_first = False
                  if len(part) > max_chars:
                      words = part.split()
                      wbuf = ''
                      for w in words:
                          cand = (wbuf + ' ' + w) if wbuf else w
                          if len(cand) <= max_chars:
                              wbuf = cand
                          else:
                              if wbuf:
                                  segments.append((wbuf, is_first and para_idx > 0))
                                  is_first = False
                              wbuf = w
                      buf = wbuf or ''
                  else:
                      buf = part
          if buf:
              segments.append((buf, is_first and para_idx > 0))
              is_first = False
  return segments

# --- Parse script.md ---
with open(script_path, 'r', encoding='utf-8') as f:
  content = f.read()

# Find scene markers
scene_re = re.compile(r'<!-- scene: (scene-\d+), pace: (\w+) -->')
markers = list(scene_re.finditer(content))

if not markers:
  print('Error: No scene markers found in script. Add <!-- scene: scene-XX, pace: Y --> markers.', file=sys.stderr)
  sys.exit(1)

# Extract sections between markers
sections = []
for i, m in enumerate(markers):
  scene_id = m.group(1)
  pace = m.group(2)
  start = m.end()
  # End at next scene marker, or at ## Notes, or end of file
  if i + 1 < len(markers):
      end = markers[i + 1].start()
  else:
      notes_match = re.search(r'^## Notes', content[start:], re.MULTILINE)
      end = start + notes_match.start() if notes_match else len(content)

  raw_text = content[start:end]
  # Clean lines
  cleaned_lines = []
  in_code = False
  for line in raw_text.split('\\n'):
      if line.strip().startswith('\`\`\`'):
          in_code = not in_code
          continue
      if in_code:
          continue
      cl = clean_line(line)
      if cl is not None:
          cleaned_lines.append(cl)

  text = '\\n'.join(cleaned_lines).strip()
  # Collapse multiple blank lines
  text = re.sub(r'\\n{3,}', '\\n\\n', text)

  if text:
      sections.append({'scene': scene_id, 'pace': pace, 'text': text})

if not sections:
  print('Error: No text extracted from script sections.', file=sys.stderr)
  sys.exit(1)

print(f'  Found {len(sections)} scenes with pace markers')

# --- Generate SRT with pace-aware timing ---
srt_lines = []
timing_data = []
seg_index = 0
current_time = 0.0

for sec_idx, section in enumerate(sections):
  pace_cfg = PACE.get(section['pace'], PACE['normal'])
  cps = pace_cfg['cps']
  gap_sent = pace_cfg['gap_sent']
  gap_para = pace_cfg['gap_para']

  # Scene gap (not before first scene)
  if sec_idx > 0:
      current_time += GAP_SCENE

  scene_start = current_time
  segments = split_to_segments(section['text'], max_chars)

  for i, (seg_text, is_para_start) in enumerate(segments):
      # Gaps within scene
      if i > 0:
          current_time += gap_para if is_para_start else gap_sent

      duration = len(seg_text) / cps
      start = current_time
      end = current_time + duration

      seg_index += 1
      srt_lines.append(f'{seg_index}')
      srt_lines.append(f'{format_ts(start)} --> {format_ts(end)}')
      srt_lines.append(seg_text)
      srt_lines.append('')

      current_time = end

  scene_end = current_time
  scene_dur = scene_end - scene_start
  timing_data.append({
      'scene': section['scene'],
      'pace': section['pace'],
      'startMs': round(scene_start * 1000),
      'endMs': round(scene_end * 1000),
      'durationSec': round(scene_dur, 2),
  })

  print(f'    {section[\"scene\"]} ({section[\"pace\"]}): {scene_dur:.1f}s')

# Write SRT
with open(srt_path, 'w', encoding='utf-8') as f:
  f.write('\\n'.join(srt_lines))

# Write section timing JSON
with open(timing_path, 'w', encoding='utf-8') as f:
  json.dump(timing_data, f, indent=2, ensure_ascii=False)

total = current_time
print(f'')
print(f'  Total: {seg_index} segments, {total:.1f}s ({int(total // 60)}m {int(total % 60)}s)')
" "$SCRIPT_FILE" "$OUTPUT_SRT" "$OUTPUT_TIMING" "$MAX_CHARS"

if [[ -f "$OUTPUT_SRT" ]]; then
  ENTRY_COUNT=$(grep -c '^[0-9]\+$' "$OUTPUT_SRT" || echo "0")
  WORD_COUNT=$(grep -v '^[0-9]' "$OUTPUT_SRT" | grep -v '^\s*$' | grep -v -- '-->' | wc -w)

  echo ""
  echo -e "${GREEN}Smart SRT generated!${NC}"
  echo -e "  SRT:     $OUTPUT_SRT ($ENTRY_COUNT entries, $WORD_COUNT words)"
  echo -e "  Timing:  $OUTPUT_TIMING"
  echo ""
  echo -e "Next steps:"
  echo -e "  1. Generate voice: make voice BOOK=$SLUG"
  echo -e "  2. Sync assets:    make sync BOOK=$SLUG"
else
echo -e "${RED}Failed to generate subtitles${NC}"
exit 1
fi
