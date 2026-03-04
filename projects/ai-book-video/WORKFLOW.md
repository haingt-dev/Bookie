# AI Book Video — Production Workflow

> **Format**: Video dai (5-8 min) + 2-3 shorts
> **Platform**: YouTube, Facebook, Shorts/Reels
> **Style**: Flat illustration + Ken Burns motion
> **Voice**: AI voice clone (viXTTS self-hosted)

---

## Pipeline

```
Script (script.md + scene markers)
    |
    v
[make subtitle] -> SRT + section-timing.json (pace-aware)
    |
    v
[make voice] -> voiceover.wav (per-scene, speed-matched to SRT)
    |
    v
[make sync] -> symlinks to remotion/public/
    |
    v
[make studio] -> preview in Remotion Studio
    |
    v
[make render] -> video.mp4
```

## Quick Start

```bash
# 1. Init project
make init BOOK=atomic-habits

# 2. (Manual) Write script + storyboard
#    -> books/<slug>/notes.md, script.md, storyboard.md

# 3. (Manual) Generate illustrations from storyboard prompts
#    -> books/<slug>/scenes/

# 4. Generate subtitles (SRT-first, pace-aware)
make subtitle BOOK=atomic-habits

# 5. Generate voiceover (matches SRT timing)
make voice BOOK=atomic-habits

# 6. Preview
make studio BOOK=atomic-habits

# 7. Render
make render BOOK=atomic-habits

# Or run full pipeline (subtitle -> voice -> sync -> validate)
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
      ├── prompts.md            # Claude prompts
      ├── scenes/               # AI-generated scene images
      ├── audio/                # voiceover.wav (generated)
      └── output/               # subtitles.srt, section-timing.json
scripts/                        # pipeline automation
  ├── init-book.sh              # scaffold new book
  ├── generate-subtitle.sh      # script.md -> SRT (pace-aware)
  ├── generate-voice.sh         # SRT-matched voice generation
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

Pace levels:
- `slow` (12 chars/sec) — dramatic hooks, reflective moments
- `normal` (15 chars/sec) — standard narration
- `fast` (17 chars/sec) — energetic CTA

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
| `subtitle` | Generate pace-aware SRT from script |
| `voice` | Generate voiceover matched to SRT timing |
| `sync` | Symlink book assets to remotion/public |
| `validate` | Validate SRT quality |
| `studio` | Open Remotion Studio preview |
| `render` | Render final video |
| `all` | subtitle -> voice -> sync -> validate |
| `clean` | Remove generated files |

All targets require `BOOK=<slug>` parameter.
