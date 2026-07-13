# Xử lý proposal (nội bộ) — proposal chảy đi đâu

Phần này là việc của Bookie/automation — host KHÔNG cần biết, vì vậy KHÔNG nằm trong
Doc gửi host (`de-xuat-de-tai.md` / `[Template] Proposal BT (2026)`).

## Flow mỗi kỳ

1. **Mở kỳ mới**: `cd shared/event-automation && node create-form.mjs --new-proposal "BT31"`
   → endpoint copy Doc template thành `Proposal - BT31` trong `Bookie 2026/Proposals/`,
   trả link → gửi link vào group trao đổi với nhóm host (họ điền trực tiếp trên Doc;
   template không có mục "đầu mối" — mọi trao đổi qua group).
2. **Host điền xong** → đọc proposal, điền `event.json` theo mapping dưới → chạy
   `/event-form` → `/event-graphics` → điền comms templates.
3. Gửi bản nháp (bài công bố + poster + link form) cho đầu mối nhóm host duyệt → đăng.

## Mapping proposal → `event.json`

| Proposal (Phần B) | event.json | Lên đâu |
|---|---|---|
| Mục 1 chủ đề | `ten_sach` | Tiêu đề lớn poster, tên form "Đăng ký BOOK!E TALK #N: …" |
| 1 câu hook rút từ mục 2 | `chu_de` | Eyebrow chip poster, mô tả form, calendar |
| Mục 4 speech (tên/biệt danh) | `dien_gia` | Poster (dòng diễn giả), mô tả form |
| Mục 7 | `ngay_gio` + `ngay_gio_iso` + `dia_diem` | Poster, form, calendar event, link add-to-calendar |
| — | `loai_event` = "Book!e Talk #[Number]" | Badge poster, tên form/folder |

## Mapping proposal → comms (template ở `projects/bd-2026/comms/`, điền vào `output/`)

- **Bài công bố fanpage** = mục 2 (mở đầu) + mục 3 (bullet khía cạnh) + mục 5 ("TẠI SAO
  BẠN NÊN THAM GIA") + **4 nguyên tắc chung — dùng bản trong template proposal** (Hải đã
  biên tập lại 2026-07-13, thay bản gốc L&D cũ) + khối CHƯƠNG TRÌNH (từ mục 7 + link
  đăng ký) + câu kết cố định *"Hẹn gặp các bạn ở buổi Book!e Talk đầy thú vị này nhé!"*
  (bản gốc L&D có typo "Book!ie" — đã sửa).
- **Email mời guest** = bản rút gọn ~40% của bài công bố (giữ hook + lợi ích, bỏ phân tích
  sâu) + box thông tin + nút add-to-calendar.
- **Email nhắc T-1**, **thư cảm ơn T+2** = khung sẵn, chỉ ăn mục 1 + 7.
- Poster/cover/form/QR/lịch: tự động từ `event.json`.

## Sửa template

Template Doc ít khi đổi; cần sửa → edit trực tiếp Doc trong editor + sửa
`de-xuat-de-tai.md` cho khớp (source of truth kép, ghi chú ở đầu file đó).
