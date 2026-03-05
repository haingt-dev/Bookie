# Claude Prompt Templates — AI Book Video

> **SUPERSEDED**: Các prompt này đã được chuyển thành Claude Code skills.
> Dùng `/extract-notes`, `/write-script`, `/write-storyboard`, `/write-metadata` thay vì copy-paste.
> Skills tự đọc input files và write output — không cần paste thủ công.
> File này giữ lại làm reference.

> ~~Dùng các prompt này trong mỗi video production cycle.~~
> ~~Copy prompt → paste vào Claude → cung cấp input data.~~

---

## Prompt 1: Phân tích Notes → Chọn Angle

**Dùng khi**: Có raw notes từ NotebookLM, cần chọn góc kể cho video.

```
Mình đang làm video sách cho kênh Bookie — target audience là người Việt 20-35 tuổi, quan tâm self-improvement và đọc sách.

Đây là notes mình extract từ cuốn "[TÊN SÁCH]" của [TÁC GIẢ]:

---
[DÁN RAW NOTES TỪ NOTEBOOKLM VÀO ĐÂY]
---

Từ notes này, đề xuất 3 angle cho video YouTube (5-8 phút). Mỗi angle cần:
1. **Tiêu đề làm việc** (working title)
2. **Hook** — câu mở đầu video (gây tò mò trong 3 giây)
3. **Core message** — 1 câu tóm video nói về gì
4. **2-3 key points** sẽ cover trong video
5. **Vì sao angle này work** — tại sao audience sẽ click và xem hết

Rank 3 angles theo potential engagement. Ưu tiên angle:
- Giải quyết pain point cụ thể (không phải book summary chung chung)
- Có câu chuyện/ví dụ để visualize
- Đủ focused cho 5-8 phút (không ôm đồm)
```

---

## Prompt 2: Viết Script + Storyboard

**Dùng khi**: Đã chọn angle, cần viết script hoàn chỉnh.

```
Viết script video cho kênh Bookie.

**Sách**: [TÊN SÁCH] — [TÁC GIẢ]
**Angle đã chọn**: [ANGLE]
**Notes**: [DÁN NOTES HOẶC TÓM TẮT KEY POINTS]

Yêu cầu script:
- Độ dài: 900-1050 từ (target 7 phút, 130-150 từ/phút)
- Tone: Tự nhiên, như đang kể chuyện cho bạn bè. Không academic, không dạy đời.
- Ngôn ngữ: Tiếng Việt, xưng "mình"

Structure:
1. **Hook** (0:00-0:15) — Câu hỏi hoặc statement bất ngờ. KHÔNG bắt đầu bằng "Xin chào" hay giới thiệu kênh.
2. **Context** (0:15-0:45) — Giới thiệu sách, vì sao mình đọc, vì sao nó relevant
3. **Body** (0:45-6:00) — 2-3 insights chính. Mỗi insight: concept → ví dụ/câu chuyện cụ thể → liên hệ thực tế
4. **Takeaway** (6:00-7:00) — 1 hành động cụ thể audience làm được ngay hôm nay
5. **CTA** (7:00-7:30) — Nhẹ nhàng: subscribe, comment sách bạn muốn nghe tiếp

Đánh dấu **[SHORT]** trước những đoạn có thể cắt làm YouTube Shorts (15-60 giây, phải tự đứng được khi tách ra).

---

Sau khi viết script, viết thêm **storyboard notes** cho từng section:

| Timestamp | Script section | Visual suggestion |
|-----------|---------------|-------------------|
| 0:00-0:15 | Hook | [Mô tả hình ảnh/animation] |
| ... | ... | ... |

Visual style: flat illustration, minimalist, warm colors. Tập trung vào metaphor và emotion, không literal.
```

---

## Prompt 3: Batch Image Prompts

**Dùng khi**: Có storyboard, cần viết prompts cho AI image generation.

```
Từ storyboard notes bên dưới, viết image prompts cho AI generation (Midjourney / Leonardo AI).

**Storyboard**:
[DÁN STORYBOARD NOTES VÀO ĐÂY]

**Style guide**:
- Style: flat illustration, 2D, minimalist
- Color palette: [MÀU CHÍNH TỪ STYLE GUIDE, vd: warm earth tones, #F4A261, #2A9D8F]
- Vibe: warm, inspirational, friendly
- NO text in images
- NO realistic faces (dùng simple character design)
- Aspect ratio: 16:9

Viết 1 prompt cho mỗi scene. Format:

**Scene [số]**: [mô tả ngắn scene]
```
[Prompt sẵn sàng paste vào Midjourney/Leonardo]
```

Giữ consistent style prefix cho tất cả prompts. Ví dụ prefix:
"Flat 2D illustration, minimalist style, [color palette], warm lighting, no text —"
```

---

## Prompt 4: YouTube Metadata

**Dùng khi**: Video đã render, cần viết title/description/tags để upload.

```
Viết YouTube metadata cho video sách của kênh Bookie.

**Sách**: [TÊN SÁCH] — [TÁC GIẢ]
**Angle**: [ANGLE CỦA VIDEO]
**Script tóm tắt**: [2-3 CÂU TÓM NỘI DUNG VIDEO]
**Timestamps**:
[DANH SÁCH TIMESTAMPS NẾU CÓ]

Cần:

### 1. Title (3 options)
- Tiếng Việt, tối đa 60 ký tự
- Gây tò mò, có benefit rõ ràng
- Không clickbait rẻ tiền
- Tên sách phải xuất hiện trong title

### 2. Description
Theo format:
📚 [Tên sách] — [Tác giả]
[2-3 câu hook]
⏱️ Timestamps: [điền timestamps]
🔗 Links: [placeholder]
📱 Follow Bookie: bookiecommunity.com | facebook.com/bookie.community
Hashtags cuối description

### 3. Tags (15-20 tags)
Mix: tên sách, tên tác giả, chủ đề, "tóm tắt sách", "review sách", "đọc sách", "self improvement", keywords tiếng Việt + tiếng Anh

### 4. Shorts metadata
Cho mỗi short: title ngắn (40 ký tự) + 5 hashtags
```

---

## Tips sử dụng

- **Cung cấp đủ context**: Luôn paste notes/storyboard thay vì nói "như đã thảo luận"
- **Iterative**: Claude viết draft → Hải review → feedback cụ thể → Claude revise (2-3 rounds max)
- **Batch**: Có thể chạy Prompt 3 + Prompt 4 trong cùng session sau khi script xong
- **Tone check**: Nếu script nghe "robotic", yêu cầu Claude viết lại tự nhiên hơn, cụ thể đoạn nào
- **Consistency**: Dùng cùng conversation cho cả Prompt 2 + 3 để Claude giữ context về sách
