# AI Image Prompt Templates — Flat Illustration Style

> **Tool**: Gemini Nano Banana 2 (gemini.google.com)
> **Format**: Natural language prompts (complete sentences, not comma-separated keywords)
> **Note**: Gemini does not have separate negative prompt syntax — include constraints inline ("no text, no watermark")

## Style Instruction (dùng cho MỌI prompt)

```
Create a flat, minimalist editorial illustration in 16:9 landscape format.
Use a soft warm color palette with green (#368C06) and orange (#C86108) as accent colors
on a light (#FAFDF5) background. Simple geometric shapes, clean lines, no outlines.
No text, no watermark in the image.
```

> **QUAN TRỌNG**: Luôn bắt đầu mọi prompt bằng style instruction này để giữ consistency.
> Chỉnh chi tiết nếu cần nhưng giữ nguyên "flat, minimal, no outlines" + brand colors.

---

## Scene Templates

### Người đọc sách / suy nghĩ
```
[Style Instruction]
A person is sitting and reading a book in a cozy setting with warm lighting.
[Thêm context cụ thể]. No text, no watermark in the image.
```

### Concept trừu tượng (mindset, tư duy)
```
[Style Instruction]
The scene shows an abstract representation of [concept] through visual metaphor.
[Thêm chi tiết về metaphor]. No text, no watermark in the image.
```

### Người hành động / làm việc
```
[Style Instruction]
A person is [hành động cụ thể] in [bối cảnh].
[Thêm chi tiết]. No text, no watermark in the image.
```

### So sánh / Trước-Sau
```
[Style Instruction]
The composition is split down the center, showing the contrast between
[trạng thái A] on the left and [trạng thái B] on the right.
A visual metaphor conveys the difference. No text, no watermark in the image.
```

### Quote highlight
```
[Style Instruction]
A centered composition with open space for text overlay.
[Visual metaphor liên quan đến quote] fills the scene with a minimalist background.
No text, no watermark in the image.
```

### Bìa sách / Giới thiệu
```
[Style Instruction]
A book stands upright at the center with a warm glow around it.
[Thêm elements liên quan đến chủ đề sách] surround the book.
No text, no watermark in the image.
```

---

## Color Palette (Bookie Brand)

| Role | Hex | Dùng cho |
|------|-----|----------|
| Primary green | `#368C06` | Growth, positive elements |
| Bright green | `#4AC808` | Accent, highlight |
| Accent orange | `#C86108` | Tension, emphasis, CTA |
| Background | `#FAFDF5` | Very light green tint |
| Text dark | `#2D3436` | Dark elements |
| Text light | `#636E72` | Secondary, muted elements |

> Source: `brand/style-guide.md`

---

## Thumbnail Prompt
```
[Style Instruction]
A bold composition with [subject chính] at the center.
Dramatic lighting and high contrast with vibrant green and orange accents.
Large empty space on the [left/right] for text overlay.
Eye-catching social media thumbnail style. No text, no watermark in the image.
```

---

## Tips
- **Aspect ratio**: Gemini understands "16:9 landscape" hoặc "9:16 portrait" trong natural language
- **Không để AI thêm text** — text luôn overlay trong edit, không generate. Nhắc lại "no text" ở cuối prompt.
- **Batch generate**: paste tất cả scene prompts liên tục, review rồi re-gen cái nào lệch style
- **Style consistency**: Nếu tìm được output ưng ý, dùng prompt đó làm base cho các scene khác
- **Inline constraints**: Gemini không có negative prompt riêng — viết constraints trực tiếp trong prompt ("no text, no watermark, no realistic faces")
