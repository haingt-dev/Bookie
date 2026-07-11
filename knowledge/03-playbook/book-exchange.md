---
title: "Playbook — Book!e Exchange & Thư viện"
sources: 5
updated: 2026-07-11
---
# Playbook — Book!e Exchange & Thư viện

Tổng hợp mô hình chương trình **Book Exchange** của Bookie, vận hành trong giai đoạn 2017-2018: trao đổi sách phi tập trung giữa các thành viên, tổ chức theo địa bàn (tủ sách khu vực), và một đợt khảo sát sở thích đọc để định hướng chọn sách.

## 1. Mô hình vận hành

Book Exchange là mạng lưới trao đổi sách **phi tập trung**: mỗi thành viên (hoặc mỗi điểm/khu vực) tự quản một "tủ sách" — khai báo sách mình có thể cho mượn và sách mình muốn đọc, từ đó match nhu cầu giữa các Bookier với nhau.

Cách nhân rộng: dùng **1 template chung** ("Thư viện Bookie"), sau đó nhân bản (copy) template này cho từng điểm/khu vực cụ thể. Đã ghi nhận 2 tủ sách khu vực:

- **Tủ sách NVC**
- **Tủ sách Linh Trung**

Cả 2 bản sao khu vực đều giữ nguyên cấu trúc gốc, không chỉnh sửa field — xác nhận đây là quy trình nhân rộng chuẩn hoá (1 template → N điểm theo địa bàn).

## 2. Template "Tủ sách" — cấu trúc chuẩn

Dùng cho cả bản gốc và các bản khu vực (NVC, Linh Trung). Gồm 2 phần:

**Phần 1 — Thông tin liên hệ chủ tủ sách** (block "Tủ sách của ___"):
- Họ và tên
- Số điện thoại
- Email
- Facebook

**Phần 2 — Danh sách sách**, chia 2 cột song song:

| Tựa sách hiện có (có thể cho mượn) | Tựa sách mong muốn đọc |
|---|---|
| STT | STT |
| Tên sách | Tên sách |
| Tác giả | Tác giả |
| Tình trạng ("Đã cho mượn" / "Cho mượn được") | — |
| Ghi chú | — |
| Review | — |

Ghi chú: cả 3 file template thu được (gốc + NVC + Linh Trung) đều ở dạng **trống**, chưa có dữ liệu thực tế đã điền — chỉ phản ánh cấu trúc mẫu, không phản ánh nội dung tủ sách thật.

## 3. Quy trình đăng ký tham gia

Chương trình thu nhận thành viên qua **form đăng ký**, kết quả lưu tại sheet "Đăng ký tham gia chương trình Book Exchange (Câu trả lời)".

**Trường thông tin form:**
- Dấu thời gian
- Địa chỉ email
- Họ và tên
- Ngày sinh
- Số buổi thảo luận sách đã tham gia (tự khai, dạng text tự do)
- Email dùng để đăng ký

**Số liệu đợt đăng ký (2017):**
- 14 phản hồi, trong khung thời gian 30/10/2017 – 16/11/2017
- Phân bố lịch sử tham gia: đa số khai "1 buổi" hoặc "chưa tham gia buổi thảo luận sách nào"; một số ít khai "hơn 2 buổi"
- Đáng chú ý: có người khai "chưa tham gia buổi nào" nhưng vẫn đăng ký — cho thấy chương trình thu hút được cả người mới, chưa quen sinh hoạt cộng đồng
- Có trường hợp tự nhận là "thành viên Bookier" nên bỏ qua câu hỏi lịch sử tham gia (giả định đã được biết đến)

→ Insight vận hành: Book Exchange là điểm chạm phù hợp cho **người mới** — không yêu cầu lịch sử tham gia sâu mới được đăng ký.

## 4. Khảo sát chọn sách (dữ liệu lịch sử — OUTDATED)

Sheet "**(Outdated) Bookie's Book List**" — đánh dấu Outdated, không còn dùng để ra quyết định hiện tại, nhưng giữ lại vì phản ánh sở thích đọc lịch sử của cộng đồng giai đoạn 2017-2018.

