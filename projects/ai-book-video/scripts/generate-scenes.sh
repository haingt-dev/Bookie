#!/usr/bin/env bash
# generate-scenes.sh — Auto-generate remotion/src/data/scenes.json from pipeline outputs
# Reads: section-timing.json, voiceover.wav, scenes/, metadata.md, notes.md,
#         storyboard.md, image-prompts.md, chunks-display.md
#
# Phase 3: Auto-fills meta, chapters, per-scene visual hints, isShort flags
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
NOTES_FILE="$BOOK_DIR/notes.md"
STORYBOARD_FILE="$BOOK_DIR/storyboard.md"
PROMPTS_FILE="$BOOK_DIR/image-prompts.md"
CHUNKS_DISPLAY="$BOOK_DIR/chunks-display.md"
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

python3 - "$TIMING_FILE" "$AUDIO_DURATION" "$SCENES_DIR" "$METADATA_FILE" "$SLUG" "$OUTPUT_FILE" "$CHUNKS_DISPLAY" "$NOTES_FILE" "$STORYBOARD_FILE" "$PROMPTS_FILE" << 'PYTHON_SCRIPT'
import json, sys, os, glob, re

timing_path = sys.argv[1]
audio_duration = float(sys.argv[2])
scenes_dir = sys.argv[3]
metadata_path = sys.argv[4]
slug = sys.argv[5]
output_path = sys.argv[6]
chunks_display_path = sys.argv[7]
notes_path = sys.argv[8]
storyboard_path = sys.argv[9]
prompts_path = sys.argv[10]

# --- Load + validate timing ---
with open(timing_path, 'r', encoding='utf-8') as f:
    timing = json.load(f)

if not timing:
    print('\033[0;31mERROR: section-timing.json is empty\033[0m')
    sys.exit(1)

for t in timing:
    for key in ('scene', 'startMs'):
        if key not in t:
            print(f'\033[0;31mERROR: section-timing.json entry missing "{key}": {t}\033[0m')
            sys.exit(1)

print(f'  Scenes: {len(timing)}')

# --- Extract scene labels from chunks-display.md ---
scene_labels = {}
if os.path.isfile(chunks_display_path):
    current_scene = None
    with open(chunks_display_path, 'r', encoding='utf-8') as f:
        for line in f:
            sm = re.match(r'<!--\s*scene:\s*(scene-\d+)', line.strip())
            if sm:
                current_scene = sm.group(1)
                continue
            if current_scene and current_scene not in scene_labels:
                hm = re.match(r'^##\s+(.+)', line.strip())
                if hm:
                    scene_labels[current_scene] = hm.group(1).strip()

# --- Parse meta from notes.md + storyboard.md ---
meta = {}

if os.path.isfile(notes_path):
    with open(notes_path, 'r', encoding='utf-8') as f:
        for line in f:
            m = re.match(r'^#\s+Notes:\s*(.+?)\s*[—–-]\s*(.+)', line.strip())
            if m:
                meta['bookTitle'] = m.group(1).strip()
                meta['author'] = m.group(2).strip()
                break

if os.path.isfile(storyboard_path):
    with open(storyboard_path, 'r', encoding='utf-8') as f:
        for line in f:
            # Extract angle from storyboard title: # Storyboard: <Title> — <Angle>
            m = re.match(r'^#\s+Storyboard:\s*.+?\s*[—–-]\s*(.+)', line.strip())
            if m:
                meta['angle'] = m.group(1).strip()
                break

if meta:
    print(f'  Meta: {meta.get("bookTitle", "?")} by {meta.get("author", "?")}')

# --- Parse isShort from storyboard.md ---
scene_shorts = set()
if os.path.isfile(storyboard_path):
    current_scene_num = None
    with open(storyboard_path, 'r', encoding='utf-8') as f:
        for line in f:
            sm = re.match(r'^###\s+Scene\s+(\d+)', line.strip())
            if sm:
                current_scene_num = int(sm.group(1))
                continue
            if current_scene_num is not None:
                if re.match(r'-\s*\*\*Shorts\*\*:\s*Yes', line.strip(), re.IGNORECASE):
                    scene_shorts.add(f'scene-{current_scene_num:02d}')
                    current_scene_num = None

