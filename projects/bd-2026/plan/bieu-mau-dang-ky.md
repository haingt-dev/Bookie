# Biểu mẫu Đăng ký sự kiện — Book!e Discussion

Spec của **form gốc** (canonical template) cho form đăng ký BD/BT. Khác với các template khác trong kit: form này KHÔNG copy tay mỗi event — skill [`/event-form`](../../../shared/event-automation/README.md) tự clone form gốc và điền nội dung per-event từ `event.json`. Việc của con người chỉ là dựng form gốc này MỘT LẦN cho đúng spec.

> Bối cảnh: toàn bộ 82 form cũ trong Drive không đọc được qua crawl (`00-inventory/inventory.json` — `unreadable-form`), nghĩa là bộ câu hỏi đăng ký chưa từng được đặc tả ở đâu; mỗi event clone lại "form gần nhất" — đây chính là nguồn lỗi "copy quên cập nhật" playbook đã ghi nhận. File này là lần đầu bộ câu hỏi được freeze thành spec: **đổi câu hỏi = sửa form gốc + sửa file này**, không sửa lẻ tẻ trong form của từng event.

## Phân vùng nội dung form

| Vùng | Gồm | Ai ghi |
|---|---|---|
| **Per-event** (đổi mỗi buổi) | Tiêu đề form · Mô tả (chủ đề, ngày giờ, địa điểm, diễn giả) · Confirmation message (kèm link "thêm vào Google Calendar") | **Automation** ghi từ `event.json` — không sửa tay |
| **Cố định** (mọi buổi) | Toàn bộ câu hỏi bên dưới + settings | Form gốc trong `Bookie 2026/Templates/` |

Quy ước tên form (automation tự đặt): `Đăng ký BOOK!E DISCUSSION: <TÊN SÁCH>` (theo pattern các form cũ 2023–2024).

## Các trường của form gốc (theo thứ tự)

| # | Tên trường | Loại câu hỏi | Bắt buộc | Ghi chú |
|---|-----------|-------------|----------|---------|
| 1 | Timestamp | Tự động (Google Form) | Tự động | Không cần tạo thủ công |
| 2 | Email | Setting "Thu thập địa chỉ email" → *Responder input* | Bắt buộc | Không bắt đăng nhập Google — giảm friction |
| 3 | Họ và tên | Text (câu trả lời ngắn) | Bắt buộc | |
| 4 | Số điện thoại (có Zalo) | Text (câu trả lời ngắn) | Bắt buộc | Kênh nhắc lịch T-1 |
| 5 | Bạn là ai với Book!e? | Multiple choice | Bắt buộc | `Bookier (thành viên)` / `Bookie's Friend — từng tham gia` / `Lần đầu tham gia` |
| 6 | Bạn đã đọc cuốn sách của buổi này chưa? | Multiple choice | Không bắt buộc | `Đã đọc` / `Đang đọc` / `Chưa đọc` — giúp Host cân chỉnh độ sâu thảo luận |
| 7 | Bạn biết sự kiện qua đâu? | Multiple choice | Không bắt buộc | `Fanpage` / `Email` / `Bạn bè giới thiệu` / `Khác` — đo kênh truyền thông cho MarCom |
| 8 | Câu hỏi / điều bạn muốn thảo luận | Text (đoạn dài) | Không bắt buộc | Gửi trước cho Host/Speaker chuẩn bị |

Nguồn các trường: distill từ những form đọc được trong knowledge base (Book!e Exchange 2017: họ tên/email/số buổi đã tham gia; check-in BD/BT: họ tên + email; Gala 2023–2024: name/email/phone/loại thành viên) + nhu cầu vận hành trong playbook. Không thêm câu hỏi dài dòng — form đăng ký phải điền xong dưới 1 phút.

## Settings của form gốc

- [ ] Thu thập email: **Responder input** (không bắt đăng nhập, không giới hạn 1 phản hồi — bản ghi trùng xử lý khi tổng hợp, đúng thực tế vận hành cũ)
- [ ] Ảnh header: banner brand Bookie (lấy từ `shared/branding/`, một lần — mọi form clone tự kế thừa)
- [ ] Confirmation message: để placeholder bất kỳ — automation ghi đè mỗi event (cảm ơn + ngày giờ + địa điểm + calendar link)
- [ ] KHÔNG bật "Limit to 1 response" (đòi đăng nhập Google)

## Checklist dựng form gốc (một lần, account bookie.community@gmail.com)

- [ ] Tạo form mới trong `Bookie 2026/Templates/`, tên: `Format Form đăng ký BD (2026)` (nối tiếp pattern "Format Form đky BT (mới)" 2024)
- [ ] Dựng 8 trường đúng thứ tự + settings ở trên
- [ ] Submit thử 1 response → xoá response test
- [ ] Lấy `TEMPLATE_ID` (chuỗi giữa `/d/` và `/edit` trong URL editor) → điền vào Script Properties của Apps Script (xem [deploy guide](../../../shared/event-automation/README.md))

---

> Nguồn: chưng cất từ [BD playbook](../../../knowledge/03-playbook/book-discussion.md) (§3 — mục "Chuẩn bị Form: đăng ký"), [BT playbook](../../../knowledge/03-playbook/bookie-talk.md) (§5, §10 — rủi ro template hóa), form analog trong [book-exchange](../../../knowledge/03-playbook/book-exchange.md) §3 và [gala](../../../knowledge/03-playbook/gala.md) §8.
