# Event Automation — Roadmap & quyết định kiến trúc

> Chốt 2026-07-15 (session kiến trúc), AMENDED 2026-08-03 (session thiết kế trọn gói — registry Sheet, mail HTML, site, slice plan). Build dời về đợt làm việc tại SG ~đầu tháng 8, BT31 = mốc chạy thật đầu.
> File này là state carrier: session build đầu tiên đọc file này + [README.md](README.md) là đủ bootstrap, không cần khảo sát lại. Bối cảnh kiến trúc đầy đủ (2 ranh giới, system map, risk register) → [`ARCHITECTURE.md`](../../ARCHITECTURE.md). Schema + luật registry, sync algorithm, endpoint contract → [`REGISTRY.md`](REGISTRY.md).

## Quyết định: KHÔNG dùng n8n — Apps Script spine + Claude content layer + human gate

Ops của Bookie (form, calendar, mail, Drive) sống trọn trên `bookie.community@gmail.com` — Apps Script là automation bản địa của đúng hệ đó:

1. **Time-driven trigger chạy phía Google** (cron server-side, không phụ thuộc máy cá nhân bật/tắt), `MailApp`/`GmailApp`, `CalendarApp`, `FormApp` — zero hạ tầng phải nuôi, free, và stack này ĐÃ được chọn + verify từ slice form đăng ký (07/2026, xem [README § Ghi chú kỹ thuật](README.md)).
2. **n8n chỉ thêm visual multi-service orchestration** — workload này không cần; đổi lại phải nuôi Docker stack + tự cấu hình OAuth. Stack n8n trong `projects/ai-book-video/n8n/` là chuyện riêng của video pipeline (đang pause, CLI vẫn chạy) — **ngoài phạm vi, không đụng**.
3. **Gap còn lại đã mỏng hơn nữa sau session 08/2026**: tạo event/form/QR/calendar/proposal đã code xong (`form-dang-ky.gs` + `create-form.mjs`), templates mail + bài FB đã viết sẵn (`projects/*/comms/`). Lớp còn thiếu: **mail scheduler** (spec amended dưới) + **registry Sheet** (schema build sẵn trong REGISTRY.md) + **check-in/feedback form tự tạo** + **site** — tất cả đã có spec, chờ build theo slice.

Nguyên tắc phân vai (giữ xuyên suốt): **máy chỉ thi hành thứ người đã duyệt**. Nội dung (mail, bài đăng) do Claude soạn từ template → người duyệt MỘT LẦN lúc tạo event → trigger chỉ gửi/nhắc theo lịch. Mọi thứ outward-facing chưa duyệt sẵn (bài FB, Zalo) = draft + người bấm đăng.

## Ops-chain mapping (từ [checklist-chuan-bi.md](../../projects/bd-2026/plan/checklist-chuan-bi.md))

