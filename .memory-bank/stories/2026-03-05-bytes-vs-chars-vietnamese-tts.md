# Bytes vs Chars: The Vietnamese UTF-8 Trap

- **Date**: 2026-03-05
- **Tags**: vixtts, utf-8, benchmark, vietnamese
- **Status**: draft

## TL;DR

Built a TTS duration prediction model with R²=0.96, but it underestimated by 17.6% in production. Root cause: benchmark measured bytes (`wc -c`) while Python estimated characters (`len()`). Vietnamese diacritics are multi-byte UTF-8 — fixing one function call (`len(s)` → `len(s.encode("utf-8"))`) dropped error from 17.6% to 1.9%.

## The Problem

viXTTS (self-hosted Vietnamese TTS) has no speed control — it speaks at a fixed rate. We needed a way to predict how long a script would take to narrate *before* running the expensive voice generation pipeline (which takes several minutes on GPU).

The goal: `make estimate BOOK=atomic-habits` tells you "this script will produce a 5m12s video" instantly, without touching the TTS server.

## The Journey

**Step 1: Benchmark.** Created 10 Vietnamese passages (10-200 words), generated voice for each, measured output duration. Got a clean linear regression:

```
duration_sec = 0.047 × chars_nospace + 2.1
R² = 0.96
```

Looked great. The 2.1s intercept = per-segment overhead (leading/trailing silence in each WAV). The 0.047 slope = ~21 effective CPS (characters per second) after overhead.

**Step 2: Build estimator.** Wrote `estimate-timing.sh` — parses script.md, simulates the same text-splitting logic as the production voice pipeline, applies the model per-unit, adds gap timing. Clean architecture, reuses exact same scene parser.

**Step 3: Reality check.** Ran it against Atomic Habits (which already had actual voice timing from a previous generation):

```
Estimated: 252s
Actual:    305s
Delta:     -53.9s (17.6% under)
```

Every single scene was underestimated. Not random noise — systematic bias.

**Step 4: The hunt.** First suspicion: gap calculation bug. Fixed paragraph gaps replacing (not adding to) sentence gaps at boundaries. Didn't help — actually made the estimate slightly worse since we were already overcounting gaps.

Then it hit: *how did the benchmark measure "chars_nospace"?*

```bash
# benchmark-voice.sh
chars_nospace=$(echo "$text" | tr -d ' ' | wc -c | tr -d ' ')
```

`wc -c` counts **bytes**, not characters. Vietnamese diacritics like ỗ, ạ, ừ are 2-3 bytes in UTF-8. But the Python estimator used:

```python
unit_chars = len(unit.replace(" ", ""))  # counts characters, not bytes
```

Vietnamese text has roughly 1.3-1.5× more bytes than characters. A 17.6% gap fits perfectly.

**Step 5: One-line fix.**

```python
unit_bytes = len(unit.replace(" ", "").encode("utf-8"))  # bytes, not chars
```

Result:

```
Estimated: 311s
Actual:    305s
Delta:     +5.7s (1.9%)
```

Per-scene deltas dropped to ±0.3s to ±1.6s. The model was correct all along — just fed the wrong unit of measurement.

## The Insight

When building prediction models across language boundaries (bash → python, or any two systems), **verify that your units of measurement are the same**. `wc -c` and `len()` both "count characters" but mean completely different things for non-ASCII text.

This is especially treacherous with Vietnamese, where every word is a single syllable but most syllables contain diacritics that expand to 2-3 UTF-8 bytes. The error is invisible in ASCII-only testing and only shows up at scale with real Vietnamese content.

The broader lesson: a model with R²=0.96 means nothing if you feed it the wrong input type. The math was perfect; the plumbing was wrong.

## Technical Details

- **viXTTS**: Self-hosted Vietnamese TTS, Podman container, RTX 4070 Super Ti
- **Benchmark model**: `duration_sec = 0.04731 × bytes_nospace + 2.146` (note: bytes, not chars)
- **Vietnamese UTF-8**: avg character = ~1.4 bytes (due to tone/diacritic marks)
- **Production accuracy after fix**: 1.9% error on 9-scene, 5-minute script
- **Tool**: `make estimate BOOK=<slug>` — instant timing prediction, no GPU needed
