# Current Context

> **Last Updated**: 2026-03-05
> **Updated By**: Claude Code (với Hải)

## Current Sprint/Focus
**Goal**: Sản xuất video đầu tiên (Atomic Habits) cho kênh Bookie
**Deadline**: Không cố định — ưu tiên chất lượng trước tốc độ
**Progress**: Pipeline restructured và production-ready. Cần viết lại script Atomic Habits + chạy full e2e.

## Active Workstreams
1. **AI Book Video Pipeline**
   - **Status**: Ready for production
   - **Owner**: Hải
   - **Priority**: High
   - **Next Action**: Viết lại script Atomic Habits → chạy `make all BOOK=atomic-habits`

## Recent Changes (Last 30 Days)
- **2026-03-05** `refactor`: Major project restructure — unified `books/` layout + Makefile pipeline
  - Consolidated `scripts/<slug>/` + `assets/<slug>/` + `output/<slug>/` → `books/<slug>/`
  - Added: Makefile, sync-assets.sh (symlinks), .env.example, .gitignore
  - Removed: parallax pipeline (separate-layers.sh, .venv-layers 7.4GB), test projects, voice matrix artifacts
  - Updated scripts: smart subtitle = default, match-srt voice = default, --draft removed
  - Renamed init-video.sh → init-book.sh
  - Branch: `restructure/clean-pipeline`
- **2026-03-03** `feat`: SRT-first pipeline — subtitle timing drives voice generation
  - generate-subtitle.sh --smart: script markers → pace-aware SRT
  - generate-voice.sh --match-srt: per-scene voice → stretch to match SRT timing
  - 13 scenes, 7m29s output, stretch ratios 0.68x-1.09x
- **2026-03-03** `feat`: Remotion visual improvements — Ken Burns + cross-dissolve + subtitle fade
- **2026-03-03** `feat`: Voice evaluation — fonos/temp=0.85 confirmed best (avg 4.60/5)
- **2026-03-03** `feat`: Full pipeline infrastructure (viXTTS, Remotion, scripts)

## Context Carry-Forward
**For Next Session**:
- Merge `restructure/clean-pipeline` → master khi sẵn sàng
- Viết lại script Atomic Habits (script.md) — tối ưu cho 7-8 phút
- Chạy full pipeline: `make all BOOK=atomic-habits` → `make studio`
- Tạo scene illustrations mới (nếu cần) theo storyboard.md

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
