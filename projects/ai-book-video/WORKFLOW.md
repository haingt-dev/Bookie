# AI Book Video — Production Workflow

> **Format**: Video dài (5-8 min) + 2-3 shorts cắt từ video chính
> **Platform**: YouTube, Facebook, Shorts/Reels
> **Style**: Flat illustration + motion graphics
> **Voice**: AI voice clone (Fish Speech self-hosted)
> **Tần suất**: 1 video/tuần

---

## Pipeline Overview

```
 ┌─────────┐   ┌─────────┐   ┌───────────┐   ┌──────────┐   ┌────────┐
 │ 1. PICK │──▶│ 2. COOK │──▶│ 3. VISUAL │──▶│ 4. BUILD │──▶│ 5. SHIP│
 │  Chọn   │   │  Viết   │   │  Dựng     │   │  Ghép    │   │ Đăng   │
 │  sách   │   │  script │   │  hình     │   │  video   │   │ & phát │
 └─────────┘   └─────────┘   └───────────┘   └──────────┘   └────────┘
   Day 1          Day 2         Day 3-4         Day 5          Day 6-7
```

### Automation Level

| Phase | Manual | AI-Assisted | Automated |
|-------|--------|-------------|-----------|
| **PICK** | Chọn sách | NotebookLM MCP extract + Claude chọn angle | — |
| **COOK** | Review & feedback | Claude viết script, storyboard, prompts | — |
| **VISUAL** | Chọn & approve | AI image generation | — |
| **BUILD** | — | — | Voice (Fish Speech) → Subtitle (PhoWhisper) → Render (Remotion) |
| **SHIP** | Upload & schedule | Claude viết metadata | — |

**Target automation flow (Phase 4)**:
```
Script text → [Fish Speech] → WAV → [PhoWhisper] → SRT → [Remotion] → MP4 + Shorts
```

---

## Quick Start — Video mới

```bash
# 1. Init project cho cuốn sách
./scripts/init-video.sh <book-slug>

# 2. (Manual) Dùng NotebookLM MCP + Claude để viết script
#    → scripts/<book-slug>/notes.md, script.md, storyboard.md

# 3. (Manual) Generate illustrations từ storyboard prompts
#    → assets/<book-slug>/scenes/

# 4. Generate voice → subtitle → render
./scripts/generate-voice.sh <book-slug>
./scripts/generate-subtitle.sh <book-slug>
# Remotion render (khi template ready):
# npx remotion render BookVideo out/video.mp4

# 5. (Manual) Upload + write metadata
```

---

## Phase 1: PICK — Chọn sách & Extract (Day 1)

> **Tools**: **NotebookLM** (via MCP trong Antigravity), **Claude**

### Input
- Sách đã đọc (PDF/ebook/physical)

### Process

#### 1a. Extract bằng NotebookLM MCP

Dùng trực tiếp trong Antigravity (không cần mở browser):
```
# Tạo notebook mới
nlm notebook create "Atomic Habits - James Clear"

# Add source (PDF, URL, YouTube, Google Drive)
nlm source add <notebook-id> --url "https://..."
nlm source add <notebook-id> --file "/path/to/book.pdf"

# Query để extract insights
nlm notebook query <notebook-id> "Tóm tắt 5 key insights chính"
nlm notebook query <notebook-id> "Tìm 3 câu chuyện/ví dụ hay nhất"
nlm notebook query <notebook-id> "Tìm quotes có impact cao"
```

> **Setup MCP (1 lần)**: `uv tool install notebooklm-mcp-cli && nlm auth login && nlm setup add antigravity`
> **⚠️ Context warning**: 29 tools, disable khi không dùng.

#### 1b. Competitive Analysis (nhanh)
- Search YouTube VN: đã có ai làm video về sách này?
- Tìm keyword gap — angle nào chưa ai khai thác?
- Ghi vào `notes.md` → phần Competitive Analysis

#### 1c. Chọn Angle (Claude)
- Prompt: xem `scripts/templates/claude-prompts.md` → **Prompt 1**
- Input: raw notes từ NotebookLM + target audience context
- Output: 3 angle options ranked theo potential engagement
- Chọn **1 góc kể** — KHÔNG tóm tắt cả cuốn sách

### Output
- `scripts/<book-slug>/notes.md` — raw notes + competitive analysis
- Angle đã chọn

### Tips
- Angle tốt = giải quyết 1 pain point cụ thể, không phải book report
- Ưu tiên sách có câu chuyện/ví dụ minh họa — dễ visualize hơn
- Chọn sách có thể liên hệ thực tế audience 20-35 tuổi

