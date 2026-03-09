# Tech Stack

## Core Tools

- **NotebookLM** (MCP) — book research hub
- **Claude** — script writing, analysis, metadata
- **viXTTS** — AI voice clone (self-host, Podman, local GPU)
- **Gemini** (`gemini-3.1-flash-image-preview`) — scene image generation
- **Remotion** — React-based video render (Node.js 18+)
- **yt-dlp** — YouTube competitive analysis
- **ffmpeg** — audio/video processing

## viXTTS Runtime

- API: `localhost:8020` (Podman container, RTX 4070 Super Ti)
- Config: fonos speaker, temp=0.85, repetition_penalty=2.0
- Pure Vietnamese only — EN words spelled phonetically (CPS drops ~12). Short Vinglish OK (1-2 syllable).
- Chunk sweet spot: 75-250 chars, 160 optimal. Below 50 → noise. Above 300 → drift.
- Numbers as words: "ba mươi bốn" not "34"
- Script guide: 5min ≈ 1050w, 7min ≈ 1470w, 10min ≈ 2100w

## NotebookLM CLI

- Package: `notebooklm-mcp-cli` — auth: `nlm login`
- Chrome automation (undocumented APIs) — may break on Google UI updates

## Secrets

- `VIXTTS_API_URL`, `GEMINI_API_KEY` — in `.env`
- Google auth — managed by `nlm login` (local cookie)
