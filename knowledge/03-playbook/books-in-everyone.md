---
title: "Playbook — BOOKs in Everyone"
sources: 1
updated: 2026-07-11
---
# Playbook — BOOKs in Everyone

Chương trình **BOOKs in Everyone** (2024) của Bookie là chương trình xây dựng và vận hành một **tủ sách cộng đồng** (thư viện sách chia sẻ). Nguồn duy nhất thu thập được cho nhóm này là sheet danh mục thư viện (`BOOKIE LIBRARY`), phản ánh cơ chế số hóa/quản lý đầu sách vận hành nội bộ.

⚠ Nguồn hiện có chỉ bao trùm phần "danh mục thư viện" — chưa có tài liệu về quy trình mượn/trả, tiêu chí chọn sách, cách tổ chức sự kiện, hay timeline chương trình. Cần bổ sung nếu tìm được thêm tài liệu khác thuộc chương trình này.

## Cơ chế mã hóa & quản lý đầu sách

Playbook vận hành thư viện dùng một schema cột chuẩn để tra cứu nhanh và theo dõi tình trạng lưu hành từng đầu sách:

| Cột | Mục đích | Quy ước |
|---|---|---|
| ID / ID_Raw | Mã định danh duy nhất mỗi đầu sách | Ghép chữ cái đầu tiêu đề + mã tác giả (vd `ĐNT_DC` = *Đắc Nhân Tâm*, tác giả Dale Carnegie) |
| TIÊU ĐỀ / TITLE ID | Tên sách tiếng Việt + mã rút gọn | |
| TIÊU ĐỀ GỐC | Tên gốc (Anh/Pháp/Nhật...) | Chỉ điền nếu là sách dịch |
| TÁC GIẢ / ID - TÁC GIẢ | Tên tác giả + mã tác giả | Dùng để nhóm nhiều sách cùng tác giả (vd Nguyễn Ngọc Tư = NNT, Guillaume Musso = GM) |
| THỂ LOẠI | Nhãn phân loại | Fiction, Personal Development, Career & Success, Communication Skills, Management & Leadership, Mindfulness & Happiness, Motivation & Inspiration, Economics, Money & Investments, Health & Nutrition, Psychology, Education, Entrepreneurship, Productivity, Corporate Culture, Fantasy, Book Types... (phần lớn dòng để trống) |
| NGÔN NGỮ | Ngôn ngữ ấn bản | Chủ yếu Tiếng Việt, một số English |
| TÓM TẮT NHANH | Tóm tắt ngắn | Trống ở hầu hết các dòng (chưa điền) |
| NGƯỜI ĐANG GIỮ / NGƯỜI ĐÓNG GÓP | Vai trò quản thủ thư viện | Nội bộ — đã lược bỏ danh tính, xem Ghi chú PII |
| TRẠNG THÁI | Tình trạng lưu hành | Chủ yếu "Available"; có thể "Occupied" (đang mượn), "N/A", hoặc "-" (chưa cập nhật) |
| CẬP NHẬT | Ngày cập nhật dòng | |
| GHI CHÚ | Ghi chú tự do | Trống toàn bộ các dòng trong đợt nhập liệu đầu |

**Nguyên tắc playbook rút ra**: mỗi đầu sách có mã ID duy nhất, ghép từ chữ cái đầu tiêu đề + mã tác giả → cho phép tra cứu nhanh và theo dõi ai đang giữ sách nào mà không cần hệ thống phần mềm riêng — chỉ cần một Google Sheet có schema nhất quán.

## Số liệu & facts (tính đến đợt nhập liệu 10/09/2024)

- Tổng số đầu sách trong danh mục: khoảng **150 đầu sách**
- Ngôn ngữ: đa số Tiếng Việt, thiểu số English
- Trạng thái lưu hành: ~148 "Available", 1 "Occupied", 1 "N/A"
- Tác giả xuất hiện nhiều lần trong tủ sách: Nguyễn Ngọc Tư, Guillaume Musso, Nguyễn Hiến Lê, Jules Verne, The Sunday Times (series kỹ năng quản lý), Napoleon Hill, Eckart Tolle
- Thể loại phổ biến nhất (khi có gắn nhãn): Fiction, Personal Development, Motivation & Inspiration, Management & Leadership, Career & Success, Mindfulness & Happiness
- Ngày nhập liệu chủ đạo của toàn bộ danh mục: 10/09/2024 (một đợt nhập liệu ban đầu, không rải rác theo thời gian)

## Ghi chú PII

Tên người thật ở cột "Người đang giữ" / "Người đóng góp" (xuất hiện lặp lại xuyên suốt danh mục, thực chất là một cá nhân duy nhất phụ trách thư viện) đã được thay bằng vai trò **"quản thủ thư viện"**. Tên tác giả sách được giữ nguyên vì là thông tin xuất bản công khai.

## Nguồn

- [BOOKIE LIBRARY](https://docs.google.com/spreadsheets/d/13OpPWFOPksjEeC5GcMYEFJ_U3TPJJbmfPQgVpDGZppg/edit?usp=drivesdk) — Bookie/BOOKs in Everyone/BOOKIE LIBRARY
