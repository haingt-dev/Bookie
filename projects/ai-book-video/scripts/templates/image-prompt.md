# AI Image Prompt Templates — Flat Illustration Style

## Style Prefix (dùng cho MỌI prompt)

```
Flat illustration style, minimal, clean lines, soft pastel color palette,
muted warm tones, simple geometric shapes, no outlines, modern minimalist,
editorial illustration style, white or light background,
no text, no watermark, no signature
```

> **QUAN TRỌNG**: Luôn bắt đầu mọi prompt bằng style prefix này để giữ consistency.
> Chỉnh color palette nếu cần nhưng giữ nguyên "flat, minimal, no outlines".

---

## Scene Templates

### Người đọc sách / suy nghĩ
```
[Style Prefix], a person sitting and reading a book,
cozy warm lighting, [thêm context cụ thể]
```

### Concept trừu tượng (mindset, tư duy)
```
[Style Prefix], abstract representation of [concept],
metaphorical visual, [thêm chi tiết]
```

### Người hành động / làm việc
```
[Style Prefix], a person [hành động cụ thể],
[bối cảnh], [thêm chi tiết]
```

### So sánh / Trước-Sau
```
[Style Prefix], split composition showing contrast between
[trạng thái A] on the left and [trạng thái B] on the right,
visual metaphor
```

### Quote highlight
```
[Style Prefix], centered composition with space for text overlay,
[visual metaphor liên quan đến quote], minimalist background
```

### Bìa sách / Giới thiệu
```
[Style Prefix], a book standing upright with warm glow around it,
[thêm elements liên quan đến chủ đề sách]
```

---

## Color Palettes

### Default (Bookie warm)
- Primary: `#E8927C` (coral)
- Secondary: `#7BBFBA` (teal)
- Accent: `#F2C94C` (golden)
- Background: `#FDF6F0` (warm white)
- Dark: `#2D3436` (charcoal)

### Alternative — Cool/Calm (cho sách về mindfulness, tĩnh lặng)
- Primary: `#6C8EBF` (soft blue)
- Secondary: `#A8D5BA` (sage green)
- Background: `#F5F7FA` (cool white)

### Alternative — Bold (cho sách về business, leadership)
- Primary: `#E55B3C` (bold red-orange)
- Secondary: `#2D3436` (dark)
- Accent: `#F2C94C` (golden)
- Background: `#FFFFFF` (clean white)

---

## Thumbnail Prompt
```
[Style Prefix], bold composition, [subject chính],
dramatic lighting, high contrast, vibrant version of palette,
large empty space on [left/right] for text overlay,
eye-catching, social media thumbnail style
```

---

## Tips
- **Aspect ratio**: `--ar 16:9` cho video scenes, `--ar 9:16` cho shorts
- **Không để AI thêm text** — text luôn overlay trong edit, không generate
- **Batch generate**: chạy tất cả scene prompts cùng lúc, review rồi re-gen cái nào lệch style
- **Seed locking** (Midjourney): nếu tìm được style ưng, note lại seed để dùng cho scene khác
- **Negative prompt** (nếu tool hỗ trợ): `no text, no letters, no words, no watermark, no 3D, no realistic photo`
