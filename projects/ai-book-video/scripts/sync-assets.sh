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

# Remove old symlinks/dirs
rm -rf "$PUBLIC_DIR/scenes" "$PUBLIC_DIR/audio"
rm -f "$PUBLIC_DIR/subtitles.srt"

# Create symlinks (absolute paths)
ln -s "$BOOK_DIR/scenes" "$PUBLIC_DIR/scenes"
ln -s "$BOOK_DIR/audio" "$PUBLIC_DIR/audio"

if [[ -f "$BOOK_DIR/output/subtitles.srt" ]]; then
  ln -s "$BOOK_DIR/output/subtitles.srt" "$PUBLIC_DIR/subtitles.srt"
fi

echo "Synced: books/$SLUG -> remotion/public/"
echo "  scenes/       -> $(readlink "$PUBLIC_DIR/scenes")"
echo "  audio/        -> $(readlink "$PUBLIC_DIR/audio")"
if [[ -L "$PUBLIC_DIR/subtitles.srt" ]]; then
  echo "  subtitles.srt -> $(readlink "$PUBLIC_DIR/subtitles.srt")"
fi
