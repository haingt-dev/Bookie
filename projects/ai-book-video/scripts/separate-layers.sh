#!/usr/bin/env bash
# separate-layers.sh — Tách illustration thành foreground/background cho parallax
#
# Usage: ./scripts/separate-layers.sh <book-slug> [options]
#
# Pipeline per image:
#   1. rembg (BiRefNet) → foreground with alpha
#   2. Python: extract alpha → binary mask PNG
#   3. iopaint (LaMa) → inpainted background
#
# Options:
#   --force       Overwrite existing layer files
#   --dry-run     Show what would be processed, don't execute
#   --model NAME  rembg model (default: birefnet-general, alt: isnet-anime)

set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$SCRIPT_DIR/.venv-layers"
REMBG_MODEL="birefnet-general"
FORCE=false
DRY_RUN=false

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[layers]${NC} $*"; }
ok()   { echo -e "${GREEN}[  OK  ]${NC} $*"; }
warn() { echo -e "${YELLOW}[ WARN ]${NC} $*"; }
err()  { echo -e "${RED}[ERROR ]${NC} $*" >&2; }

usage() {
    echo "Usage: $0 <book-slug> [--force] [--dry-run] [--model NAME]"
    echo ""
    echo "Separates scene illustrations into foreground/background layers."
    echo ""
    echo "Options:"
    echo "  --force       Overwrite existing layer files"
    echo "  --dry-run     Show what would be processed"
    echo "  --model NAME  rembg model (default: birefnet-general)"
    echo "                Alternatives: isnet-anime, u2net"
    exit 1
}

# --- Parse args ---
SLUG=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --force) FORCE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --model) REMBG_MODEL="$2"; shift 2 ;;
        -h|--help) usage ;;
        -*) err "Unknown option: $1"; usage ;;
        *) SLUG="$1"; shift ;;
    esac
done

[[ -z "$SLUG" ]] && { err "Missing <book-slug>"; usage; }

SCENES_DIR="$PROJECT_DIR/assets/$SLUG/scenes"
[[ -d "$SCENES_DIR" ]] || { err "Scenes directory not found: $SCENES_DIR"; exit 1; }

# --- Activate venv ---
if [[ ! -d "$VENV_DIR" ]]; then
    err "Venv not found at $VENV_DIR"
    err "Create it with: uv venv --python 3.12 $VENV_DIR"
    exit 1
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

# --- Verify tools ---
check_tool() {
    if ! command -v "$1" &>/dev/null; then
        err "$1 not found. Install with: uv pip install $2"
        exit 1
    fi
}

check_tool rembg "rembg[gpu]"
check_tool iopaint iopaint

# --- Collect input files ---
# Skip files with -fg, -bg, -mask suffixes
mapfile -t INPUT_FILES < <(
    find "$SCENES_DIR" -maxdepth 1 -name '*.png' -type f \
        ! -name '*-fg.png' \
        ! -name '*-bg.png' \
        ! -name '*-mask.png' \
    | sort
)

