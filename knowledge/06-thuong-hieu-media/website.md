---
title: "Website bookiecommunity.com"
sources: 0
updated: 2026-07-13
---
# Website bookiecommunity.com

> ⚠ Provenance: ghi nhận TRỰC TIẾP 2026-07 (quan sát site + DNS + quyết định vận hành),
> KHÔNG thuộc snapshot Drive 2026-07-11 — không có mặt trong `00-inventory/inventory.json`.
> Mảng website chưa từng được văn bản hoá trong Drive.

## Hiện trạng (07/2026)

- **Nền tảng**: Google Sites (bản mới), quản lý qua account tổ chức.
- **Domain**: `www.bookiecommunity.com` — đăng ký tại **Cloudflare Registrar**,
  nameservers Cloudflare, hạn gia hạn **02/2027**; CNAME trỏ `ghs.googlehosted.com`
  (mapping Google Sites chuẩn).
- **Cấu trúc trang**: Home · About BOOKIE · Admin Team · Bookier · Event · Blog.
  (Bản quy hoạch sitemap 2023 — phần lớn chưa triển khai — xem
  [chi-muc-thuong-hieu.md §3](chi-muc-thuong-hieu.md).)
  - Home: giới thiệu cộng đồng, tìm Bookier, 4 hoạt động chính (Talk / Discussion /
    Challenges / Mentoring).
  - Event: giới thiệu 5 loại hình (BT, BD, Meet-up, Workshop, Gala) + địa điểm quen
    (25A Cao Thắng, Q.3); mục "Các sự kiện đã tổ chức" là heading **rỗng**.
  - Blog: **rỗng** (placeholder, chưa có bài nào).
  - Không có embed (Calendar/Docs/Drive) nào trên site.
- **Bảo trì per-event** (flow cũ): mỗi event vào editor Google Sites sửa tay — thực tế
  ít khi được làm (Blog + archive rỗng là bằng chứng), site chủ yếu đóng vai brochure;
  kênh sự kiện thật là fanpage + form.

## Ràng buộc kỹ thuật quan trọng

**Google Sites (bản mới) KHÔNG có content API** — API cũ chỉ đọc/ghi classic Sites
(đã deprecated); tới 07/2026 Google vẫn chưa phát hành API cho bản mới. Nghĩa là
không thể tự động sửa nội dung trang bằng code; đường tự động hoá duy nhất trên Sites
là **embed nguồn Google-native tự cập nhật** (Calendar / Docs / Slides / Drive folder).

## Quyết định (07/2026)

1. **Migrate khỏi Google Sites → static site (Astro) + Cloudflare Pages**, code nằm
   trong repo Bookie — quyết định bởi co-founder kỹ thuật (người maintain duy nhất):
   - Sites là ngõ cụt automation; site-as-code thì mọi cập nhật per-event tự sinh từ
     `event.json` (cùng nguồn dữ liệu với form/QR/poster).
   - Nội dung hiện tại rất mỏng (5 trang brochure, blog rỗng) → chi phí port thấp.
   - Domain đã nằm sẵn trên Cloudflare → cutover chỉ là đổi CNAME; site cũ giữ ở URL
     `sites.google.com` làm archive.
   - Design system trong repo (`shared/design-system/tokens/`) tái dùng cho web →
     đồng bộ nhận diện poster ↔ website.
2. **Interim (trước khi migrate xong)**: sự kiện được tạo tự động lên calendar
   **"Bookie Events"** (Apps Script `shared/event-automation/` — property `CALENDAR_ID`);
   có thể embed calendar này vào trang Event của Sites hiện tại (một lần, tự cập nhật).

## Việc per-event sau khi hệ mới chạy

Không còn thao tác tay trên website: `/event-form` ghi `event.json` + tạo calendar
event → site build tự render "Sự kiện sắp tới" / archive từ chính `event.json` +
poster đã render. Chi tiết triển khai: xem repo (`shared/event-automation/README.md`
và slice website khi thực hiện).
