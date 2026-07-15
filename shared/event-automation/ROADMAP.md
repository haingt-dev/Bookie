# Event Automation — Roadmap & quyết định kiến trúc

> Chốt 2026-07-15 (session kiến trúc, build dời về đợt làm việc tại SG ~đầu tháng 8).
> File này là state carrier: session build đầu tiên đọc file này + [README.md](README.md) là đủ bootstrap, không cần khảo sát lại.

## Quyết định: KHÔNG dùng n8n — Apps Script spine + Claude content layer + human gate

Ops của Bookie (form, calendar, mail, Drive) sống trọn trên `bookie.community@gmail.com` — Apps Script là automation bản địa của đúng hệ đó:

1. **Time-driven trigger chạy phía Google** (cron server-side, không phụ thuộc máy cá nhân bật/tắt), `MailApp`/`GmailApp`, `CalendarApp`, `FormApp` — zero hạ tầng phải nuôi, free, và stack này ĐÃ được chọn + verify từ slice form đăng ký (07/2026, xem [README § Ghi chú kỹ thuật](README.md)).
2. **n8n chỉ thêm visual multi-service orchestration** — workload này không cần; đổi lại phải nuôi Docker stack + tự cấu hình OAuth. Stack n8n trong `projects/ai-book-video/n8n/` là chuyện riêng của video pipeline (đang pause, CLI vẫn chạy) — **ngoài phạm vi, không đụng**.
3. **Gap còn lại rất mỏng**: tạo event/form/QR/calendar/proposal đã code xong (`form-dang-ky.gs` + `create-form.mjs`), templates mail + bài FB đã viết sẵn (`projects/*/comms/`). Thiếu đúng một lớp: **mail scheduler** (gửi đúng ngày theo T-offset) + các mảnh v2 bên dưới.

Nguyên tắc phân vai (giữ xuyên suốt): **máy chỉ thi hành thứ người đã duyệt**. Nội dung (mail, bài đăng) do Claude soạn từ template → người duyệt MỘT LẦN lúc tạo event → trigger chỉ gửi/nhắc theo lịch. Mọi thứ outward-facing chưa duyệt sẵn (bài FB, Zalo) = draft + người bấm đăng.

## Ops-chain mapping (từ [checklist-chuan-bi.md](../../projects/bd-2026/plan/checklist-chuan-bi.md))

| T | Việc | Cơ chế | Trạng thái |
|---|------|--------|-----------|
| T-45 | Gặp host, host nộp proposal | `--new-proposal` copy Doc template | ✅ đã code, chờ deploy |
| T-40 | Calendar cho member | Apps Script tạo event trên "Bookie Events" | ✅ đã code, chờ deploy |
| T-40 | Poster | `/event-graphics` (draft → người duyệt) | ✅ đang dùng |
| T-40 | Venue, co-host | Người | manual (giữ nguyên) |
| T-35 | Đăng FB announcement | Claude draft từ `comms/bai-dang-fb.md` → người đăng / schedule Meta Business Suite. **Không đi Graph API** (app review không đáng cho 1 page) | draft+gate |
| T-31 | Mail mời guest | **Semi-auto v1**: hàm `sendInvite()` chạy tay với guest list — nguồn list = OPEN item bên dưới | 🔨 build SG |
| T-30 | Form đăng ký + QR + calendar | `/event-form` | ✅ đã code, chờ deploy |
| T-30 | Feedback form | Spec sẵn ([bieu-mau-feedback.md](../../projects/bd-2026/plan/bieu-mau-feedback.md)) | v2 |
| T-10→T-2 | Role-holders, titles, verify prep | Người (+ templates guideline có sẵn) | manual |
| T-7 / T-1 | Teaser FB | draft+gate như T-35 | draft+gate |
| **T-1** | **Mail nhắc người đã đăng ký** | **Auto** — mail scheduler (dưới). Zalo nhắc (SĐT thu ở form đúng cho mục này) vẫn là kênh tay song song | 🔨 build SG |
| T-0 | Check-in QR, ảnh, feedback, ghi chú | Người; check-in tự động = v2 | manual → v2 |
| T+1 | Upload ảnh, bài recap FB | Recap = v2 skill (draft+gate) | v2 |
| **T+2** | **Mail cảm ơn** | **Auto** — mail scheduler | 🔨 build SG |
| T+3 | Reflection | Người | manual |

## Design v1 — mail scheduler (spec để build, CHƯA build)

Thêm vào `apps-script/form-dang-ky.gs` (cùng project, không tách):