**Cơ chế khảo sát:** mỗi thành viên chấm điểm **toàn bộ** danh mục theo thang **0-5 điểm/cuốn** (càng cao càng muốn đọc) — bắt buộc chấm hết, không được bỏ sót, để đảm bảo dữ liệu so sánh công bằng giữa các đầu sách.

**Quy mô:**
- 78 đầu sách trong danh mục khảo sát
- Khoảng 15-17 người tham gia chấm điểm
- 4 thể loại chính: Kiến thức/làm giàu nội tâm · Văn học · Phương pháp đọc-học-kỹ năng · Thay đổi tư tưởng/tạo động lực

**Top sách được mong muốn đọc nhất (tổng điểm cao nhất):**

| Sách | Tác giả | Điểm |
|---|---|---|
| Khuyến học | Fukuzawa Yukichi | 57 |
| Súng, vi trùng và thép | Jared Diamond | 56 |
| Phương pháp luận sáng tạo và đổi mới | Phan Dũng | 53 |
| Dù của bạn màu gì? | Richard N. Bolles | 52 |
| Phương pháp đọc sách hiệu quả | Mortimer J. Adler | 52 |
| 451 độ F | Ray Bradbury | 51 |
| Làm như chơi | Minh Niệm | 50 |
| Lolita | Vladimir Nabokov | 50 |

Tác giả Việt xuất hiện nhiều nhất trong danh mục: **Nguyễn Nhật Ánh** (5 tựa — Con chó nhỏ mang giỏ hoa hồng, Cho tôi xin một vé đi tuổi thơ, Tôi thấy hoa vàng trên cỏ xanh, Quán gò đi lên, Đảo mộng mơ).

## 5. Ghi chú áp dụng

- Toàn bộ tư liệu thuộc giai đoạn 2017-2018 — mang tính lịch sử/tham khảo mô hình, không phải cấu hình đang chạy.
- Template tủ sách là tài sản tái sử dụng được: có thể lấy lại làm khung cho mô hình trao đổi sách nếu tái khởi động.
- Khảo sát chọn sách (mục 4) minh hoạ một cơ chế "vote toàn danh mục, không bỏ sót" — có thể tham khảo cho các đợt khảo sát chọn sách tương lai, dù dữ liệu cụ thể đã outdated.

## Nguồn

- [Thư viện Bookie](https://docs.google.com/spreadsheets/d/1dIcp1YGqMF-S47VrdwVjDImnr3oQFlDP4T-hgmrt3Kw/edit?usp=drivesdk) — Old/2017-2018/Book Exchange/Thư viện Bookie
- [Book!e Exchange Library - Linh Trung](https://docs.google.com/spreadsheets/d/1DIEGyjl8k0mlXAEJQMaRCriIVi4mJTx_y2W39Q9u_Ac/edit?usp=drivesdk) — Old/2017-2018/Book Exchange/Book!e Exchange Library - Linh Trung
- [Book!e Exchange Library - NVC](https://docs.google.com/spreadsheets/d/1FWOZMP5qi0mURlDMAMsvfGclNAFJRuylY0ss9UirKlw/edit?usp=drivesdk) — Old/2017-2018/Book Exchange/Book!e Exchange Library - NVC
- [(Outdated) Bookie's Book List](https://docs.google.com/spreadsheets/d/1GHDcmclE7t_HXT9YCBXAVIGlCp6xvbL6yuvCBxmKqwc/edit?usp=drivesdk) — Old/2017-2018/Book Exchange/(Outdated) Bookie's Book List
- [Đăng ký tham gia chương trình Book Exchange (Câu trả lời)](https://docs.google.com/spreadsheets/d/1IYRHugVFR1FGoi0cvbukGIPd33LLg6bMM-rgE1NlauM/edit?usp=drivesdk) — Old/2017-2018/Book Exchange/Đăng ký tham gia chương trình Book Exchange (Câu trả lời)
