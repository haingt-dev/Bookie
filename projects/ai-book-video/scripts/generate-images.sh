#!/usr/bin/env bash
# generate-images.sh — Generate scene images from image-prompts.md via Gemini API (Nano Banana 2)
# Usage: ./scripts/generate-images.sh <book-slug> [--force]
# Prerequisites: GEMINI_API_KEY set in .env or environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
GEMINI_API_KEY="${GEMINI_API_KEY:-}"
GEMINI_MODEL="${GEMINI_MODEL:-gemini-3.1-flash-image-preview}"
GEMINI_IMAGE_SIZE="${GEMINI_IMAGE_SIZE:-2K}"
REQUEST_DELAY=1  # seconds between API calls
GEN_IMAGE_SCRIPT="$SCRIPT_DIR/gemini-gen-image.sh"

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
  echo "Usage: $0 <book-slug> [--force]"
  echo "  --force  Regenerate images even if they already exist"
  exit 1
}

# extract_prompts <image-prompts.md>
# Outputs lines: SCENE_NUM<TAB>PROMPT_TEXT
extract_prompts() {
  local file="$1"
  local scene_num=""

  while IFS= read -r line; do
    # Match scene header: ### Scene 01 — HOOK (0:00 - 0:21)
    if [[ "$line" =~ ^###\ Scene\ ([0-9]+) ]]; then
      scene_num="${BASH_REMATCH[1]}"
      continue
    fi

    # Match prompt line: - **Prompt**: "..."
    if [[ -n "$scene_num" && "$line" =~ ^-\ \*\*Prompt\*\*:\ \"(.+)\"$ ]]; then
      printf '%s\t%s\n' "$scene_num" "${BASH_REMATCH[1]}"
      scene_num=""
    fi
  done < "$file"
}

# generate_image <prompt> <output_path>
# Delegates to the global gen-image skill script
generate_image() {
  local prompt="$1"
  local output="$2"
  "$GEN_IMAGE_SCRIPT" \
    --prompt "$prompt" \
    --output "$output" \
    --aspect "16:9" \
    --size "${GEMINI_IMAGE_SIZE:-2K}" \
    --model "${GEMINI_MODEL}"
}

# ============================================================
# MAIN
# ============================================================

# Parse arguments
FORCE=0
BOOK=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -*) echo -e "${RED}Unknown option: $arg${NC}"; usage ;;
    *) BOOK="$arg" ;;
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

# Validate API key
if [[ -z "$GEMINI_API_KEY" ]]; then
  echo -e "${RED}Error: GEMINI_API_KEY not set. Add it to .env or export it.${NC}"
  exit 1
fi

BOOK_DIR="$PROJECT_DIR/books/$BOOK"
PROMPTS_FILE="$BOOK_DIR/image-prompts.md"
SCENES_DIR="$BOOK_DIR/scenes"

if [[ ! -f "$PROMPTS_FILE" ]]; then
  echo -e "${RED}Error: $PROMPTS_FILE not found. Run /generate-prompts first.${NC}"
  exit 1
fi

mkdir -p "$SCENES_DIR"

echo -e "${CYAN}Generating images for: ${BOOK}${NC}"
echo -e "${CYAN}Model: ${GEMINI_MODEL} | Size: ${GEMINI_IMAGE_SIZE} | Aspect: 16:9${NC}"
echo ""

# Extract prompts
prompts_data=$(extract_prompts "$PROMPTS_FILE")

if [[ -z "$prompts_data" ]]; then
  echo -e "${RED}Error: No prompts found in $PROMPTS_FILE${NC}"
  exit 1
fi

# Process each scene
generated=0
skipped=0
failed=0
total=0

while IFS=$'\t' read -r scene_num prompt_text; do
  total=$((total + 1))
  scene_id="scene-$(printf '%02d' "$((10#$scene_num))")"
  output_file="$SCENES_DIR/${scene_id}.png"

  # Skip if exists (unless --force)
  if [[ -f "$output_file" && $FORCE -eq 0 ]]; then
    echo -e "  ${CYAN}[${scene_id}]${NC} Skipped (exists)"
    skipped=$((skipped + 1))
    continue
  fi

  echo -ne "  ${CYAN}[${scene_id}]${NC} Generating..."

  if generate_image "$prompt_text" "$output_file"; then
    local_size=$(du -h "$output_file" | cut -f1)
    echo -e "\r  ${GREEN}[${scene_id}]${NC} Done (${local_size})"
    generated=$((generated + 1))
  else
    echo -e "\r  ${RED}[${scene_id}]${NC} Failed"
    failed=$((failed + 1))
  fi

  # Rate limit between requests
  if [[ $total -lt $(echo "$prompts_data" | wc -l) ]]; then
    sleep "$REQUEST_DELAY"
  fi
done <<< "$prompts_data"

# Summary
echo ""
echo -e "${CYAN}Summary:${NC} ${generated} generated, ${skipped} skipped, ${failed} failed (${total} total)"

if [[ $failed -gt 0 ]]; then
  echo -e "${YELLOW}Tip: Re-run with same command to retry failed scenes (existing ones will be skipped).${NC}"
  exit 1
fi

echo -e "${GREEN}All images ready in ${SCENES_DIR}/${NC}"
