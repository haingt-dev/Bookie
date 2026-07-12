---
name: event-graphics
model: sonnet
description: "Sinh bộ đồ hoạ sự kiện Bookie (poster FB 4:5 + cover event) từ event.json — nền gen-art + template brand-locked. Trigger: 'làm poster', 'cover event', 'đồ hoạ sự kiện', 'ảnh cho BD/BT/Gala'."
argument-hint: "<event.json|tên event> [--no-bg] [--formats poster-feed,cover-event]"
allowed-tools: Bash, Read, Write, Edit, Skill, AskUserQuestion, SendUserFile
---

# event-graphics — poster + cover cho một event Bookie

`DS=shared/design-system` (đọc `$DS/README.md` nếu cần chi tiết schema/khổ).

## 1. Chuẩn bị `event.json`

- Có sẵn file → dùng. Chưa có → tạo `projects/<event>/assets/event.json` theo schema
  trong `$DS/README.md`, điền từ proposal/checklist của event (vd. `projects/bd-2026/plan/`).
- Thiếu field bắt buộc (tên sách, ngày giờ, địa điểm, link đăng ký) → hỏi Hải một lần
  bằng AskUserQuestion, đừng đoán.
- Thiếu `dang_ky` vì form chưa tạo → gợi ý chạy **`/event-form`** trước (tạo form + QR
  tự động, ghi ngược `dang_ky` + `qr` vào event.json — poster tự gắn ô QR vào info-card).
- PII: repo PUBLIC — `dien_gia` chỉ ghi role label hoặc tên đã công bố công khai.
- Hashtag đúng casing: `#BookieDiscussion`.

## 2. Nền minh hoạ (bỏ qua nếu `--no-bg` → gradient brand)

1. Tái dùng trước: xem `$DS/backgrounds/final/` — có nền hợp chủ đề thì dùng luôn, $0.
2. Chưa có → invoke skill **`/gen-art`** (KHÔNG tự gọi imagegen tay): subject = chủ đề
   sách/event bằng tiếng Anh, mô tả cảnh — anchor Bookie tự ép style + no-text.
   - Poster: `--size 1024x1536` · Cover: `--size 1536x1024` (cùng subject).
   - Ladder: `--quality low` 2–3 candidates → Hải chọn (AskUserQuestion kèm ảnh) →
     regen bản chọn `--quality high` → chuyển vào `$DS/backgrounds/final/`, đặt tên
     `<chu-de>--<huong>.jpg`.
3. Điền đường dẫn nền vào `event.json` (`bg`, tương đối so với file data). Poster và
   cover có thể trỏ 2 file data / 2 giá trị `bg` khác hướng — khi đó tạo
   `event-cover.json` chỉ khác field `bg`.

## 3. Render

```bash
cd shared/design-system
node render.mjs --template poster-feed --data <event.json> --out ../../projects/<event>/output/
node render.mjs --template cover-event --data <event-cover.json|event.json> --out ../../projects/<event>/output/
```

## 4. Tự review (Read từng PNG, sửa rồi render lại tới khi đạt)

- Chữ: đúng dấu, không tràn khối, tiêu đề ≤ số dòng cho phép, tương phản đủ trên nền.
- Cover: toàn bộ chữ/logo trong safe zone — nghi ngờ thì render thêm `--debug-safe-area`.
- Nền: không dính chữ/watermark AI, vibe khớp brand, vùng đặt chữ đủ "yên".
- Logo sắc nét, badge/CTA không bể layout với data thật.

## 5. Giao

- SendUserFile các PNG cuối cho Hải duyệt (kèm 1 dòng: nền nào, template version nào).
- Nhắc: PNG nằm ở `projects/<event>/output/` (không commit); nền final + event.json
  thì commit được.
