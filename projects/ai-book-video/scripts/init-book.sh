#!/usr/bin/env bash
# init-book.sh — Scaffold folder structure for a new book video
# Usage: ./scripts/init-book.sh <book-slug>
# Example: ./scripts/init-book.sh atomic-habits

set -euo pipefail

# --- Colors ---
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# --- Validate input ---
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <book-slug>"
  echo "Example: $0 atomic-habits"
  exit 1
fi

SLUG="$1"

# Validate slug format (lowercase, hyphens, numbers only)
if [[ ! "$SLUG" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
  echo -e "${RED}Error: book-slug must be lowercase alphanumeric with hyphens (e.g., atomic-habits)${NC}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BOOK_DIR="$PROJECT_DIR/books/$SLUG"

# --- Check if already exists ---
if [[ -d "$BOOK_DIR" ]]; then
  echo -e "${RED}Error: '$SLUG' already exists at $BOOK_DIR${NC}"
  exit 1
fi

# --- Create directories ---
echo "Creating directories for '$SLUG'..."

mkdir -p "$BOOK_DIR/scenes"
mkdir -p "$BOOK_DIR/audio"
mkdir -p "$BOOK_DIR/output"

# --- Create notes.md placeholder ---
cat > "$BOOK_DIR/notes.md" << 'EOF'
# Notes: [Tên Sách]

> **Source**: NotebookLM
> **Ngày extract**: [YYYY-MM-DD]

## Key Insights (3-5 ý chính)

1.
2.
3.

## Quotes đắt giá

> "[Quote 1]" — Trang X

> "[Quote 2]" — Trang X

## Câu chuyện / Ví dụ hay

### [Tên câu chuyện 1]
[Mô tả]

## Competitive Analysis (nhanh)

- YouTube VN đã có video nào về sách này?
- Angle nào chưa ai khai thác?
- Keywords gap:
EOF

# --- Done ---
echo ""
echo -e "${GREEN}Initialized '$SLUG' successfully!${NC}"
echo ""
echo "Structure: books/$SLUG/"
echo "  ├── notes.md          <- Placeholder (skills fill content)"
echo "  ├── scenes/           <- AI illustrations (generated)"
echo "  ├── audio/            <- Voiceover (generated)"
echo "  └── output/           <- SRT, timing, video"
echo ""
echo "Next steps:"
echo "  /produce-video $SLUG              (full auto — one interaction)"
echo ""
echo "  -- OR granular: --"
echo "  1. /extract-notes $SLUG"
echo "  2. /create-storyboard $SLUG"
echo "  3. /write-video $SLUG"
echo "  4. make voice BOOK=$SLUG"
echo "  5. /generate-prompts $SLUG"
echo "  6. make produce BOOK=$SLUG ARGS=\"--skip-voice\""
