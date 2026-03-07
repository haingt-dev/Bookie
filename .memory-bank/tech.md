# Tech Stack

## 🛠️ Core Technologies

### AI & Content Creation
| Tool | Purpose | Type |
|------|---------|------|
| **NotebookLM** (MCP) | Book extraction, research | Cloud (MCP: `notebooklm-mcp-cli`) |
| **Claude** | Script writing, analysis, metadata | Cloud |
| **viXTTS** | AI voice clone → voiceover | Self-host (Podman, local GPU) |
| **Gemini Nano Banana 2** | Flat illustration, natural language prompts | Cloud (gemini.google.com) |
| **yt-dlp** | YouTube competitive analysis (search + metadata) | Local CLI (`yt-dlp ytsearchN:query --skip-download --print`) |

### Video Production
| Tool | Purpose | Type |
|------|---------|------|
| **Remotion** | React-based video framework | OSS, local |
| **Antigravity** | IDE + visual editor for Remotion | Local |
| **Canva** | Thumbnail design | Cloud (free tier) |
| **ffmpeg** | Audio/video processing | Local |

### Distribution
| Tool | Purpose |
|------|---------|
| YouTube Studio | Upload + schedule video |
| Meta Business Suite | Facebook video + Reels |

## 📦 Key Dependencies

### viXTTS (Self-hosted)
- **GPU**: RTX 4070 Super Ti (16GB VRAM) — dư sức
- **Runtime**: Podman container (`ghcr.io/vixtts`)
- **API**: REST API tại `localhost:8020`
- **Env var**: `VIXTTS_API_URL=http://localhost:8020`
- **Voice clone**: 10-30s reference audio (WAV)
- **Start**: `scripts/vixtts-server.sh` (manages Podman container)
- **Tested**: 30 WAV samples generated successfully (6 speakers × 5 temps)
- **Speaking rate** (benchmark 2026-03-06, 16 passages): CPS mean=17.4 (VN pure), max ~500 chars/call
- **EN limitation**: viXTTS không nói được tiếng Anh — cố đánh vần EN bằng phonetics Việt, CPS rớt ~12 (unpredictable). Giải pháp: loại bỏ EN dài, chỉ cho phép Vinglish ngắn (1-2 syllable: gym, blog, fan, team)
- **Numbers as words**: CPS=21 (consistent with VN pure) → viết số thành chữ ("ba mươi bốn" not "34")
- **Chunk optimization** (benchmark 2026-03-06, 27 passages): sweet spot 75-250 chars, 160 chars = lowest variance (std=0.24). Config: `tts-config.json`. Below 50 chars → SLOW/NOISE. Above 300 → CPS drift.
- **Chunking pipeline**: `/write-video` outputs paired `chunks-display.md` (natural VN) + `chunks.md` (TTS-normalized) → `generate-voice.sh` uses pre-split chunks (chunks.md required).
- **Script conventions**: Pure Vietnamese + Vinglish ngắn only. Xem WORKFLOW.md "Script Language Rules"
- **Script guide**: 5min≈1050w, 7min≈1470w, 10min≈2100w (pure speech, add ~10-15s for gaps)

### NotebookLM CLI (`nlm`)
- **Package**: `notebooklm-mcp-cli` v0.3.19
- **Install**: `uv tool install notebooklm-mcp-cli`
- **Binaries**: `~/.local/bin/nlm` (CLI) + `~/.local/bin/notebooklm-mcp` (MCP server)
- **Auth**: `nlm login` (mở Chrome, đăng nhập Google — 1 lần)
- **Auth check**: `nlm login --check`
- **Account**: thanhhai9x98@gmail.com
- **Credentials**: `~/.notebooklm-mcp-cli/profiles/default`
- **Chrome profile**: `~/chrome_profile_notebooklm/` (persistent session)
- **MCP integration**: Antigravity (via `nlm setup add antigravity`)
- **MCP config**: `~/.gemini/antigravity/mcp_config.json`
- **⚠️**: Chrome automation (undocumented APIs) — có thể break khi Google update UI

### Pipeline Orchestration
- **`produce.sh`**: Full pipeline orchestrator — voice → images → subtitle → scenes → sync → validate → render
  - Skip flags: `--skip-voice`, `--skip-images`, `--skip-render`
  - Usage: `make produce BOOK=<slug>` or `make produce BOOK=<slug> ARGS="--skip-voice"`
  - Prerequisites: viXTTS running, GEMINI_API_KEY set, chunks.md + image-prompts.md exist
- **`/produce-video`**: Master Claude Code skill — full pipeline from research to rendered video
  - One interaction: choose angle. Everything else automated.
  - Phases: Deep Research (NotebookLM + web) → Angle Selection → Creative Gen → Voice → Visual → Report
- **Gemini API**: `gemini-3.1-flash-image-preview` for scene image generation
  - Config: `GEMINI_API_KEY` in `.env`, `GEMINI_IMAGE_SIZE=2K`
  - Script: `generate-images.sh` (retry logic, rate limiting, base64 decode)

### Remotion
- **Version**: Latest (create-video)
- **Runtime**: Node.js 18+
- **Render**: CLI (`npx remotion render`)
- **Config**: `remotion.config.ts`

## 🖥️ Development Environment

### Required System
- **OS**: Linux
- **GPU**: NVIDIA RTX 4070 Super Ti (16GB VRAM)
- **Shell**: zsh

### Required Tools
- Node.js 18+ — Remotion
- Python 3.12 — Inline scripts (subtitle generation, voice pipeline)
- ffmpeg — Audio/video concatenation
- jq — JSON processing in scripts
- uv — Python package/tool manager (`~/.local/bin/uv`)

## 🔐 Security & Secrets

### Secrets Management
- **Method**: Environment variables + `.env` files
- **Required Secrets**:
  - `VIXTTS_API_URL` — viXTTS server URL (default: `http://localhost:8020`)
  - `GEMINI_API_KEY` — Gemini API key for image generation
  - Google account auth cookie (managed by `nlm auth` — stored locally)

### .gitignore
- `.env*`, `*.wav`, `*.mp3`, `*.mp4` (media files tracked via Git LFS)
- Voice reference files
- Output renders

## 🔄 Version Control

### Git Strategy
- **Main Branch**: `master`
- **Large Files**: Git LFS for media (video, audio, PSD, high-res images)
- **Output**: Not committed (generated, can be re-rendered)

### Commit Convention
- `feat(video): add init-video script`
- `docs: update WORKFLOW with automation details`
- `fix(voice): adjust chunk splitting for viXTTS`
