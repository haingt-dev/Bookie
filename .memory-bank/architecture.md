# Architecture

## System Overview
Pipeline-based production system cho video sách. Không phải application code — là một chuỗi tools + scripts + templates orchestrated bởi Makefile và bash scripts.

**Architecture Style**: Pipeline / Workflow automation

## Project Structure
```
projects/ai-book-video/
├── Makefile                    — Pipeline orchestration
├── WORKFLOW.md                 — Master workflow documentation
├── .env.example                — Environment template
├── content-calendar.md         — Production tracking
├── books/                      — 1 book = 1 folder (source of truth)
│   └── atomic-habits/
│       ├── script.md           — Narration + scene/pace markers
│       ├── storyboard.md       — Visual prompts per scene
│       ├── notes.md            — NotebookLM extract
│       ├── metadata.md         — YouTube/FB metadata
│       ├── prompts.md          — Claude prompts used
│       ├── scenes/             — AI-generated illustrations (PNG)
│       ├── audio/              — voiceover.wav (generated)
│       └── output/             — subtitles.srt, section-timing.json
├── scripts/                    — Pipeline automation
│   ├── init-book.sh            — Scaffold new book project
│   ├── generate-subtitle.sh    — Script → SRT (pace-aware)
│   ├── generate-voice.sh       — SRT → Voice (per-scene, time-matched)
│   ├── validate-subtitle.sh    — SRT quality checks
│   ├── vixtts-server.sh        — TTS server management
│   └── sync-assets.sh          — Symlink books/ → remotion/public/
├── templates/                  — Reusable templates
├── brand/                      — Voice reference + style guide
└── remotion/                   — React video renderer
    ├── src/                    — Compositions, components, types, utils
    ├── public/                 — Symlinks populated by sync-assets.sh
    └── package.json
```

## Data Flow (SRT-First Pipeline)

```
[Sách (PDF/ebook)]
    ↓
[NotebookLM] → Raw notes + insights
    ↓
[Claude] → Script (script.md) + Storyboard + Image prompts
    ↓
[AI Image Gen] → Scene illustrations (PNG) → books/<slug>/scenes/
    ↓
[make subtitle] → SRT + section-timing.json (pace authority)
    ↓
[make voice] → voiceover.wav (per-scene, stretched to match SRT)
    ↓
[make sync] → symlinks to remotion/public/
    ↓
[make studio/render] → preview / video.mp4
    ↓
[YouTube / Facebook] → Published content
```

**Key principle**: Natural voice is the authority. Gap adjustment (silence between sentences/paragraphs) absorbs timing deltas. SRT auto-syncs to match actual audio duration. No audio stretching — voice stays natural.

## Key Components

### Makefile Orchestration
- **Location**: `Makefile`
- **Targets**: init, subtitle, voice, sync, validate, studio, render, all, clean
- **Usage**: `make <target> BOOK=<slug>`

### viXTTS (Self-hosted)
- **Location**: Podman container on local GPU, port 8020
- **Purpose**: AI voice cloning → Vietnamese voiceover
- **Dependencies**: NVIDIA GPU (>=4GB VRAM), Podman, CUDA
- **Config**: fonos speaker, temp=0.85, repetition_penalty=2.0
- **Management**: `scripts/vixtts-server.sh`

### Remotion Template
- **Location**: `remotion/`
- **Purpose**: Programmatic video composition + CLI rendering
- **Dependencies**: Node.js, React/TypeScript, Remotion 4.x
- **Compositions**: BookVideo (16:9, 1920x1080, 30fps), BookShort (9:16)
- **Components**: SceneSlide (Ken Burns + cross-dissolve), Subtitle (SRT overlay + fade), Intro, Outro, Logo, BGM
- **Branding**: #368C06 primary, #C86108 accent, #FAFDF5 background

### Script Format
- Scene markers: `<!-- scene: scene-01, pace: slow -->`
- Pace presets: slow (12 cps), normal (15 cps), fast (17 cps)
- Voice config: `<!-- voice: temp=X, repetition_penalty=Y -->`

## External Integrations
- **NotebookLM**: MCP via `notebooklm-mcp-cli` (unofficial API)
- **viXTTS**: REST API at localhost:8020 (Podman container)
- **AI Image Gen**: Manual via Midjourney/Leonardo web UI
- **YouTube/Facebook**: Manual upload

## Critical Constraints
- **1-person operation**: Everything must be automatable or very fast manually
- **GPU bound**: viXTTS runs on local GPU — can't run while gaming/training
- **No CI/CD**: Content pipeline, not software deployment
