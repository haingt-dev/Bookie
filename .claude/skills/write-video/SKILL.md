---
name: write-video
description: "Write book video script as paired TTS-ready chunks"
disable-model-invocation: false
argument-hint: "<book-slug>"
---

# Write Video Script

Write a Bookie book video script directly as numbered chunks, outputting paired files for display (subtitles) and TTS (voice generation). This replaces the old write-script + split-script + estimate flow.

## Context

- **When to use**: After `/create-storyboard` produces storyboard.md. Before `make voice`.
- **Input**: `storyboard.md` (story direction) + `notes.md` (insights) + `tts-config.json` (normalization rules)
- **Output**: `chunks-display.md` (readable script + subtitle source) + `chunks.md` (TTS-normalized)

## Pipeline Position

```
/create-storyboard → storyboard.md
        ↓
/write-video → chunks-display.md + chunks.md  ← YOU ARE HERE
        ↓
make voice → audio + section-timing.json
        ↓
/generate-prompts → image-prompts.md
```

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided. If missing, ask Hai for the book slug. Set `SLUG=$ARGUMENTS`. Check that `projects/ai-book-video/books/$SLUG/` exists.

2. **Read input files**:
   - Read `projects/ai-book-video/books/$SLUG/storyboard.md` — scene plan, story arc, pacing
   - Read `projects/ai-book-video/books/$SLUG/notes.md` — book title, author, insights, angle, stories
   - Read `projects/ai-book-video/tts-config.json` — chunk params and `en_to_vn` dictionary
   - Read `projects/ai-book-video/brand/style-guide.md` — tone reference

   If storyboard.md is missing, warn and ask if Hai wants to proceed without it (using notes.md only) or run `/create-storyboard` first.

3. **Detect mode**:
   - If `chunks-display.md` exists with actual narration content → **revision** mode
   - If missing or empty → **new draft** mode

   > Read `references/writing-guide.md` — chunk-aware writing guidelines, scene structure, tone/style, revision mode procedure. Read for both new draft and revision modes.

4. **Write display chunks** (new draft): Follow the storyboard's scene plan. Write narration as numbered chunks `[NNN] "text"`. Each chunk is one natural speech unit — a complete thought that sounds right when spoken aloud.

5. **Generate TTS chunks**: For each display chunk, create its TTS-normalized version.

   > Read `references/format-rules.md` — chunk format specs, TTS normalization rules (numbers, EN terms, avoid patterns), chunk size validation, file headers. Read before writing output files.

6. **Validate TTS chunks**: Check each TTS chunk's character count (Python `len()`). Sweet spot: 75-250 chars. Flag outliers.

7. **Write both files** to `projects/ai-book-video/books/$SLUG/`

8. **Print summary**: Total chunks, total words, per-scene breakdown, normalizations applied, warnings, next step: `make voice BOOK=$SLUG`

## Output Files

**`chunks-display.md`** — Human-readable script AND subtitle source. Contains scene headings (## HOOK, ## CONTEXT...), voice config, `**[SHORT]**` markers.

**`chunks.md`** — TTS-normalized version. Same structure, headings are `## Scene 01`, normalized text. This is what viXTTS speaks.

> Read `references/format-rules.md` for exact file header templates, scene marker syntax, and numbering conventions.

## Important

- Both files have identical chunk numbering — `[001]` in display maps to `[001]` in TTS
- Scene markers and pace values identical in both files
- The display file IS the readable script — there's no separate script.md
- Vietnamese text: count chars with `len()` (Python), not byte count
- After writing, next step: `make voice BOOK=$SLUG`
