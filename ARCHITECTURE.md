# Kiến trúc hệ vận hành event — Bookie

> Doc spine, span toàn hệ (ops + registry + website). Nếu bạn chỉ đọc một file để hiểu
> "hệ này ráp lại thế nào và vì sao", đọc file này. Chi tiết build từng lớp nằm ở các
> doc con — file này KHÔNG lặp lại chúng, chỉ link sang.

## Đây là gì / ai maintain

Bộ tự động hoá vận hành event của Bookie: từ tạo event (form đăng ký, QR, calendar,
proposal host) tới quản lý member (registry), gửi mail theo lịch (mời/nhắc/cảm ơn),
và hiển thị ra ngoài (website). Toàn bộ chạy trên **Apps Script gắn với
`bookie.community@gmail.com`** — không hạ tầng ngoài, không dịch vụ trả phí.

Maintainer duy nhất: Hải (co-founder kỹ thuật). Không có team vận hành thứ hai đọc
được code — mọi quyết định kiến trúc trong doc này giả định đây vẫn là sự thật khi
build (xem risk "single-account SPOF" ở § Risk register).

## Hai ranh giới cứng

Hai câu này áp dụng cho MỌI slice, MỌI file bên dưới — không có ngoại lệ, không có
"lần này thì khác":

> **PII line**: data cá nhân chỉ sống trong Drive/Sheets/Forms trên account
> bookie.community; repo và website chỉ chứa event metadata + số liệu tổng;
> `event.json` là public data by definition.

> **Human-gate line**: máy chỉ thi hành content người đã duyệt — Doc trong event
> folder hoặc git commit. Thiếu artifact đã duyệt → skip + log, không bao giờ tự
> sáng tác.

Hệ quả trực tiếp: website KHÔNG BAO GIỜ fetch từ Sheet — chỉ render từ `event.json`
đã commit. Mail KHÔNG BAO GIỜ tự soạn nội dung — chỉ đọc Doc đã duyệt. Registry Sheet
không phải nguồn công khai — nó ở trong Drive tổ chức, không expose ra web app trừ
2 route public hẹp (subscribe/unsubscribe, § System map).

## System map

```
                         NGƯỜI DUYỆT (Doc / git commit) = human gate
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
   event.json (repo)          Docs trong event         comms templates
        │ commit = gate       folder (3 mail Docs)      (bd-2026/comms)
        │                           │                           │
        ▼                           ▼                           │
  ┌─────────────┐                                                │
  │  Cloudflare  │  build từ event.json trong repo               │
  │  Pages (site/)│  (không đọc Sheet, không đọc form response)  │
  └──────┬───────┘                                                │
         │ render "sắp diễn ra / đã diễn ra"                     │
         │                                                        │
         │ POST text/plain (subscribe/unsubscribe)                │
         ▼                                                        │
  ┌──────────────────────────── Apps Script web app ───────────┐  │
  │  doPost() router                                            │  │
  │   ├─ public: subscribe / unsubscribe / resubscribe          │  │
  │   └─ secret-gated: --new-event / --new-proposal / ...       │  │
  └───────┬─────────────────────────────────┬───────────────────┘  │
          │ create-form.mjs / event.json      │                    │
          ▼                                    │                    │
  form đăng ký + QR + calendar event +          │                    │
  folder Drive + 3 Docs mail (copy từ ◄──────────────────────────────┘
  Templates) + 1 dòng mới trong `Events`
          │
          ▼
  ┌──────────────────────────────────────────────────────────┐
  │           1 TRIGGER DUY NHẤT: dailyMailTick() ~08:00 VN    │
  │   1. syncAll()  — batch-scan form responses → registry     │
  │   2. sendDue()  — quota guard → gửi mail đến hạn            │
  └──────────────────────────┬───────────────────────────────┘
                              ▼
                 Registry Sheet `Bookie Registry 2026` — 6 tab
           Events · Subscribers · Bookiers · Attendance ·
                      Feedback · People
```

Nguyên tắc đọc sơ đồ: mọi mũi tên VÀO web app hoặc VÀO trigger đều bắt nguồn từ một
artifact đã qua human gate (Doc, event.json, hoặc payload subscribe do chính người
dùng gõ). Không có nhánh nào để Claude/script tự phát sinh nội dung publish-ra-ngoài.

## Decision log

