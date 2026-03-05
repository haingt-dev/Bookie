#!/usr/bin/env bash
# generate-scenes.sh — Auto-generate remotion/src/data/scenes.json from pipeline outputs
# Reads: section-timing.json, voiceover.wav, scenes/, metadata.md
#
# Usage: ./scripts/generate-scenes.sh <book-slug>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Validate input ---
if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <book-slug>${NC}"
  echo "Example: $0 atomic-habits"
  echo ""
  echo "Generates remotion/src/data/scenes.json from section-timing.json + scenes/"
  exit 1
fi

SLUG="$1"
BOOK_DIR="$PROJECT_DIR/books/$SLUG"
TIMING_FILE="$BOOK_DIR/output/section-timing.json"
AUDIO_FILE="$BOOK_DIR/audio/voiceover.wav"
SCENES_DIR="$BOOK_DIR/scenes"
METADATA_FILE="$BOOK_DIR/metadata.md"
OUTPUT_FILE="$PROJECT_DIR/remotion/src/data/scenes.json"

# --- Check prerequisites ---
if [[ ! -f "$TIMING_FILE" ]]; then
  echo -e "${RED}Error: section-timing.json not found: $TIMING_FILE${NC}"
  echo "  Run first: make voice BOOK=$SLUG"
  exit 1
fi

if [[ ! -f "$AUDIO_FILE" ]]; then
  echo -e "${RED}Error: voiceover.wav not found: $AUDIO_FILE${NC}"
  echo "  Run first: make voice BOOK=$SLUG"
  exit 1
fi

if ! command -v ffprobe &> /dev/null; then
  echo -e "${RED}Error: ffprobe not found. Install ffmpeg.${NC}"
  exit 1
fi

echo -e "${YELLOW}Generating scenes.json for ${SLUG}...${NC}"

# Get audio duration
AUDIO_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$AUDIO_FILE" 2>/dev/null)
echo -e "  Audio: ${AUDIO_DURATION}s"

python3 - "$TIMING_FILE" "$AUDIO_DURATION" "$SCENES_DIR" "$METADATA_FILE" "$SLUG" "$OUTPUT_FILE" << 'PYTHON_SCRIPT'
import json, sys, os, glob, re

timing_path = sys.argv[1]
audio_duration = float(sys.argv[2])
scenes_dir = sys.argv[3]
metadata_path = sys.argv[4]
slug = sys.argv[5]
output_path = sys.argv[6]

# --- Load timing ---
with open(timing_path, 'r', encoding='utf-8') as f:
    timing = json.load(f)

print(f'  Scenes: {len(timing)}')

# --- Calculate durations (start-to-start) ---
scenes = []
for i, t in enumerate(timing):
    scene_id = t['scene']

    if i + 1 < len(timing):
        duration = (timing[i + 1]['startMs'] - t['startMs']) / 1000.0
    else:
        duration = audio_duration - t['startMs'] / 1000.0

    # Find image file matching scene ID
    image = 'placeholder.png'
    if os.path.isdir(scenes_dir):
        matches = glob.glob(os.path.join(scenes_dir, f'{scene_id}*'))
        if matches:
            image = os.path.basename(matches[0])

    if image == 'placeholder.png':
        print(f'  \033[1;33mWARN\033[0m: No image for {scene_id}, using placeholder')

    scenes.append({
        'id': scene_id,
        'image': image,
        'duration': round(duration, 1)
    })

# --- Parse title from metadata ---
title = f'{slug}'
if os.path.isfile(metadata_path):
    with open(metadata_path, 'r', encoding='utf-8') as f:
        for line in f:
            m = re.match(r'^#\s+Video Metadata:\s*(.+)', line.strip())
            if m:
                title = m.group(1).strip()
                break

# --- Build config ---
config = {
    'title': title,
    'bookSlug': slug,
    'hasBgm': True,
    'subtitleAdjustMs': 0,
    'intro': {'duration': 4},
    'outro': {
        'duration': 10,
        'ctaText': 'Subscribe de khong bo lo!',
        'nextBookTitle': ''
    },
    'scenes': scenes
}

# --- Write output ---
os.makedirs(os.path.dirname(output_path), exist_ok=True)
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(config, f, ensure_ascii=False, indent=2)

# --- Summary ---
total_scene_dur = sum(s['duration'] for s in scenes)
print(f'  Total scene duration: {total_scene_dur:.1f}s')
print(f'  Video estimate: {total_scene_dur + 4 + 10:.0f}s '
      f'({int((total_scene_dur + 14) // 60)}m {int((total_scene_dur + 14) % 60)}s)')
PYTHON_SCRIPT

if [[ -f "$OUTPUT_FILE" ]]; then
  SCENE_COUNT=$(python3 -c "import json; print(len(json.load(open('$OUTPUT_FILE'))['scenes']))")
  echo ""
  echo -e "${GREEN}scenes.json generated!${NC}"
  echo -e "  Output: $OUTPUT_FILE ($SCENE_COUNT scenes)"
  echo ""
  echo -e "Next steps:"
  echo -e "  1. Sync assets: make sync BOOK=$SLUG"
  echo -e "  2. Preview:     make studio BOOK=$SLUG"
else
  echo -e "${RED}Failed to generate scenes.json${NC}"
  exit 1
fi
