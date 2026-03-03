# Current Context

> **Last Updated**: 2026-03-03
> **Updated By**: Claude Code (với Hải)

## 🎯 Current Sprint/Focus
**Goal**: Setup automated video production pipeline cho kênh Bookie
**Deadline**: Không cố định — ưu tiên chất lượng trước tốc độ
**Progress**: Feature-complete — Voice + Subtitle + Parallax layers + Remotion render pipeline ready, cần chọn sách → chạy e2e

## 🏗️ Active Workstreams
1. **AI Book Video Pipeline**
   - **Status**: In Progress
   - **Owner**: Hải
   - **Priority**: High
   - **Blockers**: Cần chọn sách đầu tiên
   - **Next Action**: Chọn sách → chạy full pipeline e2e

## 📝 Recent Changes (Last 30 Days)
- **2026-03-03** `feat`: Parallax layer pipeline — automated illustration → layered animation
  - Files: `scripts/separate-layers.sh`, `scripts/.venv-layers/`, `remotion/src/compositions/components/SceneSlide.tsx`, `remotion/src/types.ts`, `remotion/src/constants.ts`
  - Impact: rembg (BiRefNet) → foreground extraction → IOPaint (LaMa) background inpainting → Remotion parallax animation. Backward-compatible: scenes without `layers` use Ken Burns.
- **2026-03-03** `chore`: Project cleanup — remove stale test WAVs, track Remotion + new scripts, update docs
  - Impact: Git history clean. Pipeline feature-complete and committed.
- **2026-03-03** `feat`: BGM ambient audio support in Remotion template
  - Files: `remotion/src/components/BGM.tsx`, `remotion/public/bgm/`
  - Impact: Ambient background music layer, configurable per video via scenes.json
- **2026-03-03** `feat`: Subtitle styling tuned — size, positioning, readability
  - Files: `remotion/src/components/Subtitle.tsx`
  - Impact: Vietnamese subtitle rendering optimized for YouTube/Reels
- **2026-03-03** `feat`: Implement `generate-subtitle.sh` (Script text → SRT)
  - Files: `scripts/generate-subtitle.sh`
  - Impact: Subtitle pipeline complete. Text-derived timing from script markers + audio duration. Output SRT compatible with Remotion `srt.ts` parser.
- **2026-03-03** `style`: Remotion template updated with official Bookie branding
  - Files: `remotion/src/components/`, `remotion/public/logo.png`, `remotion/public/logomark.png`
  - Impact: Colors synced với brand guideline (#368C06 primary, #C86108 accent, #FAFDF5 background). Logo PNGs added to public/
- **2026-03-03** `feat`: Init Remotion template — BookVideo (16:9) + BookShort (9:16)
  - Files: `remotion/` (15 files — package.json, components, compositions, SRT parser)
  - Impact: Video render pipeline ready. scenes.json = source of truth per video. Fonts: Montserrat + Inter (Google) + Be Vietnam Pro (local TTF for subs)
- **2026-03-03** `feat`: Voice evaluation complete — 15/15 files rated
  - Files: `assets/test-sach/voice-matrix/evaluation.md`, `matrix.md`
  - Impact: fonos/temp=0.85 confirmed (avg 4.60). Best: calm (4.67), worst: heavy (3.67). excited-t085 = 5/5
- **2026-03-03** `feat`: Per-section voice config in generate-voice.sh
  - Files: `scripts/generate-voice.sh`, `WORKFLOW.md` (Phase 4a)
  - Impact: Script markers `<!-- voice: temp=X -->` cho dynamic voice tuning per section
- **2026-03-03** `feat`: Voice matrix test — 30 WAV files generated
  - Files: `scripts/test-voice-matrix.sh`, `scripts/evaluate-matrix.sh`, `assets/test-sach/voice-matrix/`
  - Impact: viXTTS server working, voice generation pipeline validated
- **2026-03-03** `feat`: Add viXTTS server scripts và expressiveness tests
  - Files: `scripts/vixtts-server.sh`, `scripts/test-expressiveness/`, `scripts/test-sach/`
  - Impact: TTS infrastructure ready, multiple voice samples available
- **2026-03-02** `feat`: Setup pipeline scripts và templates
  - Files: `scripts/init-video.sh`, `scripts/generate-voice.sh`, `scripts/templates/checklist.md`, `scripts/content-calendar.md`
  - Impact: Automation framework cho toàn bộ video production
- **2026-03-02** `docs`: Rewrite WORKFLOW.md với automation details
  - Files: `WORKFLOW.md`
  - Impact: Thêm NotebookLM MCP, viXTTS, subtitle generation, feedback loop

## 🔄 Context Carry-Forward
**For Next Session**:
- Chọn sách đầu tiên → chạy full pipeline e2e (script → voice → subtitle → render)
- Tạo scene illustrations (Midjourney/Leonardo) cho video đầu tiên
- Test full Remotion render với real content

## ⚠️ Known Issues & Workarounds
- **Issue**: NotebookLM CLI (`nlm`) dùng internal APIs — có thể thay đổi không báo trước
  - **Workaround**: Fallback: dùng NotebookLM web UI nếu CLI lỗi
- **Issue**: viXTTS Podman container cần start thủ công mỗi session
  - **Workaround**: Dùng `scripts/vixtts-server.sh` để start/manage container

## 📂 Key Files & Locations
- `WORKFLOW.md` — Master workflow document
- `scripts/init-video.sh` — Tạo folder structure cho video mới
- `scripts/generate-voice.sh` — Script → WAV bằng viXTTS API
- `scripts/vixtts-server.sh` — Start/manage viXTTS Podman container
- `scripts/test-voice-matrix.sh` — Generate voice matrix (speakers × temperatures)
- `scripts/evaluate-matrix.sh` — Interactive voice evaluation script
- `scripts/generate-subtitle.sh` — Script → SRT (text-derived timing)
- `scripts/validate-subtitle.sh` — SRT format validation
- `scripts/separate-layers.sh` — PNG → foreground/background layers (parallax)
- `scripts/.venv-layers/` — Python 3.12 venv (rembg, IOPaint, torch)
- `scripts/templates/` — Claude prompts, script template, image prompts, checklist
- `scripts/content-calendar.md` — Tracking sản xuất và metrics
- `assets/brand/voice-reference/` — Voice reference audio cho viXTTS
- `assets/brand/style-guide.md` — Visual style guide
- `remotion/` — Remotion video template (BookVideo + BookShort)
- `remotion/src/data/scenes.json` — Per-video config (swap per video)