| Ngày | Quyết định | Rationale ngắn |
|---|---|---|
| 2026-07-15 | Không dùng n8n | Ops toàn bộ đã sống trên Google account — Apps Script là automation bản địa, zero hạ tầng; n8n chỉ thêm Docker + OAuth phải nuôi cho lợi ích không cần (xem [ROADMAP.md](shared/event-automation/ROADMAP.md)). |
| 2026-07-15 | Apps Script làm spine | Time-driven trigger chạy server-side (không phụ máy cá nhân), `MailApp`/`CalendarApp`/`FormApp` free, đã verify từ slice form đăng ký. |
| 2026-07-13 (vị trí chốt 2026-08-03) | Website migrate Astro + Cloudflare Pages, code tại `site/` trong repo Bookie | Google Sites bản mới không có content API — ngõ cụt automation. Site-as-code thì mọi update per-event tự sinh từ `event.json`, cùng nguồn với form/QR/poster. Domain đã ở Cloudflare → cutover chỉ đổi CNAME. |
| 2026-08-03 | Sheet-as-registry: **Forms = system of record, Sheet = derived index** | Sheet rebuild được từ form responses bất cứ lúc nào → an toàn hơn coi Sheet là nguồn gốc. Người lỡ sửa/xoá Sheet không mất data thật. |
| 2026-08-03 | Không dùng ESP ngoài — `MailApp` thuần | List < 100 địa chỉ, quota consumer ~100 recipient/ngày đủ dùng nhiều năm nữa ở quy mô hiện tại. Tránh thêm tài khoản/tích hợp bên thứ ba khi chưa cần. |
| 2026-08-03 | Batch scan thay per-form trigger | 20 triggers/user/script là cap cứng; 3 trigger/event (đăng ký, feedback, check-in) sẽ chết ở event thứ ~6. Batch scan = đúng 1 trigger vĩnh viễn, rescan toàn bộ là recovery path khi cần. |
| 2026-08-03 | Single opt-in (không double opt-in) | Giảm ma sát đăng ký nhận tin cho list nhỏ, rủi ro thấp ở quy mô này. Tripwire: chuyển double opt-in khi list > 300 địa chỉ HOẶC có complaint thật. |
| 2026-08-03 | Unsubscribe = token HMAC ký, không lưu DB | Không cần bảng ánh xạ token↔email; verify tại chỗ bằng secret. Secret (`UNSUB_SECRET`) tách riêng khỏi `SECRET` hiện có của web app. |
| 2026-08-03 | HTML mail = brand template cố định + `htmlBody`, content từ Doc đã duyệt | Đạt độ chỉn chu kiểu Mailchimp mà không cần ESP — người duyệt template 1 lần, duyệt content mỗi event; human gate không đổi chỗ. |
| 2026-08-03 | 2 loại user quản lý độc lập (Bookier vs Subscriber), unsubscribe LUÔN thắng roster preference | Bookier = roster nội bộ do người quản; Subscriber = guest do script quản. Gặp nhau duy nhất lúc tính audience gửi mail — và khi có mâu thuẫn, quyền từ chối của người nhận thắng tuyệt đối. |

> Bảng audience + suppression đầy đủ → [REGISTRY.md](shared/event-automation/REGISTRY.md) mục 4 (hai loại user & audience).

## Component inventory

| Thành phần | Vai trò | Doc chi tiết |
|---|---|---|
| Apps Script spine (form/QR/calendar/proposal) | Tạo event, tạo form đăng ký, đổ Sheet | [shared/event-automation/README.md](shared/event-automation/README.md) |
| Mail scheduler + registry (`dailyMailTick`, 6-tab Sheet) | Sync data, gửi mail đúng lịch, quản subscriber | [shared/event-automation/REGISTRY.md](shared/event-automation/REGISTRY.md) |
| Roadmap + slice sequencing | Ops-chain per-event, trạng thái build từng phần, backlog v2 | [shared/event-automation/ROADMAP.md](shared/event-automation/ROADMAP.md) |
| Design system (poster/cover) + email template | Brand tokens dùng chung cho poster, cover, và mail HTML | [shared/design-system/README.md](shared/design-system/README.md) |
| Event kits (BD, BT) | Nội dung/quy trình theo loại event: proposal, comms templates, form spec | [projects/bd-2026/](projects/bd-2026/), [projects/bt-2026/](projects/bt-2026/) |
| Website | View-only + 1 điểm tương tác (subscribe), build từ `event.json` | [site/SPEC.md](site/SPEC.md) |

## Quota verified

Toàn hệ chạy trong tầng free của Google Workspace/consumer account — mọi con số dưới
đây là hard cap, không phải ước lượng, và mọi thiết kế trong REGISTRY.md/ROADMAP.md
phải nằm trong giới hạn này:

