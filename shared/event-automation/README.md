# Bookie Event Automation — form đăng ký + QR tự động

Tự động hoá khâu thủ công nhiều lỗi nhất mỗi event: clone form đăng ký cũ → sửa nội dung → tạo QR → gắn vào poster/bài đăng. Playbook ghi nhận đây là ổ lỗi "copy quên cập nhật → sai ngày/sai chủ đề" — hệ này diệt tận gốc: **nội dung per-event chỉ được ghi bởi script từ `event.json`, không sửa tay**.

```
[event.json] ──POST──> Apps Script Web App (account bookie.community@gmail.com)
                        clone form gốc → sửa title/mô tả/confirmation
                        → publish guard → shortenFormUrl
                        → event trên calendar "Bookie Events" (nếu có CALENDAR_ID)
             <──JSON── {form_id, edit_url, published_url, short_url, folder_url,
                        calendar_event_id?, calendar_error?}
[create-form.mjs] ghi ngược event.json (dang_ky = forms.gle, calendar_link…)
                  + QR: qr-dang-ky.svg (poster) + qr-dang-ky.png (slide/in)
[/event-graphics] render poster kèm QR
```

Skill **`/event-form`** chạy trọn flow. Form gốc (bộ câu hỏi chuẩn) đặc tả tại
[`projects/bd-2026/plan/bieu-mau-dang-ky.md`](../../projects/bd-2026/plan/bieu-mau-dang-ky.md).

Lộ trình mở rộng (mail scheduler T-1/T+2, check-in, feedback form, recap) + quyết định
kiến trúc (vì sao không n8n): **[ROADMAP.md](ROADMAP.md)** — build đợt SG ~08/2026.

## Dùng nhanh

```bash
cd shared/event-automation
node create-form.mjs --new-proposal "BT31"            # mở kỳ mới: copy Doc proposal cho host điền
node create-form.mjs --data ../../projects/<event>/assets/event.json
node create-form.mjs --data <event.json> --dry-run    # xem payload, không gọi
node create-form.mjs --data <event.json> --qr-only    # chỉ sinh lại QR từ link đã có
node create-form.mjs --data <event.json> --force      # tạo form MỚI dù event.json đã có link
```

`--new-proposal` copy `[Template] Proposal BT (2026)` (Templates/) thành `Proposal - <kỳ>`
trong `Bookie 2026/Proposals/` rồi trả link gửi host — kỳ đã có proposal thì trả bản cũ,
không copy trùng. Host điền xong → xử lý theo `projects/bt-2026/plan/xu-ly-proposal.md`.

Field script đọc từ `event.json`: `ten_sach✓ loai_event✓ ngay_gio✓ dia_diem✓ chu_de dien_gia` + `ngay_gio_iso: {"start":"2026-07-27T09:00","end":"2026-07-27T11:30"}` (để build link "thêm vào Google Calendar" — thuần URL, không cần API — và giờ event trên calendar "Bookie Events"). Field script **ghi ngược**: `dang_ky` (forms.gle), `form_edit_url`, `form_published_url`, `calendar_link`, `calendar_event_id` (nếu endpoint có CALENDAR_ID), `qr`.

Chống tạo form trùng: `event.json` đã có `form_published_url` → script từ chối chạy lại nếu không có `--force`. Khi `--force`, id calendar event cũ (nếu có) được gửi kèm để endpoint xoá trước khi tạo lại — không để trùng lịch trên "Bookie Events". (Form cũ thì KHÔNG tự xoá — dọn tay trong Drive nếu cần.)

## Deploy một lần (account bookie.community@gmail.com, ~15 phút)

Chuẩn bị trong Drive (Shared Drive, folder `Bookie 2026/`):