| T | Việc | Cơ chế | Trạng thái |
|---|------|--------|-----------|
| T-45 | Gặp host, host nộp proposal | `--new-proposal` copy Doc template | ✅ đã code, chờ deploy |
| T-40 | Calendar cho member | Apps Script tạo event trên "Bookie Events" | ✅ đã code, chờ deploy |
| T-40 | Poster | `/event-graphics` (draft → người duyệt) | ✅ đang dùng |
| T-40 | Venue, co-host | Người | manual (giữ nguyên) |
| T-35 | Đăng FB announcement | Claude draft từ `comms/bai-dang-fb.md` → người đăng / schedule Meta Business Suite. **Không đi Graph API** (app review không đáng cho 1 page) | draft+gate |
| **T-31** | **Mail mời guest** | **Auto** trong `dailyMailTick()` — audience = `Subscribers[subscribed]` ∪ `Bookiers[active, nhan_mail_su_kien=yes]` (nguồn guest list ĐÃ CHỐT = tab `Subscribers` trong registry Sheet, xem [REGISTRY.md](REGISTRY.md) — OPEN item cũ đóng). Gửi chia đợt trong cửa sổ `[T-31, T-28]` | 🔨 build SG (S7) |
| T-30 | Form đăng ký + QR + calendar | `/event-form` | ✅ đã code, chờ deploy |
| **T-30** | **Check-in form + QR thứ hai** | **Auto** — `doPost` clone `CHECKIN_TEMPLATE_ID` cùng lúc tạo event, như form đăng ký | 🔨 build SG (S5) |
| **T-30** | **Feedback form** | **Auto** — `doPost` clone `FEEDBACK_TEMPLATE_ID` cùng lúc tạo event (spec sẵn: [bieu-mau-feedback.md](../../projects/bd-2026/plan/bieu-mau-feedback.md)) | 🔨 build SG (S5) |
| T-10→T-2 | Role-holders, titles, verify prep | Người (+ templates guideline có sẵn) | manual |
| T-7 / T-1 | Teaser FB | draft+gate như T-35 | draft+gate |
| **T-1** | **Mail nhắc người đã đăng ký** | **Auto** — mail scheduler (dưới). Zalo nhắc (SĐT thu ở form đúng cho mục này) vẫn là kênh tay song song, giữ lại | 🔨 build SG (S3) |
| **T-0** | **Check-in QR (thứ hai), ảnh, feedback link, ghi chú** | **Auto** cho check-in (quét QR thứ hai → ghi `Attendance[stage=check_in]`); ảnh/ghi chú vẫn người | 🔨 build SG (S5) |
| **T+1** | **Upload ảnh, bài recap FB** | **Skill `/event-recap`** đọc feedback + số liệu + agenda → draft bài recap + đoạn số liệu reflection. Draft+gate, không auto-post | 🔨 build SG (S8) |
| **T+2** | **Mail cảm ơn** | **Auto** — mail scheduler. Audience = check-in list nếu có, fallback registrants | 🔨 build SG (S3) |
| T+3 | Reflection | Người | manual |

## Design v1 (AMENDED 2026-08-03) — mail scheduler spec để build