| Quota | Giá trị | Áp dụng cho |
|---|---|---|
| Recipient/ngày (consumer Gmail) | 100 | `MailApp.sendEmail` — tổng số người nhận, không phải số lần gọi |
| Triggers/user/script | 20 | Tổng trigger cho toàn bộ project Apps Script — lý do batch-scan thay per-form trigger |
| Thời gian chạy/lần execution | 6 phút | Mỗi lần `dailyMailTick()` chạy phải xong trong cửa sổ này |
| Trigger runtime/ngày | 90 phút | Tổng thời gian tất cả trigger cộng lại trong 1 ngày |
| Dung lượng `PropertiesService` | 500 KB | Idempotency keys, script properties — dọn định kỳ nếu phình |
| `UrlFetch` calls/ngày | 20.000 | Dự phòng cho tích hợp ngoài (Turnstile, ESP escalation) |

## Risk register

Theo thứ tự khả năng gãy (gần → xa), không theo mức độ nghiêm trọng:

1. **Quota mail khi list ~90 địa chỉ** — cách trần 100/ngày không xa, một event
   T-31 gửi trùng lịch với T-1/T+2 của event khác là chạm trần. Mitigation: quota
   guard cứng trong `sendDue()` (thứ tự T-1 → T+2 → T-31, floor 25 cho
   transactional, T-31 chia đợt theo `t31_cursor`).
2. **Người sửa cấu trúc Sheet** (đổi tên cột, chèn cột giữa, xoá tab) — script đọc
   theo header name nên đổi tên cột là gãy im lặng. Mitigation: lookup theo tên
   header (không theo index) + range protection trên các tab do script ghi.
3. **Deliverability trên consumer Gmail** — `MailApp` không set được header
   `List-Unsubscribe`, nên Gmail/các mail client không hiện nút unsubscribe chuẩn ở
   inbox → tăng khả năng người nhận bấm "report spam" thay vì unsubscribe (report
   spam ảnh hưởng domain reputation nặng hơn unsubscribe). Mitigation: link
   unsubscribe rõ ràng ngay đầu mail + footer, single-click, không yêu cầu login;
   theo dõi complaint rate; escalation path ở § Escalation ladder nếu vấn đề thật.
4. **Single-account SPOF** — toàn hệ (form, mail, calendar, registry, web app) sống
   trên một Google account cá nhân (`bookie.community@gmail.com`). Mất quyền truy
   cập (khoá account, quên mật khẩu, 2FA mất thiết bị) = sập toàn bộ vận hành cùng
   lúc. **Đây là risk vận hành lớn nhất trong toàn hệ** — lớn hơn mọi risk kỹ thuật
   ở trên. Cần runbook: 2FA có backup codes lưu nơi an toàn thứ hai, ít nhất một
   người khác (đồng đội tin cậy) có recovery access hoặc biết quy trình khôi phục.
5. **Trigger chết im lặng** — nếu `dailyMailTick()` bị Google tự tắt (lỗi liên tục,
   thay đổi quota chính sách) thì không có gì báo — mail đơn giản ngừng gửi, không
   ai biết cho tới khi có người hỏi "sao chưa nhận mail nhắc". Mitigation: heartbeat
   — mỗi lần tick chạy thành công ghi timestamp vào Script Property `LAST_TICK_AT`;
   `auditRegistry()` phát hiện staleness (>48h) và tự gửi mail self-notify.

## Escalation ladder

Ba bậc thang riêng biệt, mỗi bậc có tripwire — chỉ leo khi tripwire chạm, không leo
trước:

- **Kênh gửi mail**: `MailApp` (hiện tại) → `GmailApp` advanced service (cần verify
  khả năng set header) → Brevo free tier (300 mail/ngày). Tripwire: list vượt 150
  địa chỉ (gần chạm quota `MailApp` khi cộng cả 3 loại mail trong ngày cao điểm).
- **Chống spam/abuse ở endpoint subscribe**: honeypot field + time-to-fill check
  (hiện tại) → Cloudflare Turnstile (field `cf_token` đã chừa sẵn trong payload, bật
  không cần đổi trang). Tripwire: spam subscribe thật xuất hiện trong Subscribers
  tab (không phải giả định trước).
- **Mô hình opt-in**: single opt-in + welcome mail có unsubscribe (hiện tại) →
  double opt-in (confirm qua mail trước khi vào Subscribers). Tripwire: list vượt
  300 địa chỉ HOẶC có complaint thật (report spam / phàn nàn trực tiếp) — cái nào
  đến trước.

## Đọc tiếp

- Build registry/mail scheduler lạnh từ đầu → [REGISTRY.md](shared/event-automation/REGISTRY.md).
- Dựng site → [site/SPEC.md](site/SPEC.md).
- Trạng thái từng phần đã build/chưa, slice sequencing → [ROADMAP.md](shared/event-automation/ROADMAP.md).
- Data cá nhân sống ở đâu, ai đọc, retention → [PII-POLICY.md](knowledge/_meta/PII-POLICY.md) mục "Operational data (ngoài repo)".
