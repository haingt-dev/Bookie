# Current Context

> **Last Updated**: 2026-03-05
> **Updated By**: Claude Code (với Hải)

## Current Sprint/Focus
**Goal**: Sản xuất video đầu tiên (Atomic Habits) cho kênh Bookie
**Deadline**: Không cố định — ưu tiên chất lượng trước tốc độ
**Progress**: Script/storyboard/metadata hoàn thành (contrarian angle). Old assets cleaned. Ready for production run.

## Active Workstreams
1. **AI Book Video Pipeline**
   - **Status**: Content ready, awaiting production run
   - **Owner**: Hải
   - **Priority**: High
   - **Next Action**: Generate scene images → `make all BOOK=atomic-habits`

## Recent Changes (Last 30 Days)
- **2026-03-05** `feat`: Rewrite Atomic Habits — contrarian angle "Điều mà Atomic Habits không nói với bạn"
  - New script: 913 words, 9 scenes, 3 blind spots + positive trade-off
  - New storyboard: all flat/Ken Burns (no parallax), Bookie style prefix
  - New metadata: YouTube + Facebook + 3 Shorts
  - Research: NotebookLM + 7 criticism sources
- **2026-03-05** `feat`: Gap adjustment pipeline (generate-voice.sh)
  - Replaces atempo stretch with variable silence gaps
  - Natural voice is authority, SRT auto-syncs to actual duration
  - GAP_SENTENCE 0.05-0.40s, GAP_PARAGRAPH 0.15-1.00s
- **2026-03-05** `chore`: Cleanup old assets
  - Removed: 13 old scene PNGs, voiceover.wav, subtitles.srt, section-timing.json
  - Removed: Remotion symlinks, test renders, fish-speech-server Podman image (11.4 GB)
- **2026-03-05** `refactor`: Major project restructure — unified `books/` layout + Makefile pipeline
  - Branch: `restructure/clean-pipeline`
- **2026-03-03** `feat`: Full pipeline infrastructure (viXTTS, Remotion, scripts)

## Context Carry-Forward
**For Next Session**:
- Generate 9 scene illustrations theo storyboard.md prompts
- Chạy full pipeline: `make all BOOK=atomic-habits` → `make studio`
- Review voice output quality + gap adjustment deltas

## Known Issues & Workarounds
- **Issue**: viXTTS Podman container cần start thủ công mỗi session
  - **Workaround**: `./scripts/vixtts-server.sh start`
- **Issue**: NotebookLM CLI (`nlm`) dùng internal APIs — có thể break
  - **Workaround**: Dùng NotebookLM web UI nếu CLI lỗi
- **Issue**: Pre-existing TS error `Root.tsx:47` BookShort Composition typing
  - **Workaround**: Cosmetic only, doesn't affect render

## Key Files & Locations
- `WORKFLOW.md` — Pipeline docs + Makefile usage
- `Makefile` — `make subtitle/voice/sync/validate/studio/render BOOK=<slug>`
- `books/atomic-habits/` — Script, scenes, audio, output (single source of truth)
- `scripts/generate-subtitle.sh` — Script → SRT (smart mode default)
- `scripts/generate-voice.sh` — SRT → Voice (match-srt mode default)
- `scripts/sync-assets.sh` — Symlink books/ → remotion/public/
- `scripts/init-book.sh` — Scaffold new book project
- `scripts/vixtts-server.sh` — Manage viXTTS container
- `brand/` — Style guide + voice reference
- `templates/` — Script/prompt/checklist templates
- `remotion/src/data/scenes.json` — Per-video config