if scene_shorts:
    print(f'  Shorts: {len(scene_shorts)} scenes marked')

# --- Parse per-scene visual hints from image-prompts.md ---
scene_visuals = {}
if os.path.isfile(prompts_path):
    current_scene = None
    with open(prompts_path, 'r', encoding='utf-8') as f:
        for line in f:
            sm = re.match(r'^###\s+Scene\s+(\d+)', line.strip())
            if sm:
                current_scene = f'scene-{int(sm.group(1)):02d}'
                continue
            if current_scene and current_scene not in scene_visuals:
                lm = re.match(r'-\s*\*\*Layers\*\*:\s*(.+)', line.strip())
                if lm:
                    layers = lm.group(1).lower()
                    vis = {}
                    if 'flat' in layers and 'ken burns' not in layers:
                        vis['layout'] = 'framed'
                    # Zoom direction
                    if 'zoom in' in layers:
                        vis['zoomDir'] = 'in'
                    elif 'zoom out' in layers:
                        vis['zoomDir'] = 'out'
                    # Pan direction
                    if 'pan left' in layers and 'to right' not in layers:
                        vis['panDir'] = 'left'
                    elif 'pan right' in layers or 'left to right' in layers or ('pan' in layers and 'to' in layers):
                        vis['panDir'] = 'right'
                    if vis:
                        scene_visuals[current_scene] = vis
                    current_scene = None

if scene_visuals:
    print(f'  Visual overrides: {len(scene_visuals)} scenes')

# --- Build chapters from scene labels (same logic as chapters.ts) ---
def normalize_label(label):
    if not label:
        return ''
    return re.sub(r'\s*\d+\s*[:.].*$', '', label).strip()

chapters = []
if scene_labels:
    ordered_ids = sorted(scene_labels.keys())
    if ordered_ids:
        current_prefix = normalize_label(scene_labels[ordered_ids[0]])
        start_idx = 0
        for i in range(1, len(ordered_ids)):
            prefix = normalize_label(scene_labels[ordered_ids[i]])
            if prefix != current_prefix:
                chapters.append({
                    'title': current_prefix,
                    'startIndex': start_idx,
                    'endIndex': i - 1
                })
                current_prefix = prefix
                start_idx = i
        chapters.append({
            'title': current_prefix,
            'startIndex': start_idx,
            'endIndex': len(ordered_ids) - 1
        })

if chapters:
    print(f'  Chapters: {len(chapters)}')

# --- Calculate durations (start-to-start) ---
scenes = []
missing = []
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
        missing.append(scene_id)

    entry = {
        'id': scene_id,
        'image': image,
        'duration': round(duration, 1)
    }
    if scene_id in scene_labels:
        entry['label'] = scene_labels[scene_id]
    if scene_id in scene_visuals:
        vis = scene_visuals[scene_id]
        for key in ('layout', 'panDir', 'zoomDir'):
            if key in vis:
                entry[key] = vis[key]
    if scene_id in scene_shorts:
        entry['isShort'] = True
    scenes.append(entry)

# --- Fail hard if any scene is missing an image ---
if missing:
    print(f'\n  \033[0;31mERROR: Missing images for {len(missing)} scene(s):\033[0m')
    for sid in missing:
        print(f'    - {sid}')
    print(f'\n  Generate images first, then re-run.')
    print(f'  Expected: {scenes_dir}/<scene-id>.png (or .jpg/.webp)')
    sys.exit(1)

# --- Parse title from storyboard or metadata ---
title = slug
if os.path.isfile(storyboard_path):
    with open(storyboard_path, 'r', encoding='utf-8') as f:
        for line in f:
            m = re.match(r'^#\s+Storyboard:\s*.+?\s*[—–-]\s*(.+)', line.strip())
            if m:
                title = m.group(1).strip()
                break
if title == slug and os.path.isfile(metadata_path):
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
        'ctaText': 'Subscribe để không bỏ lỡ!',
        'nextBookTitle': ''
    },
    'scenes': scenes
}
if meta:
    config['meta'] = meta
if chapters:
    config['chapters'] = chapters

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
