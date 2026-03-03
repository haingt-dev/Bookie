# Architecture

## 🏛️ System Overview
Pipeline-based production system cho video sách. Không phải application code — là một chuỗi tools + scripts + templates orchestrated bởi bash scripts và AI agents.

**Architecture Style**: Pipeline / Workflow automation

## 📁 Project Structure
```
projects/ai-book-video/
├── WORKFLOW.md               — Master workflow documentation
├── assets/
│   ├── brand/
│   │   ├── style-guide.md    — Visual brand guidelines
│   │   └── voice-reference/  — AI voice clone reference audio
│   ├── test-sach/
│   │   └── voice-matrix/     — Voice test samples (speakers × temperatures)
│   ├── test-expressiveness/  — Expressiveness test samples
│   └── <book-slug>/          — Per-video assets (scenes, thumbnails, audio)
├── remotion/
│   ├── public/
│   │   ├── logo.png          — Full Bookie logo (transparent)
│   │   └── logomark.png      — Bookie logomark (transparent)
│   └── src/
│       ├── compositions/     — BookVideo (16:9), BookShort (9:16)
│       ├── components/       — Scene, Subtitle, Intro, Outro, Logo
│       ├── data/scenes.json  — Per-video config (swap per video)
│       └── utils/            — SRT parser, fonts
├── scripts/
│   ├── init-video.sh         — Scaffold new video project
│   ├── generate-voice.sh     — Script → WAV (viXTTS API)
│   ├── generate-subtitle.sh  — Script → SRT (text-derived timing)
│   ├── validate-subtitle.sh  — SRT validation (timing, format)
│   ├── vixtts-server.sh      — Start/manage viXTTS Podman container
│   ├── test-voice-matrix.sh  — Generate voice matrix for evaluation
│   ├── evaluate-matrix.sh    — Interactive voice sample evaluation
│   ├── separate-layers.sh    — PNG → foreground/background layers (rembg + IOPaint)
│   ├── .venv-layers/         — Python 3.12 venv for layer pipeline (gitignored)
│   ├── content-calendar.md   — Production tracking
│   └── templates/            — Reusable templates (prompts, script, checklist)
└── output/
    └── <book-slug>/          — Final renders (MP4, SRT)
```

## 🔄 Data Flow

```
[Sách (PDF/ebook)]
    ↓
[NotebookLM MCP] → Raw notes + insights
    ↓
[Claude] → Script + Storyboard + Image prompts
    ↓
[AI Image Gen] → Scene illustrations (PNG)
    ↓
[rembg + IOPaint] → Foreground/Background layers (PNG) ← optional parallax
    ↓
[viXTTS] → Voiceover (WAV) ← script text
    ↓
[generate-subtitle.sh] → Subtitles (SRT) ← script text + audio duration
    ↓
[Remotion] → Final video (MP4) ← illustrations + voiceover + SRT
    ↓
[YouTube / Facebook] → Published content
    ↓
[Analytics] → Feedback → Phase 1 adjustments
```

## 🧩 Key Components

### NotebookLM MCP Integration
- **Location**: MCP server config (managed by `nlm setup`)
- **Purpose**: Extract book insights without leaving Antigravity
- **Dependencies**: Google account, internet
- **Used by**: Phase 1 (PICK)

### viXTTS (Self-hosted)
- **Location**: Podman container on local GPU, port 8020
- **Purpose**: AI voice cloning → Vietnamese voiceover
- **Dependencies**: RTX 4070 Super Ti, Podman, CUDA
- **Used by**: Phase 4 (BUILD) via `generate-voice.sh`
- **Management**: `scripts/vixtts-server.sh`

### Remotion Template
- **Location**: `remotion/`
- **Purpose**: Programmatic video composition + CLI rendering
- **Dependencies**: Node.js, React/TypeScript, Remotion 4.x
- **Used by**: Phase 4 (BUILD)
- **Compositions**: BookVideo (16:9), BookShort (9:16)
- **Components**: Scene (Ken Burns + parallax), Subtitle (SRT overlay), Intro, Outro, Logo, BGM (ambient audio)
- **Parallax**: Optional layered animation — foreground/background drift at different speeds + spring entry
- **Branding**: Official colors + logo PNGs in `public/`

### Automation Scripts
- **Location**: `scripts/`
- **Purpose**: Orchestrate pipeline steps, reduce manual work
- **Dependencies**: bash, ffmpeg, jq, curl

## 🔌 External Integrations
- **NotebookLM**: MCP via `notebooklm-mcp-cli` (unofficial API)
- **viXTTS**: REST API at localhost:8020 (Podman container, self-hosted)
- **AI Image Gen**: Manual via Midjourney/Leonardo web UI
- **YouTube/Facebook**: Manual upload via web UI (potential future API integration)

## 🚨 Critical Constraints
- **1-person operation**: Everything must be automatable or very fast manually
- **GPU bound**: viXTTS runs on local GPU — can't run while gaming/training
- **NotebookLM MCP instability**: Uses undocumented APIs, may break on updates
- **No CI/CD**: This is a content pipeline, not a software deployment pipeline