Tách khỏi `form-dang-ky.gs` thành 4 file riêng, xem [§ Code layout](#code-layout-apps-script) bên dưới. Thay đổi lớn so với bản 07/2026: **mapping event↔form/folder + trạng thái gửi chuyển từ Script Properties sang tab `Events` trong registry Sheet** — người đọc/sửa trực tiếp được, xoá 1 cell = re-send có chủ đích, không cần mở editor. Rationale + schema đầy đủ → [REGISTRY.md](REGISTRY.md); tóm tắt dưới đây đủ để hiểu luồng.

- **`setupMailTrigger()`** (one-time): cài time-driven trigger daily ~08:00 VN gọi `dailyMailTick()`.
- **`dailyMailTick()`** — 2 bước tuần tự, không gộp:
  1. **`syncAll()`** trước: quét form responses của mọi event đang mở → ghi `Attendance` (append-only, dedupe theo `row_key`), rebuild `People`. Đây cũng là cơ chế recovery — chạy lại an toàn.
  2. **`sendDue()`** sau: với mỗi event trong tab `Events`, tính T-offset từ `Events.ngay_gio_iso` (date-part múi +07:00) → đến hạn thì gửi, theo **quota guard** dưới.
- **Mapping event → form/folder = tab `Events` trong registry Sheet** (KHÔNG dùng Script Properties `evt:`/`sent:` nữa): mỗi event 1 dòng, ghi mọi id form/folder/calendar liên quan — cột đầy đủ: [REGISTRY.md mục 2.1](REGISTRY.md). **3 cột trạng thái gửi `sent_t31_at` / `sent_t1_at` / `sent_t2_at`** thay cho Script Properties `sent:<id>:<loại>` cũ — trống = chưa gửi, có timestamp = đã gửi, **xoá cell = re-send lần tick kế**. Cột `t31_cursor` theo dõi tiến độ gửi chia đợt của mail mời.
- **Quota guard đầu `sendDue()`**: gọi `getRemainingDailyQuota()` một lần đầu hàm, rồi gửi theo **thứ tự cứng T-1 → T+2 → T-31** (transactional trước, marketing sau) — **floor 25 mail dành riêng cho transactional** (T-1/T+2 không bao giờ bị mail mời ăn hết quota). T-31 = cửa sổ `[T-31, T-28]`, gửi chia đợt theo `t31_cursor` (advance dần, không gửi hết 1 lần với list lớn); hụt quota giữa chừng → self-notify về `bookie.community@gmail.com`, cursor giữ nguyên để tick sau tiếp tục.
- **3 Google Doc mail / event** (tăng từ 2): `[Mail] Mời T-31` (mới) + `[Mail] Nhắc T-1` + `[Mail] Cảm ơn T+2` — convention tên giữ nguyên trong event folder. **`doPost` tự copy cả 3 từ Templates lúc tạo event** (không còn phải tạo tay), Claude soạn nội dung từ [`comms/`](../../projects/bd-2026/comms/) tương ứng, người duyệt/sửa trực tiếp trong Doc. **Dòng 1 của Doc = subject, còn lại = body.** Hỗ trợ substitution `{{ten}}`. **Thiếu Doc → skip + log, tuyệt đối không tự sáng tác nội dung** (giữ nguyên từ v1). **Self-notify T-32** nếu Doc mời (T-31) chưa được duyệt tính đến thời điểm đó — cảnh báo sớm 1 ngày trước cửa sổ gửi.
- **Audience + suppression**: 3 loại mail (mời/nhắc/cảm ơn) mỗi loại có audience + rào chặn riêng — **unsubscribe LUÔN thắng roster preference** cho mail marketing (T-31), mail transactional (T-1/T+2) chỉ chặn bởi `blocked`. Bảng đầy đủ + rationale → [REGISTRY.md mục 4](REGISTRY.md).

- **Mail HTML kiểu Mailchimp, không cần ESP**: `MailApp.sendEmail` với `htmlBody` + **plain-text fallback cùng mail** (bắt buộc, không phải nice-to-have — bản 07/2026 để "sau", nay đã có brand template). Kiến trúc = **brand email template cố định** tại `shared/design-system/templates/email/` (dùng chung tokens với poster/cover/web — 1 nguồn brand → 4 kênh, duyệt template 1 lần) + **content chữ từ Doc đã duyệt** (mỗi đoạn văn bản trong Doc → 1 thẻ `<p>`, không có markup nào khác được suy diễn). **Footer do CODE nối vào** (không nằm trong Doc → người sửa nội dung Doc không xoá nhầm được): marketing = link unsubscribe (token HMAC, xem REGISTRY.md), transactional = dòng "vì sao bạn nhận thư này". Ràng buộc kỹ thuật email-HTML: table-based layout + inline CSS, giữ mail < 102KB (Gmail clip ngưỡng này), font fallback system stack (Be Vietnam Pro không load trong mail client), ảnh poster v1 dùng `inlineImages` CID → chuyển sang ảnh host trên site sau S6.
- **Lỗi không chặn**: try/catch per event per mail-loại; lỗi → `Logger` + mail self-notify. Idempotency giờ đọc/ghi qua cột `sent_*_at` (thay Script Properties).
- Escalation ladder nếu list vượt khả năng MailApp (tripwire > 150 recipient): Gmail advanced service (chưa verify thực nghiệm — cần test trước khi dựa vào) → Brevo free tier nếu vẫn không đủ. Ghi chi tiết → ARCHITECTURE.md § Escalation ladder.

## Code layout Apps Script

Tách `form-dang-ky.gs` (monolith cũ) thành 4 file theo trách nhiệm — dễ đọc, dễ test riêng từng lớp:

| File | Trách nhiệm |
|---|---|
| `web.gs` | Router `doPost`/`doGet` — nhánh public (subscribe/unsubscribe/resubscribe) trước secret gate, nhánh admin (tạo event) sau |
| `form-dang-ky.gs` | Tạo form đăng ký + check-in + feedback (clone template), QR, calendar, folder, proposal |
| `registry.gs` | `setupRegistry()`, `syncAll()`, sync algorithm, People rebuild, dedupe/normalize |
| `mail.gs` | `dailyMailTick()`, `sendDue()`, quota guard, HTML compose, unsubscribe token |

**Script Properties mới** (thêm vào bộ hiện có; danh sách đầy đủ ngay đây — README chưa có mục này, sẽ cập nhật bước deploy tương ứng lúc build S2): `REGISTRY_ID`, `UNSUB_SECRET` (tách khỏi `SECRET` hiện có), `SITE_URL`, `CHECKIN_TEMPLATE_ID`, `FEEDBACK_TEMPLATE_ID`, 3 template id mail (`MAIL_INVITE_TEMPLATE_ID`, `MAIL_REMIND_TEMPLATE_ID`, `MAIL_THANKS_TEMPLATE_ID` — Doc gốc dùng để copy vào Templates của mỗi event), `MAIL_WELCOME_DOC_ID` (Doc `[Mail] Chào mừng`, thiếu → không gửi welcome), `LAST_TICK_AT` (heartbeat — `dailyMailTick()` ghi timestamp cuối mỗi lần chạy, `auditRegistry()` phát hiện stale >48h), `TURNSTILE_SECRET` (sau, field `cf_token` chừa sẵn ở form subscribe từ S4a).

## Slice plan S1 → S8 (thay v2 backlog cũ — build theo thứ tự, mỗi slice có acceptance test)

Chỉ **S1 có deadline cứng** (BT31 đầu tháng 8). Các slice sau xếp theo phụ thuộc kỹ thuật, không cam kết ngày. S6 (site) chạy song song được với S2–S5 vì độc lập registry.

| Slice | Nội dung | Acceptance test |
|---|---|---|
| **S1** | Deploy phần đã code (form đăng ký + QR + calendar + proposal) — **CHẶN BỞI BT31 đầu 08, deadline cứng duy nhất của kế hoạch này**. Kèm scope plumbing `ma_su_kien`: `event.json` + `create-form.mjs` gửi `ma_su_kien`, `doPost` validate pattern `[A-Z]{2,4}\d+` (pattern + prefix: [REGISTRY.md mục 2.1](REGISTRY.md)) và từ chối event thiếu key. Cập nhật danh sách field `event.json` trong [README.md](README.md) cùng lúc build | Tạo event thật BT31 qua `doPost` → form/QR/calendar/folder/proposal Doc xuất hiện đúng, không lỗi editor; payload gửi lên chứa đúng `ma_su_kien: "BT31"` |
| S2 | `setupRegistry()` tạo 6 tab đúng schema + `Events` row/event + `syncAll()` đọc form responses → `Attendance` + rebuild `People` + trigger daily | Chạy `syncAll()` 2 lần liên tiếp trên data test → `Attendance` không có row_key trùng, `People` số đăng ký đúng |
| S3 | Mail T-1/T+2 qua `sendDue()` + brand email template v1 (khung tĩnh, chưa cần content thật) | Set ngày event giả T-1 → tick chạy → mail HTML nhận được đúng người trong `Attendance`, cột `sent_t1_at` được ghi; xoá cell → tick sau gửi lại |
| S4a | Endpoint `subscribe`/`unsubscribe`/`resubscribe` trong `web.gs` + welcome mail (budget ~20/ngày) — **test được bằng `curl` trước khi có site** | `curl -X POST` với `text/plain` JSON hợp lệ → `Subscribers` có dòng mới, trạng thái đúng; token unsubscribe HMAC verify được, sai token → reject |
| S4b | Form đăng ký gốc thêm trường #9 checkbox consent (không tick mặc định) | Đăng ký test, không tick consent → không xuất hiện trong `Subscribers`; tick → xuất hiện `subscribed` |
| S5 | Check-in v2 (`CHECKIN_TEMPLATE_ID` clone + QR thứ hai + `Attendance[stage=check_in]`) + feedback auto-create (`FEEDBACK_TEMPLATE_ID`) + T+2 audience chuyển sang check-in list | Quét QR check-in test → `Attendance` có dòng `stage=check_in`; feedback form tồn tại ngay khi tạo event, không cần tay clone |
| S6 | Site Astro + Cloudflare Pages + CNAME cutover (song song được với S2–S5, xem [`site/SPEC.md`](../../site/SPEC.md)) | Build local pass zod schema, deploy Pages preview, DNS cutover không downtime > vài phút |
| S4c | Wire form subscribe lên site (`/dang-ky-nhan-tin` gọi endpoint S4a qua `fetch` `text/plain`) | Submit form trên site thật → `Subscribers` cập nhật, không lỗi CORS/preflight |
| S7 | T-31 auto trong `sendDue()` — audience Subscribers ∪ Bookiers, cửa sổ `[T-31,T-28]`, `t31_cursor` | Event test với > cursor-batch-size subscriber giả → gửi chia đúng đợt qua nhiều tick, không gửi trùng, không vượt floor transactional |
| S8 | Skill `/event-recap` (vị trí: `.claude/skills/event-recap/`) — đọc feedback + số liệu + agenda → draft bài recap + đoạn reflection | Chạy skill trên event có feedback thật → draft đọc được, số liệu khớp `Feedback`/`Attendance`, không auto-post |

## Runbook đợt SG (theo thứ tự)

1. **Session build** (cần Claude): implement slice plan S1→S8 theo đúng thứ tự bảng trên + cập nhật README: bước deploy **xác nhận "Collect email — Responder input"** ở form đăng ký gốc (script thử set bằng code, không đảm bảo trên mọi account — kiểm lại bằng UI, xem Execution log) + bước mới **chạy `setupMailTrigger()`** (one-time, cài time-driven trigger daily ~08:00 VN gọi `dailyMailTick()`).
2. **Deploy một buổi desktop** (KHÔNG cần Claude — [README § Deploy một lần](README.md), cập nhật kèm session build): các bước pending + việc UI (form theme + collect-email; calendar public nếu muốn embed) + `setupMailTrigger()`.
3. **E2E test** (công thức chuẩn — áp cho mỗi slice đụng mail/idempotency, xem thêm acceptance test S3/S7 ở bảng trên): event.json nháp → form/QR/calendar OK → tạo Doc mail nháp → **chỉnh giờ event giả** để T-offset trúng ngày hôm nay → chạy tick **2 lần liên tiếp** → kiểm **idempotency** (không gửi trùng, cột `sent_*_at` chỉ ghi timestamp 1 lần) → dọn rác test (xoá form/folder/calendar/Sheet row test).
4. **BT31 = lần chạy thật đầu tiên của S1** (đầu tháng 8 — deploy S1 xong trước hạn này; S2→S8 build sau, không cam kết ngày).

## OPEN items

- ~~Nguồn guest list cho mail mời T-31~~ — **CHỐT 2026-08-03**: tab `Subscribers` trong registry Sheet (xem bảng audience ở trên + [REGISTRY.md](REGISTRY.md)).
- **Giữ lại** kênh nhắc T-1 qua Zalo song song với mail — xem số liệu "Bạn biết sự kiện qua đâu" sau 1-2 event trước khi quyết bỏ.
- Gmail advanced service (escalation ladder khi list > 150) — **note: chưa verify thực nghiệm**, cần test trước khi coi là escape hatch chắc chắn dùng được.
- ~~Recap skill đặt ở đâu~~ — **CHỐT**: `.claude/skills/event-recap/`, build ở S8 (xem bảng slice).
