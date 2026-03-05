# AI Book Video — Production Workflow

> **Format**: Video dai (5-8 min) + 2-3 shorts
> **Platform**: YouTube, Facebook, Shorts/Reels
> **Style**: Flat illustration + Ken Burns motion
> **Voice**: AI voice clone (viXTTS self-hosted)

---

## Pipeline

> Legend: `Skill` = Claude Code skill (`/skill-name`) | `Script` = automated (`make target`) | `Manual` = requires Hải

```
[/extract-notes] -------------- Skill (Claude+MCP)
    ↓ notes.md + chosen angle
[/write-script] ←----------+-- Skill (Claude, iterative)
    |                       |
    v                       |  iterate until
[make voice] --- Script     |  voice + script
  voiceover.wav             |  are solid
  + timing.json             |
    |                       |
    v                       |
[Review voice] --- Manual --+
    |
    | (voice approved)
    |
    +---------------------------+
    |                           |
    v                           v
[/write-storyboard] -- Skill [make subtitle] --- Script
[Image Gen: Gemini] - Manual   Whisper → word timestamps → SRT
  -> scenes/                    |
    |                           |
    +---------------------------+
    v
[make scenes] --- Script
  scenes.json (from timing + images)
    ↓
[make sync] -> [make studio] -> [make render] --- Script
    ↓
[/write-metadata] ------------ Skill
    ↓
[Publish] --- Manual (YouTube + Facebook)
```

> **Voice-first**: Voice là authority. Script ↔ voice lặp cho tới khi chất lượng ổn.
> Sau khi voice approved: storyboard (informed by actual timing) + subtitle chạy song song.
> Hội tụ tại `make scenes` → `make sync`.

## Pipeline Steps

| # | Step | Type | Command | Output |
|---|------|------|---------|--------|
| 1 | Init project | Script | `make init BOOK=<slug>` | Book folder scaffold |
| 2 | Extract notes | Skill | `/extract-notes <slug>` | `notes.md` + angle |
| 3 | Write script | Skill | `/write-script <slug>` | `script.md` |
| 4 | Generate voice | Script | `make voice BOOK=<slug>` | `voiceover.wav` + `section-timing.json` |
| 5 | Review voice | Manual | Listen + iterate 3→4 | Approved voice |
| 6a | Write storyboard | Skill | `/write-storyboard <slug>` | `storyboard.md` |
| 6b | Generate images | Manual | Gemini (paste prompts) | `scenes/*.png` |
| 6c | Generate subtitles | Script | `make subtitle BOOK=<slug>` | `subtitles.srt` |
| 7 | Generate scenes.json | Script | `make scenes BOOK=<slug>` | `scenes.json` |
| 8 | Preview + Render | Script | `make studio` / `make render` | `video.mp4` |
| 9 | Write metadata | Skill | `/write-metadata <slug>` | `metadata.md` |
| 10 | Publish | Manual | YouTube Studio + Meta | Live video |

## Quick Start

```bash
# 1. [Script] Init project
make init BOOK=atomic-habits

# 2. [Skill] Extract notes + choose angle
/extract-notes atomic-habits

# 3. [Skill] Write script (iterative with review)
/write-script atomic-habits

# 4. [Script] Generate voice — [Manual] listen, tweak, repeat
make voice BOOK=atomic-habits

# 5a. [Skill] Write storyboard (informed by timing)
/write-storyboard atomic-habits
#     [Manual] Generate illustrations via Gemini -> scenes/

# 5b. [Script] Generate subtitles (Whisper word timestamps)
make subtitle BOOK=atomic-habits

# 6. [Script] Generate scenes.json (from timing + images)
make scenes BOOK=atomic-habits

# 7. [Script] Preview + Render
make studio BOOK=atomic-habits
make render BOOK=atomic-habits

# 8. [Skill] Write metadata
/write-metadata atomic-habits

# 9. [Manual] Publish to YouTube + Facebook

# Or run automated steps (voice -> subtitle -> scenes -> sync -> validate)
make all BOOK=atomic-habits
```

## Project Structure

```
books/                          # 1 book = 1 folder
  └── atomic-habits/
      ├── script.md             # narration + scene/pace markers
      ├── storyboard.md         # visual prompts per scene
      ├── notes.md              # NotebookLM extract
      ├── metadata.md           # YouTube/FB metadata
      ├── scenes/               # AI-generated scene images
      ├── audio/                # voiceover.wav (generated)
      └── output/               # subtitles.srt, section-timing.json
scripts/                        # pipeline automation
  ├── init-book.sh              # scaffold new book
  ├── generate-voice.sh         # voice-first: voiceover + actual timing
  ├── generate-subtitle.sh      # SRT timed to actual voice
  ├── generate-scenes.sh        # auto-gen scenes.json for Remotion
  ├── validate-subtitle.sh      # SRT quality checks
  ├── vixtts-server.sh          # TTS server management
  └── sync-assets.sh            # symlink to remotion/public
remotion/                       # React video renderer
brand/                          # shared branding + voice reference
templates/                      # reusable templates
```

## Script Format

Script files use scene markers for pace control:

```markdown
<!-- scene: scene-01, pace: slow -->
## HOOK (0:00 - 0:20)
Text content here...

<!-- scene: scene-02, pace: normal -->
## CONTEXT (0:20 - 1:00)
More text...
```

Pace levels (calibrated to viXTTS ~15 cps):
- `slow` (15 cps, large gaps) — dramatic hooks, reflective moments
- `normal` (15 cps, standard gaps) — standard narration
- `fast` (16 cps, tight gaps) — energetic CTA

> viXTTS speaks at ~15 cps regardless. Slow/fast effect comes from gap timing between sentences/paragraphs, not speech speed.

## viXTTS Server

```bash
# First time setup
./scripts/vixtts-server.sh setup

# Start/stop
./scripts/vixtts-server.sh start
./scripts/vixtts-server.sh stop
./scripts/vixtts-server.sh status
```

Requires: Podman + NVIDIA GPU (>=4GB VRAM)

## Makefile Targets

| Target | Description |
|--------|-------------|
| `init` | Scaffold new book project |
| `voice` | Generate voiceover + section-timing.json (authority) |
| `subtitle` | Generate SRT via Whisper word timestamps from voiceover |
| `scenes` | Auto-generate scenes.json from timing + images |
| `sync` | Symlink book assets to remotion/public |
| `validate` | Validate SRT quality |
| `studio` | Open Remotion Studio preview |
| `render` | Render final video |
| `all` | voice -> subtitle -> scenes -> sync -> validate |
| `clean` | Remove generated files |

All targets require `BOOK=<slug>` parameter.
