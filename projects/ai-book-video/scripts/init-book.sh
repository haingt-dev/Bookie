#!/usr/bin/env bash
# init-book.sh — Tạo folder structure + copy templates cho video mới
# Usage: ./scripts/init-book.sh <book-slug>
# Example: ./scripts/init-book.sh atomic-habits

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Validate input ---
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <book-slug>"
  echo "Example: $0 atomic-habits"
  exit 1
fi

SLUG="$1"

# Validate slug format (lowercase, hyphens, numbers only)
if [[ ! "$SLUG" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
  echo "Error: book-slug must be lowercase alphanumeric with hyphens (e.g., atomic-habits)"
  exit 1
fi

BOOK_DIR="$PROJECT_DIR/books/$SLUG"

# --- Check if already exists ---
if [[ -d "$BOOK_DIR" ]]; then
  echo "Error: '$SLUG' already exists at $BOOK_DIR. Aborting."
  exit 1
fi

# --- Create directories ---
echo "Creating directories for '$SLUG'..."

mkdir -p "$BOOK_DIR/scenes"
mkdir -p "$BOOK_DIR/audio"
mkdir -p "$BOOK_DIR/output"

# --- Copy templates ---
echo "Copying templates..."

TEMPLATE_DIR="$PROJECT_DIR/templates"

# Notes template
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

# Script — copy from template
if [[ -f "$TEMPLATE_DIR/script-template.md" ]]; then
  cp "$TEMPLATE_DIR/script-template.md" "$BOOK_DIR/script.md"
else
  echo "  ⚠️  script-template.md not found, creating minimal"
  echo "# Script: [Tên Sách] — [Angle]" > "$BOOK_DIR/script.md"
fi

# Storyboard + Image Prompts (merged)
cat > "$BOOK_DIR/storyboard.md" << 'EOF'
# Storyboard & Image Prompts: [Tên Sách]

> Kết hợp visual notes + AI image prompts cho mỗi scene

## Style Prefix (dùng cho MỌI prompt)

```
Flat illustration style, minimal, clean lines, soft pastel color palette,
muted warm tones, simple geometric shapes, no outlines, modern minimalist,
editorial illustration style, white or light background,
no text, no watermark, no signature
```

## Scenes

### Scene 01 — [Hook]
- **Timestamp**: 0:00 - 0:15
- **Visual**: [Mô tả visual]
- **Image prompt**:
```
[Style prefix], [mô tả scene cụ thể], 16:9 aspect ratio
```
- **Status**: [ ] Generated  [ ] Approved

### Scene 02 — [Context]
- **Timestamp**: 0:15 - 0:45
- **Visual**: [Mô tả visual]
- **Image prompt**:
```
[Style prefix], [mô tả scene cụ thể], 16:9 aspect ratio
```
- **Status**: [ ] Generated  [ ] Approved

<!-- Copy thêm scenes theo nhu cầu (thường 8-15 scenes cho 7 phút) -->
EOF

# Metadata template
cat > "$BOOK_DIR/metadata.md" << 'EOF'
# Video Metadata: [Tên Sách]

## YouTube

### Title (chọn 1)
1. 
2. 
3. 

### Description
```
📚 [Tên sách] — [Tác giả]

[2-3 câu tóm tắt nội dung video]

⏱️ Timestamps:
00:00 — [Section 1]
00:00 — [Section 2]

🔗 Links:
- Mua sách: [link]

📱 Follow Bookie:
- Website: bookiecommunity.com
- Facebook: facebook.com/bookie.community

#Bookie #[TênSách] #ĐọcSách
```

### Tags (15-20)


### Shorts
| Short | Title (≤40 chars) | Hashtags (5) |
|-------|-------------------|--------------|
| 1 | | |
| 2 | | |
| 3 | | |

## Facebook
- Post caption:
- Hashtags:
EOF

# --- Done ---
echo ""
echo "Initialized '$SLUG' successfully!"
echo ""
echo "Structure: books/$SLUG/"
echo "  ├── notes.md          <- Paste NotebookLM output"
echo "  ├── script.md         <- Viet script"
echo "  ├── storyboard.md     <- Storyboard + image prompts"
echo "  ├── metadata.md       <- Title, description, tags"
echo "  ├── scenes/           <- AI illustrations"
echo "  ├── audio/            <- Voiceover (generated)"
echo "  └── output/           <- SRT, timing, final renders"
echo ""
echo "Next steps:"
echo "  1. Extract notes: NotebookLM -> notes.md"
echo "  2. Write script: script.md"
echo "  3. Generate illustrations from storyboard prompts"
echo "  4. Run: make subtitle BOOK=$SLUG"
