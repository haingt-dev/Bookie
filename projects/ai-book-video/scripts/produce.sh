#!/usr/bin/env bash
# produce.sh — Run full production pipeline (voice → render)
# Usage: ./scripts/produce.sh <book-slug> [--skip-voice] [--skip-images] [--skip-render]
# Prerequisites: viXTTS server running, GEMINI_API_KEY set in .env

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
VIXTTS_API_URL="${VIXTTS_API_URL:-http://127.0.0.1:8020}"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================
# FUNCTIONS
# ============================================================

usage() {
  echo "Usage: $0 <book-slug> [--skip-voice] [--skip-images] [--skip-render]"
  echo ""
  echo "Options:"
  echo "  --skip-voice   Reuse existing voiceover (skip TTS generation)"
  echo "  --skip-images  Reuse existing scene images (skip Gemini API)"
  echo "  --skip-render  Stop before rendering (for Remotion Studio preview)"
  exit 1
}

step() {
  local num="$1" label="$2"
  echo ""
  echo -e "${CYAN}[$num] $label${NC}"
}

check_vixtts() {
  local response
  response=$(curl -s --max-time 3 "$VIXTTS_API_URL/speakers" 2>/dev/null || echo "")
  if [[ -z "$response" ]]; then
    echo -e "${RED}Error: viXTTS server not reachable at $VIXTTS_API_URL${NC}"
    echo -e "${YELLOW}Start it with: ./scripts/vixtts-server.sh start${NC}"
    return 1
  fi
}

# ============================================================
# MAIN
# ============================================================

# Parse arguments
SKIP_VOICE=0
SKIP_IMAGES=0
SKIP_RENDER=0
BOOK=""

for arg in "$@"; do
  case "$arg" in
    --skip-voice)  SKIP_VOICE=1 ;;
    --skip-images) SKIP_IMAGES=1 ;;
    --skip-render) SKIP_RENDER=1 ;;
    --help|-h)     usage ;;
    -*)            echo -e "${RED}Unknown option: $arg${NC}"; usage ;;
    *)             BOOK="$arg" ;;
  esac
done

[[ -z "$BOOK" ]] && usage

# Load .env if present
ENV_FILE="$PROJECT_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

BOOK_DIR="$PROJECT_DIR/books/$BOOK"

# --- Prerequisites ---
echo -e "${CYAN}=== Production Pipeline: ${BOOK} ===${NC}"

# Check book directory
if [[ ! -d "$BOOK_DIR" ]]; then
  echo -e "${RED}Error: Book directory not found: $BOOK_DIR${NC}"
  exit 1
fi

# Check chunks.md (required for voice)
if [[ $SKIP_VOICE -eq 0 && ! -f "$BOOK_DIR/chunks.md" ]]; then
  echo -e "${RED}Error: chunks.md not found. Run /write-video first.${NC}"
  exit 1
fi

# Check viXTTS (required for voice)
if [[ $SKIP_VOICE -eq 0 ]]; then
  check_vixtts || exit 1
fi

# Check image-prompts.md (required for images)
if [[ $SKIP_IMAGES -eq 0 && ! -f "$BOOK_DIR/image-prompts.md" ]]; then
  echo -e "${RED}Error: image-prompts.md not found. Run /generate-prompts first.${NC}"
  exit 1
fi

# Check GEMINI_API_KEY (required for images)
if [[ $SKIP_IMAGES -eq 0 && -z "${GEMINI_API_KEY:-}" ]]; then
  echo -e "${RED}Error: GEMINI_API_KEY not set. Add it to .env or export it.${NC}"
  exit 1
fi

# Check voice exists if skipping voice generation
if [[ $SKIP_VOICE -eq 1 && ! -f "$BOOK_DIR/audio/voiceover.wav" ]]; then
  echo -e "${RED}Error: --skip-voice but no voiceover.wav found.${NC}"
  exit 1
fi

echo -e "${GREEN}Prerequisites OK${NC}"

# --- Pipeline ---
FAILED=0

# Step 1: Voice
if [[ $SKIP_VOICE -eq 0 ]]; then
  step "1/7" "Generating voiceover (viXTTS)..."
  if ! make -C "$PROJECT_DIR" voice BOOK="$BOOK"; then
    echo -e "${RED}Voice generation failed${NC}"
    exit 1
  fi
else
  step "1/7" "Voice: skipped (--skip-voice)"
fi

# Step 2: Images
if [[ $SKIP_IMAGES -eq 0 ]]; then
  step "2/7" "Generating scene images (Gemini API)..."
  if ! make -C "$PROJECT_DIR" images BOOK="$BOOK"; then
    echo -e "${RED}Image generation failed${NC}"
    FAILED=1
  fi
else
  step "2/7" "Images: skipped (--skip-images)"
fi

# Step 3: Subtitles
step "3/7" "Generating subtitles..."
if ! make -C "$PROJECT_DIR" subtitle BOOK="$BOOK"; then
  echo -e "${RED}Subtitle generation failed${NC}"
  FAILED=1
fi

# Step 4: Scenes
step "4/7" "Generating scenes.json..."
if ! make -C "$PROJECT_DIR" scenes BOOK="$BOOK"; then
  echo -e "${RED}Scene generation failed${NC}"
  FAILED=1
fi

# Step 5: Sync
step "5/7" "Syncing assets to Remotion..."
if ! make -C "$PROJECT_DIR" sync BOOK="$BOOK"; then
  echo -e "${RED}Asset sync failed${NC}"
  FAILED=1
fi

# Step 6: Validate
step "6/7" "Validating subtitles..."
make -C "$PROJECT_DIR" validate BOOK="$BOOK" || true

# Step 7: Render
if [[ $SKIP_RENDER -eq 0 && $FAILED -eq 0 ]]; then
  step "7/7" "Rendering video..."
  if ! make -C "$PROJECT_DIR" render BOOK="$BOOK"; then
    echo -e "${RED}Render failed${NC}"
    FAILED=1
  fi
elif [[ $SKIP_RENDER -eq 1 ]]; then
  step "7/7" "Render: skipped (--skip-render)"
  echo -e "${YELLOW}Preview with: make studio BOOK=$BOOK${NC}"
else
  step "7/7" "Render: skipped (earlier step failed)"
fi

# --- Summary ---
echo ""
echo -e "${CYAN}=== Summary ===${NC}"

VIDEO_FILE="$BOOK_DIR/output/video.mp4"

if [[ $FAILED -eq 0 && -f "$VIDEO_FILE" ]]; then
  VIDEO_SIZE=$(du -h "$VIDEO_FILE" | cut -f1)
  VIDEO_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$VIDEO_FILE" 2>/dev/null || echo "unknown")
  if [[ "$VIDEO_DURATION" != "unknown" ]]; then
    # Convert seconds to mm:ss
    VIDEO_DURATION=$(printf '%d:%02d' "$(echo "$VIDEO_DURATION/60" | bc)" "$(echo "$VIDEO_DURATION%60/1" | bc)")
  fi
  echo -e "${GREEN}Video ready: $VIDEO_FILE ($VIDEO_DURATION, $VIDEO_SIZE)${NC}"
elif [[ $SKIP_RENDER -eq 1 ]]; then
  echo -e "${YELLOW}Pipeline complete (render skipped). Preview with: make studio BOOK=$BOOK${NC}"
else
  echo -e "${RED}Pipeline completed with errors. Check output above.${NC}"
  exit 1
fi