- **`setupMailTrigger()`** (one-time): cài time-driven trigger daily ~08:00 VN gọi `dailyMailTick()`.
- **`dailyMailTick()`**: quét calendar `CALENDAR_ID` trong cửa sổ `[hôm nay −7, +7]` ngày → với mỗi event tính T-offset → đến hạn thì gửi:
  - `T-1` → mail **nhắc** cho người đã đăng ký: lấy responses của form event đó, email từ `getRespondentEmail()` (form đã bật "Thu thập địa chỉ email — Responder input", bắt buộc, theo [bieu-mau-dang-ky.md](../../projects/bd-2026/plan/bieu-mau-dang-ky.md)).
  - `T+2` → mail **cảm ơn** cho cùng danh sách (v2 đổi sang danh sách check-in khi có).
- **Mapping calendar event → form/folder**: mở rộng `doPost` — sau khi tạo form + calendar event, ghi Script Properties `evt:<calendar_event_id>` = JSON `{form_id, folder_id}`. (Trigger không phải đoán từ tên folder.)
- **Nội dung mail = đã duyệt trước, nằm trong event folder trên Drive**: mỗi event có 2 Google Doc theo convention `[Mail] Nhắc T-1` và `[Mail] Cảm ơn T+2` — Claude soạn từ [`comms/email-nhac-1-ngay.md`](../../projects/bd-2026/comms/email-nhac-1-ngay.md) / [`thu-cam-on.md`](../../projects/bd-2026/comms/thu-cam-on.md) lúc tạo event, người duyệt/sửa trực tiếp trong Doc. **Dòng 1 của Doc = subject, còn lại = body** (v1 gửi plain text — đủ cho mail cộng đồng; HTML export = nice-to-have sau). **Thiếu Doc → skip + log, tuyệt đối không tự sáng tác nội dung.**
- **Idempotency**: Script Properties `sent:<calendar_event_id>:<loại>` = timestamp — trigger chạy lại không gửi trùng.
- **Lỗi không chặn**: try/catch per event per mail; lỗi → `Logger` + mail self-notify về `bookie.community@gmail.com`. Check `MailApp.getRemainingDailyQuota()` trước khi gửi (quota consumer ~100 recipient/ngày — event 20–60 khách dư, nhưng đừng gửi mù).
- **`sendInvite(calendar_event_id, sheet_url)`** (semi-auto, chạy tay từ editor): gửi mail mời T-31 theo danh sách trong 1 Google Sheet (cột email, tên). Không nằm trong trigger — chờ chốt nguồn guest list.

## v2 backlog (không cam kết ngày)

- **Check-in tại event**: form check-in per-event (clone như form đăng ký) + QR thứ hai; danh sách check-in nuôi mail cảm ơn + số liệu recap.
- **Feedback form auto-create**: thêm `setupFeedbackTemplate()` + nhánh doPost, spec 9 trường đã có sẵn.
- **Recap skill** (`/event-recap`): đọc feedback responses + ảnh + agenda → draft bài FB recap + đoạn số liệu cho reflection. Draft+gate, không auto-post.

## Runbook đợt SG (theo thứ tự)

1. **Session build** (cần Claude): viết phần mail scheduler theo spec trên vào `form-dang-ky.gs` + cập nhật README (bước deploy 4b: bật "Collect email — Responder input" bằng UI vì code không set được; bước mới: chạy `setupMailTrigger()`).
2. **Deploy một buổi desktop** (KHÔNG cần Claude — [README § Deploy một lần](README.md) tự chứa): 8 bước pending + 2 việc UI (form theme + collect-email; calendar public nếu muốn embed) + `setupMailTrigger()`.
3. **E2E test**: event.json nháp → form/QR/calendar OK → tạo 2 Doc mail nháp → chỉnh giờ event giả để trigger bắn thử → check idempotency (chạy tick 2 lần) → dọn rác test.
4. **BT31 = lần chạy thật đầu tiên** (có thể rơi đầu tháng 8 — deploy xong trước).

## OPEN items (chốt ở SG)

- **Nguồn guest list cho mail mời T-31**: member list từ đâu (Sheet tổng? export từ form các event cũ? nhóm Zalo?) — quyết rồi mới build `sendInvite` cho tử tế.
- Kênh nhắc T-1 qua Zalo: giữ tay hay bỏ hẳn khi mail chạy — xem số liệu "Bạn biết sự kiện qua đâu" sau 1-2 event.
- Recap skill đặt ở đâu (`.claude/skills/event-recap/` cạnh `/event-form`?) — chốt lúc build v2.
