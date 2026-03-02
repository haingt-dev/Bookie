# Current Context

> **Last Updated**: 2026-03-03
> **Updated By**: Claude Code (với Hải)

## 🎯 Current Sprint/Focus
**Goal**: Setup automated video production pipeline cho kênh Bookie
**Deadline**: Không cố định — ưu tiên chất lượng trước tốc độ
**Progress**: 75% — Voice generation working, evaluate script ready, cần chọn voice + init Remotion

## 🏗️ Active Workstreams
1. **AI Book Video Pipeline**
   - **Status**: In Progress
   - **Owner**: Hải
   - **Priority**: High
   - **Blockers**:
     - Remotion template chưa init
   - **Next Action**: Evaluate 30 WAV samples → chọn speaker/temperature → init Remotion template

## 📝 Recent Changes (Last 30 Days)
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
  - Impact: Thêm NotebookLM MCP, Fish Speech, PhoWhisper, feedback loop

## 🔄 Context Carry-Forward
**From This Session (2026-03-03)**:
- viXTTS server running via Podman container on port 8020
- Voice matrix: 30 WAV files (6 speakers × 5 temperatures) generated thành công
- `evaluate-matrix.sh` — interactive script để nghe + đánh giá từng sample
- Reference audio đã record và đặt trong `assets/brand/voice-reference/`

**For Next Session**:
- Chạy `evaluate-matrix.sh` để chọn best speaker + temperature combo
- Init Remotion template project
- Chọn sách đầu tiên và chạy thử end-to-end

## ⚠️ Known Issues & Workarounds
- **Issue**: NotebookLM MCP dùng internal APIs — có thể thay đổi không báo trước
  - **Workaround**: Fallback: dùng NotebookLM web UI nếu MCP lỗi
- **Issue**: viXTTS Podman container cần start thủ công mỗi session
  - **Workaround**: Dùng `scripts/vixtts-server.sh` để start/manage container

## 📂 Key Files & Locations
- `WORKFLOW.md` — Master workflow document
- `scripts/init-video.sh` — Tạo folder structure cho video mới
- `scripts/generate-voice.sh` — Script → WAV bằng viXTTS API
- `scripts/vixtts-server.sh` — Start/manage viXTTS Podman container
- `scripts/test-voice-matrix.sh` — Generate voice matrix (speakers × temperatures)
- `scripts/evaluate-matrix.sh` — Interactive voice evaluation script
- `scripts/templates/` — Claude prompts, script template, image prompts, checklist
- `scripts/content-calendar.md` — Tracking sản xuất và metrics
- `assets/brand/voice-reference/` — Voice reference audio cho viXTTS
- `assets/brand/style-guide.md` — Visual style guide