if [[ ${#INPUT_FILES[@]} -eq 0 ]]; then
    warn "No PNG files found in $SCENES_DIR (excluding -fg/-bg/-mask)"
    exit 0
fi

log "Found ${#INPUT_FILES[@]} scene(s) in $SCENES_DIR"
log "Model: $REMBG_MODEL | Force: $FORCE | Dry run: $DRY_RUN"
echo ""

# --- Process each scene ---
PROCESSED=0
SKIPPED=0
WARNINGS=0
TOTAL=${#INPUT_FILES[@]}
START_TIME=$SECONDS

for i in "${!INPUT_FILES[@]}"; do
    INPUT="${INPUT_FILES[$i]}"
    BASENAME="$(basename "$INPUT" .png)"
    FG_FILE="$SCENES_DIR/${BASENAME}-fg.png"
    MASK_FILE="$SCENES_DIR/${BASENAME}-mask.png"
    BG_FILE="$SCENES_DIR/${BASENAME}-bg.png"

    COUNTER="[$((i + 1))/$TOTAL]"

    # Check if already processed
    if [[ "$FORCE" != true ]] && [[ -f "$FG_FILE" ]] && [[ -f "$BG_FILE" ]]; then
        log "$COUNTER $BASENAME — already processed, skipping"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "$COUNTER $BASENAME → would generate: -fg.png, -mask.png, -bg.png"
        continue
    fi

    log "$COUNTER Processing $BASENAME..."

    # Step 1: rembg — extract foreground with alpha
    log "  → rembg ($REMBG_MODEL)..."
    rembg i -m "$REMBG_MODEL" "$INPUT" "$FG_FILE" 2>/dev/null
    ok "  Foreground: $FG_FILE"

    # Step 2: Extract alpha channel → binary mask (white = hole to fill)
    log "  → Extracting mask..."
    python3 -c "
from PIL import Image
import numpy as np

img = Image.open('$FG_FILE').convert('RGBA')
alpha = np.array(img.split()[3])

# Invert: transparent areas (alpha=0) become white (255) = areas to inpaint
mask = np.where(alpha < 128, 255, 0).astype(np.uint8)

# Dilate mask slightly to cover edge artifacts
from PIL import ImageFilter
mask_img = Image.fromarray(mask, mode='L')
mask_img = mask_img.filter(ImageFilter.MaxFilter(5))
mask_img.save('$MASK_FILE')

# Quality check: alpha coverage percentage
coverage = np.mean(alpha > 128) * 100
print(f'COVERAGE:{coverage:.1f}')
" 2>/dev/null | while IFS= read -r line; do
        if [[ "$line" == COVERAGE:* ]]; then
            COV="${line#COVERAGE:}"
            if (( $(echo "$COV < 5" | bc -l) )); then
                warn "  Alpha coverage ${COV}% — foreground too small, check segmentation"
                # Use a subshell trick to pass warning count
                echo "WARN" >> /tmp/layers_warnings_$$
            elif (( $(echo "$COV > 95" | bc -l) )); then
                warn "  Alpha coverage ${COV}% — foreground too large, check segmentation"
                echo "WARN" >> /tmp/layers_warnings_$$
            else
                ok "  Mask: $MASK_FILE (coverage: ${COV}%)"
            fi
        fi
    done
    # Count warnings from temp file
    if [[ -f "/tmp/layers_warnings_$$" ]]; then
        WARNINGS=$((WARNINGS + $(wc -l < /tmp/layers_warnings_$$)))
        rm -f "/tmp/layers_warnings_$$"
    fi

    # Step 3: iopaint — inpaint background using LaMa
    # iopaint --output expects a directory, so use temp dir then move
    log "  → iopaint (LaMa)..."
    IOPAINT_TMP="$(mktemp -d)"
    iopaint run \
        --model=lama \
        --device=cuda \
        --image="$INPUT" \
        --mask="$MASK_FILE" \
        --output="$IOPAINT_TMP" 2>/dev/null
    # iopaint saves with original filename inside output dir
    mv "$IOPAINT_TMP/$(basename "$INPUT")" "$BG_FILE"
    rm -rf "$IOPAINT_TMP"
    ok "  Background: $BG_FILE"

    PROCESSED=$((PROCESSED + 1))
    echo ""
done

# --- Summary ---
ELAPSED=$((SECONDS - START_TIME))
echo ""
log "━━━ Summary ━━━"
log "Processed: $PROCESSED | Skipped: $SKIPPED | Warnings: $WARNINGS"
log "Time: ${ELAPSED}s"

if [[ $WARNINGS -gt 0 ]]; then
    warn "Some scenes had unusual alpha coverage."
    warn "Review those scenes — consider removing 'layers' from scenes.json to fallback to Ken Burns."
fi