---

## Phase 2: COOK — Viết Script (Day 2)

> **Tools**: **Claude** (script, storyboard, image prompts)

### Input
- Notes từ Phase 1
- Angle đã chọn

### Process
1. Dùng **Claude** viết script
   - Prompt: xem `scripts/templates/claude-prompts.md` → **Prompt 2**
   - Input: notes + angle + script template
   - Claude output: script draft theo structure bên dưới
2. Structure:
   - **Hook** (0:00-0:15): Câu hỏi/statement gây tò mò
   - **Context** (0:15-0:45): Giới thiệu sách + vì sao nó relevant
   - **Body** (0:45-6:00): 2-3 insights chính, mỗi insight kèm ví dụ/câu chuyện
   - **Takeaway** (6:00-7:00): Hành động cụ thể audience có thể làm ngay
   - **CTA** (7:00-7:30): Subscribe, follow, gợi ý sách tiếp theo
3. Đánh dấu **[SHORT]** cho đoạn có thể cắt làm shorts
4. **Word count check**: 900-1050 từ (130-150 từ/phút × 7 phút)
5. **Đọc to 1 lần** — check flow tự nhiên trước khi finalize
6. Viết **storyboard + image prompts** (gộp 1 file)
   - Prompt: `claude-prompts.md` → **Prompt 2** (storyboard) + **Prompt 3** (image prompts)

### Output
- `scripts/<book-slug>/script.md` — script hoàn chỉnh (word count verified)
- `scripts/<book-slug>/storyboard.md` — storyboard + image prompts (merged)

### Tips
- Yêu cầu Claude output word count cho mỗi section
- Mỗi insight: concept → ví dụ cụ thể → liên hệ thực tế
- Tone: tự nhiên, kể chuyện cho bạn bè, xưng "mình"

---

## Phase 3: VISUAL — Dựng Illustration (Day 3-4)

> **Tools**: Midjourney / Leonardo AI, Canva

### Input
- Image prompts từ `storyboard.md`
- Brand guidelines: `assets/brand/style-guide.md`

### Process
1. Liệt kê scenes cần illustration (thường 8-15 scenes cho 7 phút)
2. Generate flat illustration bằng AI:
   - Dùng image prompts đã viết ở Phase 2
   - Consistent style: giữ cùng prompt prefix cho toàn bộ video
   - Tools: **Midjourney** (quality) / **Leonardo AI** (free tier tốt) / **Ideogram**
3. Review & regenerate nếu style không consistent

### Quality Checklist
- [ ] Cùng color palette xuyên suốt (dùng color codes trong style guide)
- [ ] Cùng character design (nếu có nhân vật lặp lại)
- [ ] Không có text trong illustration
- [ ] Aspect ratio đúng (16:9 cho video, 9:16 cho shorts)

### Naming Convention
```
assets/<book-slug>/scenes/
├── scene-01-hook-opening.png
├── scene-02-book-intro.png
├── scene-03-insight1-concept.png
├── ...
```

4. Tạo thumbnail bằng **Canva** (dùng brand template cố định)
   - Mặt người/biểu cảm mạnh + text to + màu contrast
   - Để trống space cho title text

### Output
- `assets/<book-slug>/scenes/` — all scene illustrations
- `assets/<book-slug>/thumbnail/` — thumbnail variations

### Tips
- Generate 2-3 variations mỗi scene, chọn cái tốt nhất
- Hạn chế text trong illustration — text sẽ overlay trong editing
- Seed locking (Midjourney): note lại seed nếu tìm được style ưng

---

## Phase 4: BUILD — Dựng Video (Day 5)

> **Tools**: **Fish Speech** (AI voice), **PhoWhisper** (subtitle), **Remotion** (render)

### Input
- Script, illustrations từ Phase 2-3

### Process

#### 4a. Generate Voice (Automated)

```bash
# Chạy 1 lệnh — script text → WAV
./scripts/generate-voice.sh <book-slug>

# Input:  scripts/<book-slug>/script.md
# Output: assets/<book-slug>/audio/voiceover.wav
```

**Fish Speech self-hosted** trên local GPU (RTX 4070 Super Ti, 16GB VRAM).

Setup 1 lần:
1. Clone voice reference: Record 1-3 phút giọng đọc tự nhiên → `assets/brand/voice-reference/reference.wav`
2. Install Fish Speech server (xem hướng dẫn trong `generate-voice.sh`)
3. Chạy API server: `python -m tools.api_server --listen 0.0.0.0:8080`

Sau đó mỗi video chỉ cần: `./scripts/generate-voice.sh <slug>`

