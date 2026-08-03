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
| 6 | Bạn đã đọc cuốn sách của buổi này chưa? | Multiple choice | Không bắt buộc | `Đã đọc` / `Đang đọc` / `Chưa đọc` — giúp Host cân chỉnh độ sâu thảo luận. Help text: "Với Book!e Talk (theo chủ đề): tính là cuốn sách bạn định mang theo." — một form gốc phục vụ cả BD lẫn BT |
| 7 | Bạn biết sự kiện qua đâu? | Multiple choice | Không bắt buộc | `Fanpage` / `Email` / `Bạn bè giới thiệu` / `Khác` — đo kênh truyền thông cho MarCom |
| 8 | Câu hỏi / điều bạn muốn thảo luận | Text (đoạn dài) | Không bắt buộc | Gửi trước cho Host/Speaker chuẩn bị |
| 9 | Nhận email về các sự kiện sắp tới của Book!e | Checkboxes (1 lựa chọn) | Không bắt buộc, KHÔNG tick mặc định | Label option pin nguyên văn: "Có, gửi cho mình email về các sự kiện sắp tới của Book!e". Nguồn nuôi tab `Subscribers` trong registry — chỉ ai tick mới vào danh sách nhận tin, `nguon=form-dangky`. Mapping defensive: `nhan_tin_moi` = (mảng response KHÔNG rỗng) — không so sánh chuỗi, label bị reword không lặng lẽ tắt consent |

Nguồn các trường: distill từ những form đọc được trong knowledge base (Book!e Exchange 2017: họ tên/email/số buổi đã tham gia; check-in BD/BT: họ tên + email; Gala 2023–2024: name/email/phone/loại thành viên) + nhu cầu vận hành trong playbook. Không thêm câu hỏi dài dòng — form đăng ký phải điền xong dưới 1 phút.

## Settings của form gốc

`setupTemplateForm()` tự set 3/4 mục (✅); chỉ mục ảnh header còn làm tay:

- ✅ Thu thập email: **Responder input** (không bắt đăng nhập, không giới hạn 1 phản hồi — bản ghi trùng xử lý khi tổng hợp, đúng thực tế vận hành cũ; account chưa hỗ trợ set bằng code → script log nhắc chỉnh tay)
- [ ] Ảnh header: banner brand Bookie (lấy từ `shared/branding/`, một lần — mọi form clone tự kế thừa)
- ✅ Confirmation message: placeholder — automation ghi đè mỗi event (cảm ơn + ngày giờ + địa điểm + calendar link)
- ✅ KHÔNG bật "Limit to 1 response" (đòi đăng nhập Google)

## Checklist dựng form gốc (một lần, account bookie.community@gmail.com)

Phần dựng trường đã tự động: hàm `setupTemplateForm()` trong [`form-dang-ky.gs`](../../../shared/event-automation/apps-script/form-dang-ky.gs) tự tạo form `Format Form đăng ký BD (2026)` (nối tiếp pattern "Format Form đky BT (mới)" 2024) với 8 trường (#1–#8) + settings đúng spec này, chuyển vào `Templates/`, log ra `TEMPLATE_ID` — chạy trong bước 4 của [deploy guide](../../../shared/event-automation/README.md). Trường #9 (consent checkbox) CHƯA có trong code — build ở slice S4b, xem [`shared/event-automation/ROADMAP.md`](../../../shared/event-automation/ROADMAP.md); sửa `setupTemplateForm()` + form gốc + file này cùng một commit. Còn lại làm tay:

- [ ] Kiểm Settings ▸ "Thu thập địa chỉ email" = **Responder input** (script thử set bằng code, không đảm bảo trên mọi account — xem nhắc trong Execution log)
- [ ] Chỉnh theme + ảnh header brand (từ `shared/branding/`) — FormApp không set được theme
- [ ] Submit thử 1 response → xoá response test
- [ ] Điền `TEMPLATE_ID` (từ Execution log) vào Script Properties của Apps Script

> Đổi câu hỏi về sau = sửa form gốc + sửa spec này + sửa `setupTemplateForm()` cùng một commit.

---

> Nguồn: chưng cất từ [BD playbook](../../../knowledge/03-playbook/book-discussion.md) (§3 — mục "Chuẩn bị Form: đăng ký"), [BT playbook](../../../knowledge/03-playbook/bookie-talk.md) (§5, §10 — rủi ro template hóa), form analog trong [book-exchange](../../../knowledge/03-playbook/book-exchange.md) §3 và [gala](../../../knowledge/03-playbook/gala.md) §8.
