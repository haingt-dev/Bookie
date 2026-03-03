# Tech Stack

## 🛠️ Core Technologies

### AI & Content Creation
| Tool | Purpose | Type |
|------|---------|------|
| **NotebookLM** (MCP) | Book extraction, research | Cloud (MCP: `notebooklm-mcp-cli`) |
| **Claude** | Script writing, analysis, metadata | Cloud |
| **viXTTS** | AI voice clone → voiceover | Self-host (Podman, local GPU) |
| **generate-subtitle.sh** | Script text → SRT (text-derived timing) | Local script |
| **Midjourney/Leonardo AI** | Flat illustration generation | Cloud |
| **rembg** (BiRefNet) | Foreground/background separation | Self-host (GPU) |
| **IOPaint** (LaMa) | Background inpainting after fg removal | Self-host (GPU) |

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

### rembg + IOPaint (Layer Separation)
- **Venv**: `scripts/.venv-layers/` (Python 3.12, managed by `uv`)
- **rembg model**: `birefnet-general` (default), `isnet-anime` (alt for anime/flat art)
- **IOPaint model**: `lama` (LaMa — Fast Fourier Convolution inpainting)
- **VRAM**: ~3.5GB (rembg) + ~2GB (LaMa) = ~5.5GB total
- **Script**: `scripts/separate-layers.sh <book-slug>`
- **Setup**: `uv venv --python 3.12 scripts/.venv-layers && source scripts/.venv-layers/bin/activate && uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu126 && uv pip install "rembg[cli,gpu]" iopaint`

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
- Python 3.12 — Layer pipeline (rembg, IOPaint) via `uv venv`
- ffmpeg — Audio/video concatenation
- jq — JSON processing in scripts
- uv — Python package/tool manager (`~/.local/bin/uv`)

## 🔐 Security & Secrets

### Secrets Management
- **Method**: Environment variables + `.env` files
- **Required Secrets**:
  - `VIXTTS_API_URL` — viXTTS server URL (default: `http://localhost:8020`)
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
