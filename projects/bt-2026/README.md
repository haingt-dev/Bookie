# bt-2026 — chuỗi Bookie Talk mở lại (host khách mời)

## About

Chuỗi sinh hoạt theo format **Book!e Talk** do một nhóm host khách mời dẫn dắt (khách mời danh dự
theo Bookie từ thời đầu + nhóm bạn học Quản lý cấp trung, muốn thực hành thuyết trình / nói trước
công chúng). Bookie hỗ trợ hậu cần + quảng bá qua automation (`/event-form`, `/event-graphics`);
nhóm host lo chủ đề, agenda, speech. Founder đã approve; chi tiết chốt dần trong group trao đổi.

Chủ đề dự kiến: quản trị / phát triển bản thân. Thời điểm khởi động: sau giữa tháng 07/2026.

> Tên folder là codename theo format (mirror `bd-2026`) — đổi khi chuỗi có tên chính thức.

Flow mỗi kỳ (nhịp quen của Bookie): automation copy **proposal** cho kỳ mới
(`create-form.mjs --new-proposal "BT31"` — template host-facing `plan/de-xuat-de-tai.md`
· Doc gốc trong `Bookie 2026/Templates/`) → nhóm host điền → Bookie làm content truyền
thông + email guest + automation theo `plan/xu-ly-proposal.md`.

## Structure

- `plan/` — Operation: briefing khởi động, proposal template, timeline, spec biểu mẫu
- `content/` — Host/MC: agenda/rundown, câu hỏi thảo luận, khung đánh giá
- `comms/` — MarCom: tin nhắn/email/bài đăng
- `assets/` — event.json, QR, ảnh nền poster
- `output/` — thành phẩm per-event (không commit)

## Status

- Created: 2026-07-13
- Status: Incubating
