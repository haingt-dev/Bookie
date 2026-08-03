# Bookie Website — spec slice S6

> Doc này là spec, chưa có code. Khi build, code Astro nằm CẠNH file này trong `site/`
> (vd `src/`, `astro.config.mjs`, `package.json`) — doc này trở thành README của slice site.

## Vì sao migrate

Google Sites (bản mới) không có content API → không tự động hoá được, site chủ yếu
đóng vai brochure chết (blog/archive rỗng). Quyết định + bối cảnh đầy đủ:
[`knowledge/06-thuong-hieu-media/website.md`](../knowledge/06-thuong-hieu-media/website.md).

## Hạ tầng

- **Hosting**: Cloudflare Pages, project trỏ vào repo Bookie, **root directory = `site/`**.
  Build command = lệnh build Astro chuẩn (`astro build` / `npm run build`), output `dist/`.
- **Domain cutover**: đổi CNAME `www.bookiecommunity.com` từ `ghs.googlehosted.com`
  (Google Sites) sang target Cloudflare Pages. Site Google Sites cũ **giữ nguyên**, không
  xoá — đóng vai archive, truy cập qua URL `sites.google.com` gốc (không còn gắn domain
  chính).
- **Rollback**: nếu site mới lỗi sau cutover, đổi CNAME **về** `ghs.googlehosted.com` —
  vì Sites cũ không bị xoá nên rollback là revert DNS thuần, không cần khôi phục nội dung.
- **Daily deploy hook**: Cloudflare Pages hỗ trợ deploy hook (webhook URL) + Cloudflare có
  Cron Triggers (free tier) gọi hook đó theo lịch — 1 cron/ngày (ví dụ 00:05 VN) trigger
  rebuild, để trạng thái "sắp diễn ra" → "đã diễn ra" của event tự lật theo ngày hiện tại
  mà **không cần commit thủ công**. Không nằm trong repo Bookie (infra Cloudflare riêng),
  ghi chú vị trí cấu hình khi setup thật.

## Data flow

- **Content collection `events`**: Astro content collection dùng **glob loader** đọc
  `../projects/*/assets/event.json` (đường dẫn ra ngoài `site/`, vào các sub-project
  event-type trong repo) + validate bằng **zod schema**. Schema sai (thiếu field bắt buộc,
  sai kiểu) = **build FAIL** — chủ ý: đây đúng loại lỗi "copy-paste quên cập nhật field"
  cần giết sớm ở build-time thay vì lộ ra trang live.
- **VERIFY khi build thật (S6)**: glob loader của Astro content collection có đọc được
  path ngoài site root (`../projects/...`) hay bị giới hạn trong `src/content/` không —
  chưa verify được ở giai đoạn spec này.
  - **Fallback nếu không đọc được ngoài root**: script prebuild ~20 dòng (Node, chạy
    trước `astro build`) copy toàn bộ `projects/*/assets/event.json` vào
    `site/src/content/events/<ma_su_kien>.json` trước khi Astro build.
- **Field mới bắt buộc trong `event.json`**: `ma_su_kien` (= slug event, vd `BT31`) —
  thêm vào schema chung `shared/design-system/README.md` (dùng chung với poster/cover/mail),
  route `/su-kien/<ma_su_kien>` và `/recap/<ma_su_kien>` dùng field này làm slug.
- **KHÔNG BAO GIỜ build-time fetch từ Google Sheet.** Site chỉ đọc `event.json` đã commit
  trong repo — PII không thể rò ra web **by construction**, vì Sheet (chứa data cá nhân
  thật) không nằm trong đường đi build.

## Page inventory

| Route | Nội dung |
|---|---|
| `/` | Giới thiệu ngắn + card sự kiện sắp tới (từ collection `events`) + CTA subscribe |
| `/ve-bookie` | Giới thiệu cộng đồng (nội dung tĩnh, port từ Google Sites hiện tại) |
| `/su-kien` | Danh sách event: "sắp diễn ra" (upcoming) + "đã diễn ra" (archive), lật theo ngày hiện tại lúc build |
| `/su-kien/<ma_su_kien>` | Chi tiết 1 event: info từ `event.json` + nút đăng ký (`dang_ky` → forms.gle) + poster |
| `/recap/<ma_su_kien>` | Recap sau event: số liệu tổng + ảnh + quote ẩn danh (xem contract bên dưới) |
| `/dang-ky-nhan-tin` | Form subscribe nhận tin — **điểm tương tác DUY NHẤT trên site** |
| `/cam-on-dang-ky` | Trang success sau subscribe — cũng là đích redirect cho luồng no-JS |
| `/huy-nhan-tin` | Trang confirm unsubscribe: đọc `e` (email) + `t` (token) từ query string, hiển thị 1 nút bấm xác nhận (không tự action khi load — chống link-scanner của mail client prefetch link) |
| `/du-lieu-ca-nhan` | Privacy note ngắn tiếng Việt: thu thập gì, dùng để làm gì, cách unsubscribe, cách yêu cầu xoá — bắt buộc khi vận hành mailing list |