**Review voice**: nghe lại, fix nếu:
- Phát âm tên riêng sai → thêm phonetic hint trong script
- Ngữ điệu phẳng → break script thành câu ngắn hơn

#### 4b. Auto Subtitle (Automated)

```bash
./scripts/generate-subtitle.sh <book-slug>

# Input:  assets/<book-slug>/audio/voiceover.wav
# Output: output/<book-slug>/subtitles.srt
```

Dùng **PhoWhisper** (Whisper fine-tuned cho tiếng Việt) — accuracy cao hơn Whisper gốc.

Review subtitle: fix tên riêng, thuật ngữ, timing.

#### 4c. Dựng Video (Remotion)

> Xem chi tiết: [Remotion Template Project](#remotion-template-project)

1. Update `scenes.json` với scene info
2. Import voiceover + illustrations
3. Chỉnh timing, transitions, text overlays
4. Thêm nhạc nền (volume ~15-20% so với voice)
5. Intro (3-5s): Logo animation + tên series
6. Outro (5-10s): CTA + gợi ý video khác
7. Render:

```bash
# Render video dài (16:9, 1080p)
npx remotion render BookVideo out/video.mp4

# Render shorts (9:16, 1080p)
npx remotion render BookShort out/short-1.mp4 \
  --props='{"startScene": 2, "endScene": 4}'
```

#### 4d. Cắt Shorts
1. Chọn 2-3 đoạn đánh dấu **[SHORT]** trong script
2. Remotion config reframe 9:16 từ video dài
3. Subtitle to hơn (~48px, 1/3 màn hình dưới)
4. Hook câu đầu tiên phải gây tò mò trong 1-2 giây
5. Render shorts riêng

### Output
- `output/<book-slug>/video.mp4` — video dài
- `output/<book-slug>/short-*.mp4` — shorts
- `output/<book-slug>/subtitles.srt` — subtitle file

---

## Phase 5: SHIP — Đăng & Phân phối (Day 6-7)

> **Tools**: **Claude** (metadata), YouTube Studio, Meta Business Suite

### Checklist trước khi đăng
- [ ] Subtitle đã review (không sai tên riêng, thuật ngữ)
- [ ] Credit sách + tác giả trong description
- [ ] Thumbnail đã chọn
- [ ] Title + description đã viết
- [ ] Tags/hashtags đã chuẩn bị
- [ ] Timestamps trong description

### Viết Metadata (Claude)
Dùng **Claude** để viết title, description, tags:
- Prompt: xem `scripts/templates/claude-prompts.md` → **Prompt 4**
- Input: script + angle + target platform
- Output: 3 title options + description + tags

### Upload Schedule
| Platform | Format | Khi nào |
|----------|--------|---------|
| YouTube | Video dài (16:9) | Chủ nhật 19:00 |
| YouTube Shorts | 2-3 shorts (9:16) | Thứ 2, 4, 6 |
| Facebook | Video dài (native upload) | Cùng lúc YouTube |
| Facebook Reels | Shorts | Cùng lúc YT Shorts |

> **⚠️ Facebook**: Upload native video, KHÔNG share link YouTube. Facebook giảm reach cho link ngoài.

### Post-Publish
- **24h đầu**: Reply tất cả comments — thuật toán ưu tiên engagement sớm
- **7 ngày**: Ghi metrics vào `content-calendar.md`
- **30 ngày**: Update final metrics, rút kinh nghiệm

---

## Feedback Loop

```
                    ┌──────── Analytics ──────────┐
                    ▼                              │
PICK → COOK → VISUAL → BUILD → SHIP → MEASURE ──┘
```

**Monthly Review** (sau 4 videos):
- Topic nào có views/retention cao nhất?
- Hook nào giữ người xem qua 30 giây?
- Format nào cần đổi?
- Điều chỉnh Phase 1 (chọn sách) và Phase 2 (script) theo data

---

## Remotion Template Project

### Setup (1 lần)

#### Prerequisites
- Node.js 18+ (`node -v`)
- npm hoặc pnpm

#### Cài đặt
```bash
# 1. Cài Remotion
npx create-video@latest bookie-video-template
cd bookie-video-template
npm install

# 2. Mở project trong Antigravity IDE
```

#### Template Project Structure
```
bookie-video-template/
├── src/
│   ├── compositions/
│   │   ├── BookVideo.tsx       ← Main video composition (16:9)
│   │   ├── BookShort.tsx       ← Shorts composition (9:16)
│   │   └── components/
│   │       ├── SceneSlide.tsx  ← Scene với illustration + text overlay
│   │       ├── Intro.tsx       ← Logo animation
│   │       ├── Outro.tsx       ← CTA screen
│   │       └── Subtitle.tsx   ← Subtitle renderer (từ SRT)
│   ├── data/
│   │   ├── scenes.json        ← Scene config (image, duration, text)
│   │   └── subtitles.srt      ← Subtitle file
│   └── assets/                ← Illustrations + audio cho video hiện tại
├── public/
│   └── fonts/                 ← Brand fonts
├── remotion.config.ts
└── package.json
```

### Tips
- Giữ `scenes.json` là source of truth — dễ batch update
- Nếu cần custom animation phức tạp: edit trực tiếp `.tsx` files
- Render time: ~2-5 phút cho video 7 phút (tùy máy)

---

## Tools Summary

| Bước | Tool | Vai trò | Cost |
|------|------|---------|------|
| Extract insights | NotebookLM (MCP) | Tóm tắt sách, tìm quotes | Free |
| Phân tích + chọn angle | **Claude** | Đề xuất angles từ notes | — |
| Viết script & storyboard | **Claude** | Draft script, visual notes | — |
| Viết image prompts | **Claude** | Batch prompts cho AI image gen | — |
| AI illustration | Midjourney / Leonardo AI | Generate flat illustrations | Varies |
| Thumbnail | Canva | Design thumbnail | Free tier |
| **AI Voice** | **Fish Speech** (self-host) | Script → voiceover WAV | Free (local GPU) |
| **Auto subtitle** | **PhoWhisper** | Speech-to-text → SRT | Free (local) |
| Video render | **Remotion** | React framework, CLI render | Free (OSS) |
| Viết metadata | **Claude** | Title, description, tags | — |
| Upload & schedule | YouTube Studio / Meta Business | Publish & schedule | Free |

---

## Weekly Schedule

| Ngày | Task | Tool chính | Thời gian |
|------|------|-----------|-----------| 
| **Thứ 2** | Pick sách + NotebookLM extract | NotebookLM MCP | 1-2h |
| **Thứ 2** | Claude phân tích notes → chọn angle | Claude | 30m |
| **Thứ 3** | Viết script + storyboard + image prompts | Claude | 2-3h |
| **Thứ 4-5** | Generate illustrations + thumbnail | Midjourney/Leonardo, Canva | 1-2h |
| **Thứ 6** | Generate voice + subtitle (automated) | Fish Speech, PhoWhisper | 15m |
| **Thứ 6** | Dựng video + render | Remotion | 1-2h |
| **Thứ 7** | Cắt shorts + render | Remotion CLI | 30m |
| **Thứ 7** | Viết metadata + chuẩn bị upload | Claude | 30m |
| **Chủ nhật** | Upload video dài | YouTube Studio, Meta Business | 30m |
| **Thứ 2,4,6** | Upload shorts (schedule trước) | YouTube Studio, Meta Business | 15m/short |

**Total: ~7-11h/tuần** cho 1 video dài + 2-3 shorts
*(Giảm ~2-3h nhờ AI voice + Remotion template + automation scripts)*

---

## File Structure Reference

```
projects/ai-book-video/
├── WORKFLOW.md                    ← Bạn đang đọc file này
├── assets/
│   ├── brand/
│   │   ├── style-guide.md        ← Visual style guide
│   │   └── voice-reference/
│   │       └── reference.wav     ← Voice sample cho Fish Speech
│   └── <book-slug>/
│       ├── scenes/               ← AI illustrations
│       ├── thumbnail/            ← Thumbnails
│       └── audio/                ← Generated voiceover
├── scripts/
│   ├── init-video.sh             ← Tạo folder structure mới
│   ├── generate-voice.sh         ← Script → WAV (Fish Speech)
│   ├── generate-subtitle.sh      ← WAV → SRT (PhoWhisper)
│   ├── content-calendar.md       ← Tracking production & metrics
│   ├── templates/
│   │   ├── claude-prompts.md     ← 4 prompt templates cho Claude
│   │   ├── script-template.md    ← Script format
│   │   ├── image-prompt.md       ← Image generation templates
│   │   └── checklist.md          ← Production checklist
│   └── <book-slug>/
│       ├── notes.md              ← NotebookLM extract
│       ├── script.md             ← Video script
│       ├── storyboard.md         ← Storyboard + image prompts
│       └── metadata.md           ← YouTube/FB metadata
└── output/
    └── <book-slug>/
        ├── video.mp4             ← Final video
        ├── short-*.mp4           ← Shorts
        └── subtitles.srt         ← SRT file
```
