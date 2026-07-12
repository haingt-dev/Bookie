---
name: event-form
model: sonnet
description: "Tạo form đăng ký + QR + link cho một event Bookie từ event.json — clone form gốc qua Apps Script, điền comms templates. Trigger: 'tạo form đăng ký', 'form cho BD/BT', 'link đăng ký', 'QR đăng ký'."
argument-hint: "<event.json|tên event> [--dry-run]"
allowed-tools: Bash, Read, Write, Edit, Skill, AskUserQuestion, SendUserFile
---

# event-form — form đăng ký + QR + comms cho một event Bookie

`EA=shared/event-automation` (đọc `$EA/README.md` nếu cần chi tiết; spec bộ câu hỏi:
`projects/bd-2026/plan/bieu-mau-dang-ky.md`).

## 0. Điều kiện

- `Bookie/.env` phải có `BOOKIE_FORM_WEBAPP_URL` + `BOOKIE_FORM_SECRET`. Thiếu → hướng dẫn
  Hải deploy một lần theo `$EA/README.md` (mục Deploy), DỪNG tại đó.
- Nội dung form per-event do automation ghi — KHÔNG bảo Hải sửa tay form sau khi tạo
  (trừ duyệt nội dung qua edit link).

## 1. Chuẩn bị `event.json`

- Cùng convention với `/event-graphics`: file ở `projects/<event>/assets/event.json`,
  schema trong `shared/design-system/README.md`.
- Field bắt buộc cho form: `ten_sach`, `loai_event`, `ngay_gio`, `dia_diem` + **`ngay_gio_iso`**
  (`{"start":"YYYY-MM-DDTHH:MM","end":"…"}` — để build link Google Calendar). Thiếu → hỏi Hải
  một lần bằng AskUserQuestion, đừng đoán.
- PII: repo PUBLIC — `dien_gia` chỉ role label hoặc tên đã công bố công khai.

## 2. Tạo form

```bash
cd shared/event-automation
node create-form.mjs --data ../../projects/<event>/assets/event.json
```

- Script tự chặn nếu event.json đã có form (`--force` chỉ khi Hải xác nhận muốn form mới;
  `--qr-only` nếu chỉ cần sinh lại QR).
- Lỗi endpoint (`sai secret`, không trả JSON…) → đọc mục Deploy trong `$EA/README.md`,
  báo Hải nguyên nhân cụ thể, đừng retry mù.
- Thành công → báo Hải **edit link** (duyệt nội dung form ~30 giây) + link `forms.gle`.

## 3. Điền comms templates

Copy các template trong `projects/bd-2026/comms/` → `projects/<event>/output/`, điền từ
event.json (KHÔNG sửa bản gốc):

- `bai-dang-fb.md`: thay `[Link Google Form đăng ký]`/`[Link Google Form]` = `dang_ky`,
  điền tên sách/ngày/địa điểm.
- `email-moi.md` + `email-nhac-1-ngay.md`: như trên, thêm dòng calendar: `calendar_link`.
- Giữ nguyên các placeholder chưa có dữ liệu (vd. tên Host) — đánh dấu `[...]` để team điền.

## 4. Đồ hoạ

- event.json giờ đã có `dang_ky` (forms.gle) + `qr` → invoke skill **`/event-graphics`**
  để render poster (tự gắn ô QR vào info-card, ẩn pill link) + cover.
- Nếu Hải chỉ cần form/link thì dừng, nhắc: chạy `/event-graphics` khi cần ảnh.

## 5. Giao

- Tóm tắt cho Hải: link form (edit + forms.gle), folder Drive, file QR, comms đã điền
  ở đâu. SendUserFile QR PNG nếu Hải cần gắn vào slide.
- Nhắc: `output/` không commit; event.json + QR SVG/PNG trong `assets/` commit được
  (PII-clean).
