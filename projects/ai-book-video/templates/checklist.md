# Production Checklist: [Tên Sách]

> Copy file này ra `scripts/<book-slug>/checklist.md` cho mỗi video.
> Đánh dấu [x] khi hoàn thành.

## Phase 1: PICK — Chọn sách & Extract
- [ ] Upload sách lên NotebookLM (hoặc dùng MCP: `nlm source add`)
- [ ] Extract key insights (3-5 ý chính)
- [ ] Tìm quotes đắt giá
- [ ] Tìm câu chuyện / ví dụ hay
- [ ] Competitive analysis: check YouTube VN đã có video nào về sách này
- [ ] Chọn angle → ghi vào notes.md
- [ ] ✅ Output: `notes.md` hoàn chỉnh

## Phase 2: COOK — Viết Script
- [ ] Viết script draft (Claude Prompt 2)
- [ ] Word count check: 900-1050 từ (target 7 phút)
- [ ] Đọc to 1 lần — check flow tự nhiên
- [ ] Đánh dấu [SHORT] cho đoạn cắt shorts (2-3 đoạn)
- [ ] Viết storyboard + image prompts (gộp trong storyboard.md)
- [ ] ✅ Output: `script.md` + `storyboard.md` hoàn chỉnh

## Phase 3: VISUAL — Dựng Illustration
- [ ] Generate illustrations cho tất cả scenes
- [ ] Quality check:
  - [ ] Cùng color palette xuyên suốt
  - [ ] Cùng character design (nếu có)
  - [ ] Không có text trong hình
  - [ ] Aspect ratio đúng (16:9)
- [ ] Đặt tên: `scene-01-[description].png`, `scene-02-...`
- [ ] Tạo thumbnail (Canva template)
- [ ] ✅ Output: `assets/<slug>/scenes/` + `thumbnail/`

## Phase 4: BUILD — Dựng Video
- [ ] Generate voiceover: `./scripts/generate-voice.sh <slug>`
- [ ] Review voiceover — phát âm, nhịp, ngữ điệu OK
- [ ] Generate subtitle: `./scripts/generate-subtitle.sh <slug>`
- [ ] Review subtitle — fix tên riêng, thuật ngữ
- [ ] Dựng video trong Remotion / editor
- [ ] Thêm nhạc nền (volume ~15-20%)
- [ ] Intro (3-5s) + Outro (5-10s)
- [ ] Render video dài
- [ ] Cắt + render shorts (2-3 clips)
- [ ] ✅ Output: `output/<slug>/video.mp4` + shorts

## Phase 5: SHIP — Đăng & Phân phối
- [ ] Viết metadata (Claude Prompt 4): title, description, tags
- [ ] Final review checklist:
  - [ ] Subtitle không sai tên riêng / thuật ngữ
  - [ ] Credit sách + tác giả trong description
  - [ ] Thumbnail đã chọn
  - [ ] Timestamps trong description
- [ ] Upload YouTube (video dài) — Chủ nhật 19:00
- [ ] Upload Facebook (native, không share link YT)
- [ ] Schedule shorts: Thứ 2, 4, 6
- [ ] Reply comments trong 24h đầu

## Post-Publish Tracking
- [ ] Ghi metrics vào content-calendar.md (sau 7 ngày)
  - Views:
  - Watch time avg:
  - CTR:
  - Top comment:
- [ ] Ghi metrics (sau 30 ngày)
  - Views:
  - Subscribers gained:
  - Lessons learned:
