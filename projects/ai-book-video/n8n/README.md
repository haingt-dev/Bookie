# n8n Orchestration Layer — Bookie AI Book Video

n8n-based orchestration for the Bookie AI book video pipeline. Provides a web UI alternative to the CLI pipeline (`make` targets + Claude Code skills), with form-based inputs and visual workflow management.

## Prerequisites

- **Docker** or **Podman** (with `podman-compose`)
- **Anthropic API key** (Claude, for script writing and creative steps)
- **Gemini API key** (for image generation)
- **Python 3** on the host (for the host bridge)
- Host tools: `ffmpeg`, `make`, GPU access (for voice/render steps)

## Quick Start

```bash
cd projects/ai-book-video/n8n

# 1. Configure API keys
cp .env.example .env
# Edit .env — fill in ANTHROPIC_API_KEY and GEMINI_API_KEY

# 2. Start n8n
docker compose up -d
# or: podman-compose up -d

# 3. Wait for n8n to start, then open the UI
#    http://localhost:5678

# 4. Set up owner account (first time only)
#    Follow the on-screen setup wizard

# 5. Start the host bridge (separate terminal)
./host-bridge/bridge.sh

# 6. Import workflows
#    In n8n UI: Settings → Import → point to workflows/*.json
#    Import all 9 workflow files (01 through 09)
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Browser — n8n UI (localhost:5678)               │
│  Form inputs, workflow editor, execution logs    │
└──────────────┬──────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────┐
│  n8n Container (Docker, network_mode: host)      │
│  - Workflow orchestration                        │
│  - LLM calls → Anthropic API (HTTP Request)      │
│  - Prompt templates (mounted from ./prompts/)    │
│  - Data processing, form handling                │
└──────────────┬──────────────────────────────────┘
               │ HTTP (localhost:3456)
┌──────────────▼──────────────────────────────────┐
│  Host Bridge (bridge.sh)                         │
│  - Script execution (make voice, make render...) │
│  - File I/O (read/write project files)           │
│  - Access to GPU, ffmpeg, python3, viXTTS        │
└─────────────────────────────────────────────────┘
```

**Key design decisions:**

- **n8n runs in Docker** using the official `n8nio/n8n` image. Container uses `network_mode: host` for direct access to host services.
- **All script execution goes through the host bridge** (`localhost:3456`). The n8n container is sandboxed and can't access host tools (python3, ffmpeg, GPU) directly.
- **LLM calls go directly to Anthropic API** via HTTP Request nodes in n8n — no bridge needed for API calls.
- **File I/O also goes through the host bridge** for operations outside mounted volumes.
- **Prompts are mounted read-only** from `./prompts/` into the container at `/data/prompts/`.

## Workflows

| # | Workflow | Description |
|---|----------|-------------|
| 00 | Sheet Orchestrator | Google Sheets control panel — auto-runs pipeline from sheet |
| 01 | Pipeline Dashboard | Form-based status check and step launcher |
| 02 | Book Research | Deep-research a book via Claude, extract notes and angles |
| 03 | Storyboard Creation | Plan story direction, scenes, narrative arc, pacing |
| 04 | Script Writing | Write video script as paired TTS-ready chunks |
| 05 | Voice Production | Generate voiceover via host bridge (`make voice`) |
| 06 | Visuals Production | Generate image prompts + scene images (`make images`) |
| 07 | Assembly & Render | Build scenes.json, sync assets, render video (`make render`) |
| 08 | Post-production | Generate metadata, subtitles, catalog insights |
| 09 | Status Dashboard | View pipeline status for all books |

All creative workflows (02-04, 08) use form triggers — submit inputs via the n8n form UI. Production workflows (05-07) call make targets through the host bridge.

### Google Sheets Control Panel (00 — Sheet Orchestrator)

Manage the pipeline from a Google Sheet instead of the n8n UI:

1. Set up Google Sheets OAuth2 credential in n8n (Settings → Credentials)
2. Open workflow 00, connect credential to all Google Sheets nodes
3. Activate (Publish) the workflow
4. Add a row: `book_slug = my-book`, `status = ▶ Start`
5. Orchestrator polls every 1 minute, auto-runs production phases, pauses for LLM phases

Sheet columns: `book_slug | status | phase | progress | angle_choice | notes | error`

## Host Bridge

The bridge is a lightweight Python HTTP server that runs on the host machine, exposing project commands to n8n over `localhost:3456`.

```bash
# Start with defaults (port 3456, auto-detect project dir)
./host-bridge/bridge.sh

# Custom port
./host-bridge/bridge.sh --port 4000

# Custom project directory
./host-bridge/bridge.sh --project-dir /path/to/ai-book-video
```

**Supported commands:**

| Command | Description |
|---------|-------------|
| `voice`, `render`, `images`, `subtitle`, `scenes`, `sync`, `validate`, `init`, `render-shorts`, `studio` | Make targets (require `book` field) |
| `status` | Make target (no book needed) |
| `read-file`, `write-file` | File I/O (path relative to project dir, sandboxed) |
| `scan-books` | List all books and their artifact status |
| `vixtts-health` | Check viXTTS server status |
| `shell` | Raw shell command (use with caution) |

**Security note:** The bridge has no authentication and no TLS. It is designed for **local development only** — do not expose it to the network.

## Troubleshooting

**"Connection refused" when workflow runs a host command**
The host bridge is not running. Start it: `./host-bridge/bridge.sh`

**IPv6 / "Address already in use" issues**
The bridge uses dual-stack (IPv4 + IPv6) by default. If IPv6 fails, it falls back to IPv4 automatically. If port 3456 is taken, use `--port <other>` and update the HTTP Request URLs in your workflows.

**Workflow won't activate / "Activate" button is grayed out**
Form-trigger workflows don't need activation. They respond to form submissions — just open the form URL from the workflow editor.

**n8n UI login**
Default credentials set during first-time setup. If you used the standard setup: `hai@bookie.dev` / `Bookie123!`

**Workflow import fails**
Import workflows one at a time from `workflows/*.json`. Ensure you're on a recent n8n version (the workflows use HTTP Request nodes and form triggers).

**viXTTS not responding**
The voice workflow calls viXTTS through the host bridge. Make sure the viXTTS server is running: `./scripts/vixtts-server.sh start` (from the `ai-book-video` project root).
