# AI Book Video Pipeline

> **Status: Paused** (since 2026-07-11). The n8n stack is not deployed; the pipeline is not in regular use. 3 videos shipped. Code and docs kept intact for easy revival.
>
> To revive:
> 1. `cd n8n && docker compose up -d`
> 2. Re-authenticate Google OAuth (Sheets credential)
> 3. Restart host bridge (`./host-bridge/bridge.sh`)
>
> Note: the CLI path (`make` + Claude Code skills) needs no revival — it never depended on n8n.

Automated pipeline that turns books into narrated video content for the community. See the [root README](../../README.md) for org context and how this fits into Bookie's other resources.

## Pipeline

Each book goes through a 7-phase production flow:

1. **Research** — Extract key ideas, angles, and narrative structure from the source book
2. **Storyboard** — Break the narrative into visual sections with scene descriptions
3. **Script** — Write the Vietnamese narration script with timing markers
4. **Voice** — Generate Vietnamese voiceover using viXTTS (self-hosted TTS)
5. **Visuals** — Generate scene images via Google Gemini API, sync to script timing
6. **Assembly** — Compose final video in Remotion with subtitles, BGM, and visual overlays
7. **Post-production** — Generate YouTube/Facebook metadata, catalog insights

### Three Ways to Run

| Interface | For | Entry Point |
|-----------|-----|-------------|
| **CLI** | Power users | `make produce BOOK=<slug>` + Claude Code skills |
| **n8n Web UI** | Visual workflow | Form-based triggers at `localhost:5678` (requires revival — see Status) |
| **Google Sheets** | Non-technical users | Add row → pipeline auto-runs (requires revival — see Status) |

## Tech Stack

| Tool | Purpose |
|------|---------|
| Remotion 4.0 | React-based video renderer (composition, subtitles, overlays) |
| viXTTS | Vietnamese text-to-speech, self-hosted |
| Google Gemini API | Scene image generation |
| Claude API | Script writing, storyboard, research, metadata |
| n8n | Workflow orchestration (Docker, 10 workflows) |
| Google Sheets | Pipeline control panel (Sheet Orchestrator) |
| Make + bash | Pipeline automation |
| Host bridge | HTTP relay for n8n → host command execution |
| Git LFS | Media file storage (voiceovers, rendered videos) |

## Project Structure

```
projects/ai-book-video/
├── Makefile              # CLI pipeline entry point
├── WORKFLOW.md           # Full pipeline documentation
├── books/                # Per-book data (notes, scripts, audio, video)
├── scripts/              # Shell scripts (voice, images, render, etc.)
├── remotion/             # React video renderer
├── knowledge-base/       # Cross-book intelligence vault
├── brand/                # Style guide, voice reference
├── templates/            # Narrative templates
└── n8n/                  # n8n orchestration layer
    ├── docker-compose.yml
    ├── workflows/        # 10 workflow JSONs (importable)
    ├── prompts/          # LLM prompts extracted from skills
    ├── host-bridge/      # HTTP server for host command execution
    └── README.md         # n8n setup guide
```

## Quick Start

### CLI Pipeline

```bash
# Production pipeline (voice → images → subtitles → render)
make produce BOOK=atomic-habits

# Or step by step with Claude Code skills
/extract-notes atomic-habits     # Research + angles
/create-storyboard atomic-habits # Story direction
/write-video atomic-habits       # Script as TTS chunks
make voice BOOK=atomic-habits    # Generate voiceover
make render BOOK=atomic-habits   # Render video
```

### n8n Pipeline

```bash
cd projects/ai-book-video/n8n
cp .env.example .env             # Fill in API keys
docker compose up -d             # Start n8n
./init.sh                        # Auto-create owner account
./host-bridge/bridge.sh &        # Start command bridge
# Open http://localhost:5678
```

### Google Sheets Pipeline

1. Set up n8n (above) + Google Sheets OAuth2 credential
2. Activate workflow "00 — Sheet Orchestrator"
3. Add book row with `status = ▶ Start` → auto-runs

## Produced Videos

| # | Book | Slug |
|---|------|------|
| 1 | Atomic Habits — James Clear | `atomic-habits` |
| 2 | Gia Dinh — Hector Malot | `gia-dinh-hector-malot` |
| 3 | Sa Mon Khong Hai | `sa-mon-khong-hai` |

## Roadmap

> "Next" items are on hold while the pipeline is paused.

### Done
- [x] **CLI pipeline** — Makefile + bash scripts + Claude Code skills for full book-to-video production
- [x] **Remotion video renderer** — React compositions, Ken Burns motion, subtitles, BGM, brand overlays
- [x] **viXTTS voice synthesis** — Self-hosted Vietnamese TTS with pace-aware gaps, benchmarked CPS
- [x] **Knowledge Vault** — Cross-book intelligence (concepts, authors, connections, contradictions)
- [x] **n8n orchestration** — 10 workflows (Docker), host bridge for command execution, form-based UI
- [x] **Google Sheets control panel** — Sheet Orchestrator polls every 1min, auto-runs production phases
- [x] **LLM prompt extraction** — 6 Claude Code skills converted to standalone prompts for n8n AI Agent

### Next
- [ ] **NotebookLM as content store** — Move scripts, research, chunks from local files to NotebookLM. Single source of truth, collaborative access.
- [ ] **Interactive Sheet UX** — Angle selection via dropdown, script review inline, video preview, one-click YouTube publish. Full pipeline from Sheets alone.
- [ ] **Sheet visual polish** — Conditional formatting, progress bars, color-coded phases, branded header.
- [ ] **LLM quality tuning** — Compare n8n AI Agent output vs Claude Code skill output, iterate prompts.
- [ ] **Error handling & notifications** — Error Trigger nodes, Discord/Telegram alerts on failure.

## Git LFS

This repo uses Git LFS for media files (~355MB across 9 tracked files — voiceover WAVs, rendered videos, reference audio). Free GitHub LFS has 1GB/month bandwidth. Run `git lfs install` before cloning.
