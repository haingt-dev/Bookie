# Bookie Knowledge Base — Tri thức tổ chức

Toàn bộ tri thức của **Book!e Inspires Everyone** (cộng đồng đọc sách, 9+ năm hoạt động) được trích xuất từ Google Drive của tổ chức, tổng hợp và làm sạch thông tin cá nhân trước khi đưa vào repo public.

> **Snapshot**: crawl Drive ngày **2026-07-11** — 3 thư mục gốc (Ad - Admin, Bookie, Old), 2.417 mục, 334 tài liệu được đọc toàn văn, 1.774 file media bỏ qua (chỉ ghi nhận vị trí).
> **PII**: đã loại bỏ theo chính sách trong [`_meta/PII-POLICY.md`](_meta/PII-POLICY.md). Truy ngược tài liệu gốc qua [`_meta/SOURCES.md`](_meta/SOURCES.md) (cần quyền truy cập Drive).

## Mục lục

### 00 — Inventory (bản đồ Drive)
- [Cây thư mục Drive](00-inventory/cay-thu-muc-drive.md) — toàn bộ cấu trúc 3 thư mục gốc
- [inventory.json](00-inventory/inventory.json) — bản ghi máy-đọc-được: 2.417 mục kèm link, trạng thái xử lý
- [Chỉ mục media bỏ qua](00-inventory/chi-muc-media-bo-qua.md) — vị trí + số lượng ảnh/video (tên folder = nhật ký sự kiện)

### 01 — Lịch sử
- [Dòng thời gian 2015→2025](01-lich-su/dong-thoi-gian.md) — master chronology: các thời kỳ, bảng sự kiện theo năm, chuỗi BT/BD/Gala

### 02 — Cơ cấu tổ chức
- [Giới thiệu Bookie](02-co-cau-to-chuc/gioi-thieu-bookie.md) — Bookie là gì, sứ mệnh, kênh chính thức
- [Phòng ban qua các năm](02-co-cau-to-chuc/phong-ban-qua-cac-nam.md) — BCN 3 ban (2016) → Reform (2020) → Op/MarCom/PD/L&D (2023-24)

### 03 — Playbook hoạt động
- [Book!e Discussion (BD)](03-playbook/book-discussion.md) — thảo luận sách: mô hình 3 thế hệ, quy trình, template, lịch sử đầy đủ
- [Book!e Talk (BT)](03-playbook/bookie-talk.md) — talk theo chủ đề: BT4→BT30, agenda, thẻ màu, checklist
- [Book!e Exchange & Thư viện](03-playbook/book-exchange.md) — trao đổi sách 2017-2018
- [Bookie Gala](03-playbook/gala.md) — sự kiện thường niên 2023/2024
- [Bookie Meetup](03-playbook/bookie-meetup.md) — họp mặt cộng đồng 2023/2024
- [BOOKIER (thành viên)](03-playbook/bookier.md) — hệ thống thành viên 4 cấp độ
- [CTV — Cộng tác viên](03-playbook/ctv-cong-tac-vien.md) — tuyển dụng & vận hành CTV, JD từng team
- [Learning & Development](03-playbook/dao-tao-ld.md) — đào tạo, lộ trình năng lực, hệ proposal
- [MarCom & Content](03-playbook/marcom-noi-dung.md) — truyền thông: plan FB, cấu trúc bài, quản lý content
- [Quy trình vận hành chung](03-playbook/quy-trinh-van-hanh.md) — master workflow, annual calendar, tools
- [Sinh hoạt T&D (legacy)](03-playbook/sinh-hoat-t-and-d.md) — mô hình sinh hoạt định kỳ thời kỳ đầu
- [Workshop & sự kiện khác](03-playbook/workshop-su-kien-khac.md) — WS đọc sách thời digital, dự án theo chủ đề
- [BOOKs in Everyone](03-playbook/books-in-everyone.md) — thư viện sách cộng đồng

### 04 — Kế hoạch theo năm
- [2016-2018](04-ke-hoach-nam/2016-2018.md) · [2023](04-ke-hoach-nam/2023.md) · [2024](04-ke-hoach-nam/2024.md)
- [Bookie Reform (2020-2023)](04-ke-hoach-nam/bookie-reform.md) — chiến lược tái cấu trúc

### 05 — Biên bản họp
- [Tổng hợp BOM-MoM & tri thức quản trị](05-bien-ban-hop/tong-hop.md) — quyết định lớn, HANDBOOKIE, kinh nghiệm

### 06 — Thương hiệu & media
- [Chỉ mục thương hiệu](06-thuong-hieu-media/chi-muc-thuong-hieu.md) — brand guidelines, web, kho media (xem thêm `shared/branding/`)

### 07 — Đối tác
- [Đối tác & bảo trợ](07-doi-tac/doi-tac-va-bao-tro.md) — stakeholder register, partnerships, testimonials

### 08 — Tham khảo
- [Tài liệu bên ngoài](08-tham-khao/tai-lieu-tham-khao.md) — docs không do Bookie tạo, lưu để tham chiếu

## Quy ước cập nhật

- Đây là **snapshot** — Drive tiếp tục thay đổi; muốn refresh, crawl lại và diff theo `inventory.json` (trường `modified`).
- File nào tổng hợp từ nguồn bị cắt (sheet quá lớn) có đánh dấu `⚠ nguồn không đầy đủ` tại mục liên quan.
- Google Forms (82 form) không đọc được nội dung qua API — chỉ có tên trong inventory.
