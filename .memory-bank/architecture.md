# Architecture

Pipeline-based production system cho video sách. Tools + scripts + templates orchestrated bởi Makefile và bash scripts. Không phải application code.

## Pipeline — Full Auto

```
/produce-video <slug>
    ↓
[Phase 1: Deep Research] ── NotebookLM + WebSearch + yt-dlp
    ↓ notes.md + 3-4 angle options
[Phase 2: Choose Angle] ── ONLY user interaction
    ↓
[Phase 3: Creative Gen] ── storyboard.md + chunks + metadata.md
    ↓
[Phase 4: Voice] ── make voice → voiceover.wav + section-timing.json
    ↓
[Phase 5: Visual] ── image-prompts.md → produce.sh --skip-voice
    ↓                  (images → subtitle → scenes → sync → render)
[Phase 6: Report] ── video.mp4 path, duration, file size
    ↓
[Phase 6.5: Catalog] ── concepts → knowledge-base/, source → Master notebook
    ↓
[Phase 7: Content Factory] ── NotebookLM → podcast, debate, briefing audio
```

## Pipeline — Granular

```
/extract-notes → /create-storyboard → /write-video → make voice
    → /generate-prompts → make produce ARGS="--skip-voice"
    → /write-metadata → /catalog-insights → publish
```

## Key Principles

- **Story-first**: Narrative quality first. No timing prediction — voice determines duration.
- **Voice is authority**: `section-timing.json` (from actual TTS) is the only timing source.
- **Paired chunks**: `chunks-display.md` (natural VN, subtitles) + `chunks.md` (TTS-normalized). Same `[NNN]` numbering.

## Constraints

- 1-person operation — everything automatable
- GPU-bound — viXTTS on local GPU (can't run while gaming/training)
- No CI/CD — content pipeline, not software deployment
