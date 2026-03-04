#!/usr/bin/env bash
# validate-subtitle.sh — Validate SRT subtitle quality against audio
# Usage: ./scripts/validate-subtitle.sh <book-slug>

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
  echo "Validates: books/<slug>/output/subtitles.srt against books/<slug>/audio/voiceover.wav"
  exit 1
fi

SLUG="$1"
SRT_FILE="$PROJECT_DIR/books/$SLUG/output/subtitles.srt"
AUDIO_FILE="$PROJECT_DIR/books/$SLUG/audio/voiceover.wav"

if [[ ! -f "$SRT_FILE" ]]; then
  echo -e "${RED}Error: SRT file not found: $SRT_FILE${NC}"
  echo "Chạy generate-subtitle.sh trước."
  exit 1
fi

# Get audio duration if available
AUDIO_DURATION=""
if [[ -f "$AUDIO_FILE" ]] && command -v ffprobe &> /dev/null; then
  AUDIO_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$AUDIO_FILE" 2>/dev/null || echo "")
fi

echo -e "${YELLOW}Validating: $SRT_FILE${NC}"
if [[ -n "$AUDIO_DURATION" ]]; then
  echo -e "  Audio: $AUDIO_FILE (${AUDIO_DURATION}s)"
fi
echo ""

# --- Run validation ---
python3 - "$SRT_FILE" "$AUDIO_DURATION" << 'PYTHON_SCRIPT'
import sys
import re

srt_path = sys.argv[1]
audio_duration_str = sys.argv[2] if len(sys.argv) > 2 else ""
audio_duration = float(audio_duration_str) if audio_duration_str else None

# --- Parse SRT ---
with open(srt_path, "r", encoding="utf-8") as f:
    content = f.read()

# SRT entry pattern: index\ntimestamp --> timestamp\ntext\n
TIMESTAMP_RE = r"(\d{2}):(\d{2}):(\d{2}),(\d{3})"
ENTRY_RE = re.compile(
    rf"(\d+)\n({TIMESTAMP_RE})\s*-->\s*({TIMESTAMP_RE})\n(.+?)(?=\n\n|\n*$)",
    re.DOTALL,
)

def parse_ts(h, m, s, ms):
    return int(h) * 3600 + int(m) * 60 + int(s) + int(ms) / 1000.0

entries = []
for match in ENTRY_RE.finditer(content):
    idx = int(match.group(1))
    start = parse_ts(match.group(3), match.group(4), match.group(5), match.group(6))
    end = parse_ts(match.group(8), match.group(9), match.group(10), match.group(11))
    text = match.group(12).strip()
    entries.append({"idx": idx, "start": start, "end": end, "text": text})

# --- Checks ---
errors = []
warnings = []

# Check 1: SRT not empty
if not entries:
    errors.append("SRT file has no valid entries")
    # Print and exit early
    print(f"\033[0;31mFAIL\033[0m: {errors[0]}")
    sys.exit(1)

print(f"  Entries: {len(entries)}")

# Check 2: Sequential indices
for i, e in enumerate(entries):
    if e["idx"] != i + 1:
        errors.append(f"Entry index {e['idx']} out of sequence (expected {i + 1})")
        break

# Check 3: Timestamps within each entry (end > start)
for e in entries:
    if e["end"] <= e["start"]:
        errors.append(f"Entry {e['idx']}: end ({e['end']:.3f}s) <= start ({e['start']:.3f}s)")

# Check 4: Sequential timestamps (each entry starts >= previous end, with tolerance)
for i in range(1, len(entries)):
    prev_end = entries[i - 1]["end"]
    curr_start = entries[i]["start"]
    if curr_start < prev_end - 0.01:  # 10ms tolerance for float rounding
        errors.append(
            f"Entry {entries[i]['idx']}: starts at {curr_start:.3f}s "
            f"but previous ends at {prev_end:.3f}s (overlap {prev_end - curr_start:.3f}s)"
        )

# Check 5: No gap > 500ms between consecutive entries
max_gap = 0.0
max_gap_at = None
for i in range(1, len(entries)):
    gap = entries[i]["start"] - entries[i - 1]["end"]
    if gap > max_gap:
        max_gap = gap
        max_gap_at = (entries[i - 1]["idx"], entries[i]["idx"])
    if gap > 0.5:
        warnings.append(
            f"Gap {gap:.3f}s between entry {entries[i-1]['idx']} and {entries[i]['idx']} "
            f"({entries[i-1]['end']:.3f}s → {entries[i]['start']:.3f}s)"
        )

# Check 6: No single entry > 15s
for e in entries:
    duration = e["end"] - e["start"]
    if duration > 15.0:
        warnings.append(f"Entry {e['idx']}: duration {duration:.1f}s > 15s limit")

# Check 7: Word rate per entry (Vietnamese: ~2-5 words/sec)
for e in entries:
    duration = e["end"] - e["start"]
    if duration <= 0:
        continue
    word_count = len(e["text"].split())
    rate = word_count / duration
    if rate > 6.0:
        warnings.append(f"Entry {e['idx']}: {rate:.1f} words/sec (too fast, expected ≤5)")
    elif rate < 1.0 and word_count > 1:
        warnings.append(f"Entry {e['idx']}: {rate:.1f} words/sec (too slow, expected ≥2)")

# Check 8: SRT duration vs audio duration
srt_start = entries[0]["start"]
srt_end = entries[-1]["end"]
srt_duration = srt_end - srt_start

if audio_duration:
    diff = abs(srt_end - audio_duration)
    if diff > 1.0:
        warnings.append(
            f"SRT end ({srt_end:.2f}s) differs from audio duration ({audio_duration:.2f}s) "
            f"by {diff:.2f}s (tolerance: ±1s)"
        )

# Check 9: Empty text
for e in entries:
    if not e["text"].strip():
        errors.append(f"Entry {e['idx']}: empty text")

# --- Report ---
total_words = sum(len(e["text"].split()) for e in entries)
avg_rate = total_words / srt_duration if srt_duration > 0 else 0

print(f"  SRT span: {srt_start:.2f}s → {srt_end:.2f}s ({srt_duration:.2f}s)")
if audio_duration:
    coverage = srt_end / audio_duration * 100
    print(f"  Audio duration: {audio_duration:.2f}s (coverage: {coverage:.0f}%)")
print(f"  Total words: {total_words} ({avg_rate:.1f} words/sec avg)")
if max_gap_at:
    print(f"  Max gap: {max_gap:.3f}s (between entry {max_gap_at[0]} and {max_gap_at[1]})")
print()

if errors:
    for e in errors:
        print(f"\033[0;31mERROR\033[0m: {e}")
if warnings:
    for w in warnings:
        print(f"\033[1;33mWARN\033[0m:  {w}")

if errors:
    print(f"\n\033[0;31m{'='*40}\033[0m")
    print(f"\033[0;31mFAILED: {len(errors)} error(s), {len(warnings)} warning(s)\033[0m")
    sys.exit(1)
elif warnings:
    print(f"\n\033[1;33m{'='*40}\033[0m")
    print(f"\033[1;33mPASSED with {len(warnings)} warning(s)\033[0m")
else:
    print(f"\033[0;32m{'='*40}\033[0m")
    print(f"\033[0;32mPASSED: All checks OK\033[0m")
PYTHON_SCRIPT