1. ~~Tạo cây `Bookie 2026/{Templates, Events, Admin}`~~ — ĐÃ TẠO (2026-07-12, qua Drive MCP):
   - `Bookie 2026/` — [197oWhpcqomzElXLPB18MyXSwIIbsInfq](https://drive.google.com/drive/folders/197oWhpcqomzElXLPB18MyXSwIIbsInfq)
   - `Templates/` — [1jvR--DTWtH7s3x7o9amgMqI88_M_pF6U](https://drive.google.com/drive/folders/1jvR--DTWtH7s3x7o9amgMqI88_M_pF6U)
   - `Events/` — `EVENTS_FOLDER_ID` = `1vtROHBvwA-csQRcJTkjV1Zu4lqQ7pOeJ`
   - `Admin/` — [1BFOu8DzJ9leXtR79kRvkNjSeoqeWVjXU](https://drive.google.com/drive/folders/1BFOu8DzJ9leXtR79kRvkNjSeoqeWVjXU)
   - `Proposals/` — `PROPOSALS_FOLDER_ID` = `163wW985cRrxekYt6FA5pCERKKWOZbmLs` (tạo 2026-07-13)
Deploy Apps Script:

2. Đăng nhập account bookie → [script.google.com](https://script.google.com) → **New project**, đặt tên `bookie-form-dang-ky`.
3. Xoá code mặc định, paste toàn bộ [`apps-script/form-dang-ky.gs`](apps-script/form-dang-ky.gs) → Save.
4. **Dựng form gốc bằng code**: trên thanh công cụ chọn hàm `setupTemplateForm` → **Run** → cấp quyền (màn hình "unverified app" là bình thường — app của chính mình) → xem **Execution log** lấy `TEMPLATE_ID`. Hàm tự dựng đủ 8 trường theo spec [`bieu-mau-dang-ky.md`](../../projects/bd-2026/plan/bieu-mau-dang-ky.md) và chuyển form vào `Templates/`. Việc còn lại bằng UI (~2 phút): mở form → chỉnh **theme + ảnh header brand** (lấy từ `shared/branding/` — FormApp không set được theme bằng code) → submit thử 1 response rồi xoá.
5. **Tạo calendar "Bookie Events"** (tùy chọn nhưng nên làm): chọn hàm `setupEventsCalendar` → **Run** → lấy `CALENDAR_ID` từ log. Muốn embed lịch lên website: Google Calendar → Settings của calendar này → **Make available to public** (không bật được bằng code).
6. ⚙ **Project Settings → Script Properties**, thêm 6 property:
   - `SECRET` — chuỗi ngẫu nhiên, tạo bằng `openssl rand -hex 24`
   - `TEMPLATE_ID` — từ bước 4
   - `EVENTS_FOLDER_ID` — `1vtROHBvwA-csQRcJTkjV1Zu4lqQ7pOeJ` (bước 1)
   - `CALENDAR_ID` — từ bước 5 (bỏ qua nếu không dùng calendar)
   - `PROPOSAL_TEMPLATE_ID` — `1KNjUO2Gv1MYjp2yNbAfAX0qKqtLyc3w9oMIHZnTCgEU` (Doc `[Template] Proposal BT (2026)` trong Templates/)
   - `PROPOSALS_FOLDER_ID` — `163wW985cRrxekYt6FA5pCERKKWOZbmLs` (`Bookie 2026/Proposals/`)
7. **Deploy → New deployment → Web app**: *Execute as* = **Me** · *Who has access* = **Anyone** → **Deploy** → copy **Web app URL** (`https://script.google.com/macros/s/…/exec`).
8. Trên máy, thêm vào `Bookie/.env` (gitignored):
   ```
   BOOKIE_FORM_WEBAPP_URL=<Web app URL>
   BOOKIE_FORM_SECRET=<chuỗi ở bước 6>
   ```
9. Smoke-test: mở Web app URL trên browser → thấy `{"ok":true,"service":"bookie-form-dang-ky"…}` là sống. Sau đó chạy thử end-to-end với một `event.json` nháp (xem Verification bên dưới).

Cập nhật code về sau: sửa `.gs` trong repo → paste đè vào editor → **Deploy → Manage deployments → ✎ → New version**. (URL không đổi.)

## Verification sau deploy

- Chạy `create-form.mjs` với event nháp → check: folder per-event tự tạo đúng dưới `Events/`, form nằm trong đó, title/mô tả/ngày đúng, form đang nhận response, mở `forms.gle` link OK, submit thử 1 response; nếu có `CALENDAR_ID` — event hiện trên calendar "Bookie Events" đúng giờ VN.
- Xoá form + folder + calendar event nháp sau khi test.

## Ghi chú kỹ thuật

- **Vì sao Apps Script mà không phải Forms REST API** (research + verify 07/2026): clone qua `DriveApp.makeCopy` giữ nguyên theme/ảnh header brand (REST API không set được theme); `shortenFormUrl()` là đường duy nhất lấy **forms.gle** bằng code (REST không expose; bit.ly free 5 link/tháng; TinyURL no-auth đã deprecated + chèn trang quảng cáo); không phải nuôi GCP OAuth client/refresh token (Testing mode hết hạn 7 ngày).
- **Publish guard**: sau cutover 30/06/2026 form tạo qua API mặc định *unpublished*; docs không nói rõ trường hợp copy → script tự check `isPublished()` và `setPublished(true)` khi cần.
- **Calendar "Bookie Events"**: `doPost` tạo event thật qua `CalendarApp` khi có `CALENDAR_ID` + `ngay_gio_iso` (parse với offset `+07:00` tường minh — không phụ thuộc timezone của project). Calendar này là **nguồn dữ liệu stack-agnostic** cho lịch sự kiện: embed được vào Google Sites hiện tại lẫn website tĩnh sau này (public ICS/embed). Lỗi calendar không chặn luồng tạo form (`calendar_error` trong response). Khác với `calendar_link` (URL "thêm vào lịch" cho NGƯỜI THAM DỰ, build local không cần API) — hai thứ phục vụ hai mục đích.
- **Bảo mật**: Web App "Anyone" nhưng mọi request phải khớp `SECRET` (so trong `doPost`); secret chỉ nằm ở Script Properties (phía Google) + `Bookie/.env` (local, gitignored). File `.gs` trong repo public KHÔNG chứa secret. Web App không set được HTTP status → lỗi trả qua `{"ok":false,"error":…}`.
- **QR**: encode link DÀI (`published_url` — sống độc lập với shortener), error correction **M**, quiet zone 4 module. SVG dùng cho poster (sắc nét mọi khổ), PNG ~1200px cho slide/in ấn. Sinh bằng thư viện vendored `lib/qrcode.js` ([qrcode-generator 1.4.4](https://github.com/kazuhikoarase/qrcode-generator), Kazuhiko Arase, MIT — giữ nguyên license header trong file; zero dependency, không cần cài gì thêm).
- "QR Code" là nhãn hiệu đã đăng ký của DENSO WAVE INCORPORATED.