## Contract front-end subscribe / unsubscribe

- **Request**: `fetch` `POST`, `Content-Type: text/plain` **chở JSON string** (không phải
  `application/json`). Lý do: đây là điều kiện để browser coi là "simple request" — không
  kích hoạt CORS preflight (`OPTIONS`), vì Apps Script web app **không trả lời `OPTIONS`**.
  Dùng `application/json` thật sẽ **FAIL** (preflight bị treo/lỗi) — ghi rõ ở đây để không
  bị phát hiện lại từ đầu khi build.
- **Payload**:
  ```json
  {
    "email": "...",
    "ho_ten": "...",        // optional
    "website": "",           // honeypot — input ẩn CSS, để trống là hợp lệ
    "ts_render": 0,           // timestamp lúc form render, dùng tính time-to-fill
    "cf_token": ""            // optional — chừa sẵn cho Cloudflare Turnstile (bật sau, không đổi page)
  }
  ```
- **Response**: JSON đọc được ở phía client — endpoint Apps Script web app redirect qua
  domain `*.googleusercontent.com` có header `Access-Control-Allow-Origin: *`, nên `fetch`
  đọc response bình thường dù cross-origin.
- **Fallback no-JS**: `<form method="POST">` submit thẳng vào web app exec URL (không qua
  `fetch`). `doPost` phía Apps Script phát hiện request dạng form-post thường và trả về
  `HtmlService` chứa `<meta http-equiv="refresh">` redirect về `/cam-on-dang-ky`.
- **Web app exec URL**: đặt **1 chỗ duy nhất** — `site/src/config.ts` — không phải secret
  (URL Apps Script web app không cấp quyền gì nếu không có payload hợp lệ). Ngược lại
  **SECRET (`UNSUB_SECRET`, ký token HMAC) không bao giờ xuất hiện trong `site/`** — chỉ
  sống trong Script Properties phía Apps Script.
- **Cảnh báo vận hành**: cập nhật code Apps Script đúng cách = **đổi version của deployment
  hiện có** (Manage deployments → edit → New version) → URL exec **giữ nguyên**. Chỉ khi tạo
  deployment MỚI ("New deployment") thì URL exec đổi → phải cập nhật ĐÚNG 2 chỗ cùng lúc:
  `site/src/config.ts` (fetch target front-end) + `.env` key `BOOKIE_FORM_WEBAPP_URL`
  (create-form.mjs), nếu không site sẽ POST vào endpoint chết.

## Recap authoring contract

- Vị trí: `site/src/content/recaps/<ma_su_kien>.md`.
- **Frontmatter CHỈ chứa số liệu tổng** — không có tên/contact cá nhân:
  - `so_dang_ky` (số đăng ký), `so_tham_du` (số check-in), `diem_hai_long_tb` (điểm hài
    lòng trung bình từ feedback), `photo_credits` (CHỈ role label, vd "ban MarCom", "CTV
    ảnh" — hoặc tên đã công bố công khai theo whitelist PII-POLICY; cấm mọi tên/handle cá
    nhân khác — xem `knowledge/_meta/PII-POLICY.md`).
- Ảnh recap: `site/public/su-kien/<ma_su_kien>/` (đường dẫn public trong Astro).
- **Quote feedback trích trong recap phải ẩn danh** — không gắn tên người nói, đúng
  nguyên tắc `Feedback` tab trong registry (ẩn danh là load-bearing, không phải tuỳ chọn).
- **Commit = human gate**: recap không tự sinh & tự publish — người viết/duyệt nội dung
  rồi mới commit; đây là điểm chặn con người duy nhất trong luồng recap.
- Event trước 2026 (không có `event.json`/pipeline mới): recap viết tay, vẫn nằm chung
  collection `recaps` như event mới, chỉ khác là không có `/su-kien/<ma>` tương ứng.

## Design system

- Site import **`shared/design-system/tokens/tokens.css`** làm nguồn brand màu/font/spacing
  duy nhất — copy-paste bị cấm; token sửa 1 nơi, poster/cover/mail/web đồng bộ theo.
