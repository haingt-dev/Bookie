#!/usr/bin/env bash
# sync-assets.sh — Symlink book assets into remotion/public for rendering
# Usage: ./scripts/sync-assets.sh <book-slug>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <book-slug>"
  echo "Example: $0 atomic-habits"
  exit 1
fi

SLUG="$1"
BOOK_DIR="$PROJECT_DIR/books/$SLUG"
PUBLIC_DIR="$PROJECT_DIR/remotion/public"

if [[ ! -d "$BOOK_DIR" ]]; then
  echo "Error: Book not found: $BOOK_DIR"
  exit 1
fi

# Remove old symlinks only (never delete real directories)
for target in "$PUBLIC_DIR/scenes" "$PUBLIC_DIR/audio"; do
  if [[ -L "$target" ]]; then
    rm -f "$target"
  elif [[ -e "$target" ]]; then
    echo "Warning: $target exists but is not a symlink — skipping removal"
  fi
done
# Remove old subtitles (symlink or copied file)
rm -f "$PUBLIC_DIR/subtitles.srt"

# Create symlinks (absolute paths)
ln -s "$BOOK_DIR/scenes" "$PUBLIC_DIR/scenes"
ln -s "$BOOK_DIR/audio" "$PUBLIC_DIR/audio"

# Copy SRT (not symlink — Remotion render server returns 404 for file symlinks)
if [[ -f "$BOOK_DIR/output/subtitles.srt" ]]; then
  cp "$BOOK_DIR/output/subtitles.srt" "$PUBLIC_DIR/subtitles.srt"
fi

echo "Synced: books/$SLUG -> remotion/public/"
echo "  scenes/       -> $(readlink "$PUBLIC_DIR/scenes")"
echo "  audio/        -> $(readlink "$PUBLIC_DIR/audio")"
if [[ -f "$PUBLIC_DIR/subtitles.srt" ]]; then
  echo "  subtitles.srt    (copied)"
fi
