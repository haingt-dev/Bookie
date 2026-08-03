# Registry — spec `registry.gs` + endpoint public của `web.gs`

> Chốt 2026-08-03 (session thiết kế trọn gói hệ vận hành event). **DOCS ONLY — chưa build.**
> File này là spec build được: session build đọc file này alone là viết được `registry.gs`
> + nhánh public của `web.gs` mà không cần hỏi lại. Bối cảnh + thứ tự slice: [ROADMAP.md](ROADMAP.md).
> Mọi ví dụ dữ liệu trong file đều là placeholder (`ten@example.com`) — repo PUBLIC, không bao giờ chép data thật vào đây.

## 1. Mục đích & nguyên tắc

Registry = **1 Google Sheet `Bookie Registry 2026`** trên account `bookie.community@gmail.com`, 6 tab, do Apps Script đổ dữ liệu từ form responses về. Nó giải đúng 3 chuyện đang thiếu:

1. **Nguồn guest list cho mail mời T-31** (OPEN item cũ của ROADMAP) → tab `Subscribers`.
2. **Suppression list** — có unsubscribe thì bắt buộc phải có chỗ nhớ ai đã huỷ.
3. **Golden record người tham dự** — 82 form rời rạc không nối về đâu; giờ mọi response chảy về một chỗ, join được theo email.

### Nguyên tắc số 1: Forms = system of record, Sheet = derived index

**Google Forms giữ bản gốc của mọi response. Sheet chỉ là index dựng lại được từ Forms.**

Hệ quả — đây là lý do mọi quyết định phía dưới trông "lỏng lẻo" một cách có chủ ý:

- Xoá nhầm dòng trong `Attendance` **không mất dữ liệu** — rewind watermark là rebuild lại được.
- Watermark chỉ là **optimization**, không phải correctness guarantee. Correctness nằm ở `row_key` set (mục 3).
- `People` là tab **derived hoàn toàn** — rebuild mỗi tick, không giữ state riêng ngoài cột `ghi_chu`.
- Sheet hỏng = phiền, không = thảm hoạ. Thảm hoạ duy nhất = mất account Google (xem risk register trong `ARCHITECTURE.md`).

### Nguyên tắc số 2: hai vai ghi tách bạch

| Ai ghi | Tab | Cột người được đụng |
|---|---|---|
| Script | `Events`, `Attendance`, `Feedback`, `People` | `Events.trang_thai` + `Events.ghi_chu`; `People.ghi_chu` (cột M) |
| Người | `Bookiers` | toàn bộ (script chỉ đọc + update `so_lan_host_2026` ở v2) |
| Cả hai | `Subscribers` | script ghi qua endpoint; người sửa `trang_thai`/`ghi_chu` khi cần |

Script **không bao giờ** xoá dòng ở bất kỳ tab nào. Xoá là việc của người.

Script Property mới: **`REGISTRY_ID`** = id của Sheet này (log ra bởi `setupRegistry()`, mục 8).

---

## 2. Schema 6 tab

Ký hiệu: **PK** = khoá; *(script)* = script ghi; *(người)* = người ghi; ISO = `YYYY-MM-DDTHH:mm:ss+07:00`.

### 2.1 Tab `Events` — 1 dòng / event

Script tạo dòng lúc `doPost` tạo event; sau đó chỉ update các cột state. Team chỉ sửa `trang_thai` + `ghi_chu`.

| Cột | Tên | Kiểu | Ghi bởi | Ghi chú |
|---|---|---|---|---|
| A | `ma_su_kien` | text | script | **PK** — pattern `[A-Z]{2,4}\d+`, prefix theo loại event: `BD` (Book!e Discussion) / `BT` (Book!e Talk) / `GL` (Gala) / `MU` (Meet-up) / `WS` (Workshop). Vd `BT31`, `BD42`, `GL2026`. **Field MỚI BẮT BUỘC trong `event.json`** (`create-form.mjs` gửi lên, không tự sinh). Uppercase. |
| B | `loai_event` | enum | script | `BD` / `BT` / `GL` / `MU` / `WS` — xem bảng mapping ngay dưới |
| C | `ten_su_kien` | text | script | tên sách / chủ đề |
| D | `ngay_gio_iso` | ISO | script | giờ bắt đầu, offset `+07:00` tường minh — script tự nối từ `event.json.ngay_gio_iso.start` (xem bảng mapping dưới) |
| E | `dia_diem` | text | script | |
| F | `calendar_event_id` | text | script | event trên calendar "Bookie Events" |
| G | `folder_id` | text | script | folder per-event trong `Events/` |
| H | `form_dangky_id` | text | script | trống → skip sync stage `dang_ky` |
| I | `form_checkin_id` | text | script | v2 (slice S5) |
| J | `form_feedback_id` | text | script | v2 (slice S5) |
| K | `sync_dangky_at` | ISO | script | **watermark** |
| L | `sync_checkin_at` | ISO | script | watermark |
| M | `sync_feedback_at` | ISO | script | watermark |
| N | `sent_t31_at` | ISO | script | mail mời |
| O | `t31_cursor` | number | script | resume index khi gửi chia đợt (mục 5.4) |
| P | `sent_t1_at` | ISO | script | mail nhắc |
| Q | `sent_t2_at` | ISO | script | mail cảm ơn |
| R | `trang_thai` | enum | **người** | `active` / `huy` / `xong` — `huy` = tick bỏ qua hoàn toàn (không sync, không gửi) |
| S | `ghi_chu` | text | **người** | **script không bao giờ đụng cột này** |

**Mapping `event.json` → tab `Events`** (nguồn duy nhất cho việc này — chỗ khác chỉ link về đây):

| `event.json` field | Cột `Events` | Cách map |
|---|---|---|
| `ma_su_kien` | `ma_su_kien` | copy thẳng, đã uppercase đúng pattern `[A-Z]{2,4}\d+` |
| `loai_event` (display string) | `loai_event` (enum) | `"Book!e Discussion"` → `BD` · `"Book!e Talk"` → `BT` · `"Gala"` → `GL` · `"Meet-up"` → `MU` · `"Workshop"` → `WS` |
| `ten_sach` (nếu BD) hoặc `chu_de` (nếu BT) | `ten_su_kien` | 1-trong-2 tuỳ `loai_event`, không có field `ten_su_kien` riêng trong `event.json` |
| `ngay_gio_iso` | `ngay_gio_iso` | **bắt buộc** trong `event.json` (promote từ optional — cần cho tính T-offset, mục 5). Shape trong `event.json` = object `{start, end}`, giờ local VN `YYYY-MM-DDTHH:MM` **không offset** (`parseIsoVn()` trong `form-dang-ky.gs` reject chuỗi có offset — đừng "sửa giúp"); cột Sheet = `.start` do script **nối thêm** `+07:00` |

**Luật idempotency của mail** (thay cho Script Properties `sent:<id>` ở spec v1 cũ — người xem được, sửa được):

> Chỉ gửi khi cell `sent_*` **trống** VÀ hôm nay **đúng T-offset**. Gửi xong ghi timestamp vào cell.
> **Re-send thủ công = team xoá cell** rồi chờ tick sau (hoặc chạy `syncNow()` → `sendDue()` từ menu).

Cell có timestamp = đã gửi, vĩnh viễn. Không có logic "gửi lại nếu quá X ngày" — tránh mọi khả năng mail bắn 2 lần vào mặt khách.

### 2.2 Tab `Subscribers` — danh sách nhận tin **kiêm suppression list**

| Cột | Tên | Kiểu | Ghi chú |
|---|---|---|---|
| A | `email` | text | **PK** — normalize `trim().toLowerCase()`, **KHÔNG** strip `+tag`, **KHÔNG** bỏ dấu chấm (mục 3) |
| B | `ho_ten` | text | có gì ghi nấy, được rỗng |
| C | `nguon` | enum | `website` / `form-dangky` / `import` / `manual` / `unsub-only` |
| D | `subscribed_at` | ISO | lần đầu vào list |
| E | `trang_thai` | enum | `subscribed` / `unsubscribed` / `pending` / `bounced` / `blocked` |
| F | `unsubscribed_at` | ISO | lần huỷ gần nhất |
| G | `resubscribed_at` | ISO | lần "Hoàn tác" gần nhất |
| H | `last_sent_at` | ISO | script ghi sau mỗi lần gửi marketing |
| I | `so_lan_gui` | number | counter, dùng để soi nghi vấn spam nội bộ |
| J | `ghi_chu` | text | người ghi |

Ý nghĩa 5 trạng thái:

- `subscribed` — nhận mail marketing (T-31).
- `unsubscribed` — **không nhận marketing**, vẫn nhận transactional (T-1/T+2) nếu có đăng ký event. Huỷ nhận tin ≠ từ chối mail xác nhận buổi mình đã đăng ký.
- `pending` — chừa sẵn cho double opt-in (chưa build; tripwire bật: list > 300 hoặc có complaint). v1 single opt-in nên không dòng nào ở trạng thái này.
- `bounced` — mail dội về (bounce hygiene v2). Không gửi marketing.
- `blocked` — **chặn cả transactional**. Dùng cho yêu cầu "đừng liên lạc với tôi nữa" và trường hợp lạm dụng. Chỉ đặt tay.

**Không có cột token.** Token unsubscribe = HMAC tính ra từ email (mục 7) — không lưu, không rò được qua Sheet.

**Unsubscribe từ địa chỉ chưa có dòng** → tạo dòng mới `nguon=unsub-only`, `trang_thai=unsubscribed`. Cần thiết: nếu không, địa chỉ đó có thể bị import lại vòng sau và nhận mail tiếp.

### 2.3 Tab `Bookiers` — roster nội bộ, **NGƯỜI quản**

Script **không tạo, không xoá dòng** ở tab này. Chỉ đọc (để tính audience + `People.la_bookier`), và ở v2 update duy nhất cột `so_lan_host_2026`.

| Cột | Tên | Kiểu | Ghi chú |
|---|---|---|---|
| A | `bookier_id` | text | **PK** — `BKR-001`… **Ổn định khi member đổi email** (lý do tồn tại của cột này) |
| B | `ho_ten` | text | |
| C | `email` | text | email chính, normalize như `Subscribers` |
| D | `email_phu` | text | email thứ hai (trường học/cơ quan) — cũng được match khi tính `la_bookier` |
| E | `sdt` | text | |
| F | `cap_do` | enum | `Hạt Giống` / `Tiềm Năng` / `Cỏ Ba Lá` / `Cỏ Bốn Lá` — theo [`knowledge/03-playbook/bookier.md`](../../knowledge/03-playbook/bookier.md) |
| G | `cap_do_muc_tieu` | enum | cấp độ member đang nhắm kỳ này (cùng enum) |
| H | `vai_tro` | text | Host / MarCom / Ops / … (free text, nhiều vai cách nhau bởi `, `) |
| I | `trang_thai` | enum | `active` / `alumni` / `tam_nghi` |
| J | `ngay_gia_nhap` | date | |
| K | `chu_ky` | text | kỳ/mùa tham gia, vd `2026-H1` |
| L | `nhan_mail_su_kien` | enum | `yes` / `no` — **preference riêng của member**, độc lập với `Subscribers` |
| M | `so_lan_host_2026` | number | script update (v2, đếm từ `Events` + phân vai) |
| N | `ghi_chu` | text | người ghi |

> PII: tab này chứa dữ liệu cá nhân thật → **sống trong Drive, không bao giờ vào repo**. Xem `knowledge/_meta/PII-POLICY.md` § Operational data.

### 2.4 Tab `Attendance` — fact table, **append-only**

1 dòng = 1 lần một người submit 1 stage của 1 event. 5 event = 5 dòng cùng email. Không update, không xoá.

| Cột | Tên | Kiểu | Ghi chú |
|---|---|---|---|
| A | `row_key` | text | `<ma_su_kien>\|<email>\|<stage>` — **dedupe guard** (mục 3) |
| B | `ma_su_kien` | text | |
| C | `ngay_su_kien` | date | denormalized từ `Events.ngay_gio_iso` = **date-part** của ISO đó tính theo offset `+07:00` tường minh (không phải giờ local của máy chạy script) — để pivot/chart không phải VLOOKUP |
| D | `stage` | enum | `dang_ky` / `check_in` |
| E | `email` | text | normalize; từ `getRespondentEmail()` |
| F | `ho_ten` | text | Q3 |
| G | `sdt` | text | Q4 |
| H | `quan_he` | text | Q5 — **self-declared, là claim không phải truth**. Ai cũng tự nhận được "Bookier"; nguồn sự thật về roster là tab `Bookiers`, không phải cột này |
| I | `da_doc` | text | Q6 |
| J | `biet_qua_dau` | text | Q7 |
| K | `cau_hoi` | text | Q8 |
| L | `nhan_tin_moi` | bool | Q9 — checkbox consent (trường #9 mới), đúng 1 lựa chọn, label pin nguyên văn: **"Có, gửi cho mình email về các sự kiện sắp tới của Book!e"**. Mapping **defensive**: `nhan_tin_moi = (mảng response của Q9 KHÔNG rỗng)` — không so sánh chuỗi label. Lý do: response checkbox của Google Forms là mảng các label được tick; nếu ai đó reword label sau này, so sánh chuỗi sẽ lặng lẽ tắt consent dù người dùng đã tick. `true` → upsert vào `Subscribers` với `nguon=form-dangky` |
| M | `submitted_at` | ISO | `response.getTimestamp()` |
| N | `form_id` | text | provenance — biết dòng này rebuild lại được từ form nào |

Form check-in (v2) dùng subset cột: A–G, M, N; các cột Q6–Q9 để rỗng.

### 2.5 Tab `Feedback` — **append-only, theo EVENT không theo người**

Form feedback **cố ý KHÔNG bật collect email** — ẩn danh là load-bearing cho độ thẳng thắn. Vì vậy `Feedback` **không join được với `People`**, và đó là feature, không phải thiếu sót.

| Cột | Tên | Kiểu | Ghi chú |
|---|---|---|---|
| A | `row_key` | text | `<ma_su_kien>\|<response_id>` — `response.getId()`, không có email để làm khoá |
| B | `ma_su_kien` | text | |
| C | `submitted_at` | ISO | |
| D | `hai_long` | number | 1–5 (Q3) |
| E | `cai_thien` | text | Q4 |
| F | `thu_vi` | text | Q5 |
| G | `mong_cho` | text | Q7 |
| H | `tam_su` | text | Q8 |
| I–R | `mod_checkin`, `mod_welcome`, `mod_pitching`, `mod_voting`, `mod_speech`, `mod_qa`, `mod_formative`, `mod_1on1`, `mod_listener`, `mod_summary` | enum | Q6 grid — mỗi module **1 cột riêng**, giá trị `Cũng ổn đấy chứ` / `Không ý kiến` / `Cần cải thiện` |
| S | `ten_tuy_chon` | text | Q9, optional |
| T | `email_tuy_chon` | text | Q10 optional (trường #10 mới) — chỉ để phản hồi riêng; **KHÔNG** upsert sang `Subscribers`, **KHÔNG** join sang `People` |

**Vì sao 10 cột riêng thay vì 1 cột JSON**: để chart xu hướng per-module qua các buổi bằng pivot thuần Sheets — "module Voting 3 buổi liền toàn *Cần cải thiện*" phải nhìn ra được mà không cần code.

### 2.6 Tab `People` — derived, golden record team đọc

**Rebuild mỗi tick** từ `Attendance` + lookup sang `Bookiers`/`Subscribers`. Upsert theo email, **chỉ ghi cột A–L**.

| Cột | Tên | Nguồn |
|---|---|---|
| A | `email` | **PK** |
| B | `ho_ten` | giá trị **mới nhất không rỗng** trong `Attendance` |
| C | `sdt` | mới nhất không rỗng |
| D | `lan_dau` | `min(ngay_su_kien)` |
| E | `lan_gan_nhat` | `max(ngay_su_kien)` |
| F | `so_dang_ky` | count `stage=dang_ky` |
| G | `so_check_in` | count `stage=check_in` |
| H | `ty_le_den` | `so_check_in / so_dang_ky` (số, format % ở Sheet; `so_dang_ky=0` → để rỗng, không chia 0) |
| I | `su_kien_da_du` | list `ma_su_kien` đã check-in, nối bằng `, ` |
| J | `la_bookier` | `true` nếu email khớp `Bookiers.email` **hoặc** `Bookiers.email_phu` |
| K | `nhan_tin` | copy `Subscribers.trang_thai` (không có dòng → rỗng) |
| L | `quan_he_khai_bao` | Q5 mới nhất — nhắc lại: **claim, không phải truth** |
| M | `ghi_chu` | **CHỖ DUY NHẤT team ghi. Script không bao giờ đụng cột M.** |

**Luật rebuild (bắt buộc, đây là nơi dễ ghi đè mất công người nhất):**

1. Đọc header row 1 → build map `{tên_header: index}`. **Match cột theo TÊN HEADER, không theo index cứng.**
2. Thiếu bất kỳ header cần thiết (A–M) → **abort riêng bước `rebuildPeople()`** + self-notify 1 lần, **KHÔNG ghi bừa**. Các bước khác trong tick vẫn chạy.
3. Ghi bằng `setValues` trên range **A:L** (tính từ header map, không hardcode `"A2:L"` nếu thứ tự header khác) — cột M nằm ngoài range ghi theo thiết kế.
4. Email đã có dòng → update tại chỗ (giữ nguyên M). Email mới → append cuối.

### 2.7 Tab phụ `Quarantine` (không thuộc 6 tab chính)

Bãi chứa các request `subscribe` bị chặn bởi rate-cap (mục 6). 4 cột: `at` (ISO) · `email` · `ly_do` (`cap-hourly` / `cap-daily` / `budget-welcome`) · `payload_tom_tat`. Không gửi welcome mail, không vào `Subscribers`. Người soi định kỳ, thấy request thật thì `manual` add tay.

---

## 3. Normalize, dedupe, `row_key`

### 3.1 Normalize email

```
normalizeEmail(s) = String(s).trim().toLowerCase()
```

**Chỉ vậy. KHÔNG strip `+tag`, KHÔNG bỏ dấu chấm trong local-part.**

Vì sao: `a.b@example.com` và `ab@example.com` sẽ là cùng một hộp thư **nếu domain đó là Gmail** (Gmail bỏ qua dấu chấm trong local-part) — chuẩn hoá kiểu đó là áp luật của một provider lên mọi provider, và sẽ merge nhầm 2 người thật ở domain khác. Merge nhầm = mất dữ liệu không undo được; để trùng = thừa 1 dòng, người merge tay được. **Chọn cái sai rẻ hơn.** `auditRegistry()` (mục 8b) flag các cặp near-duplicate cho người quyết định.

Validate: có đúng 1 `@`, phần trước và sau đều không rỗng, phần sau có ít nhất 1 dấu `.`, tổng độ dài ≤ 254 ký tự. Không regex RFC 5322 — vô ích, chỉ tốn thời gian debug.

### 3.2 `row_key` và dedupe guard

| Tab | Công thức |
|---|---|
| `Attendance` | `<ma_su_kien>` + `\|` + `<email đã normalize>` + `\|` + `<stage>` |
| `Feedback` | `<ma_su_kien>` + `\|` + `<response.getId()>` |

Thuật toán dedupe (chạy 1 lần cho mỗi (event, stage), **trước** khi ghi):

1. Đọc toàn bộ cột A của tab đích → `new Set(...)`.
2. Với mỗi response: build `row_key`; đã có trong Set → **skip**; chưa có → push vào mảng ghi **và** `Set.add` ngay (chống trùng trong cùng batch).
3. Ghi cả mảng bằng **một** `setValues`.

**Người submit 2 lần cho cùng event = 1 dòng, first wins.** Bản submit sau vẫn còn nguyên trong Form (system of record) — cần thì đọc tay. Chọn first-wins vì nó khiến sync trở thành phép toán idempotent thuần: chạy lại bao nhiêu lần cũng ra cùng kết quả.

### 3.3 Upsert `Subscribers`

Khoá = email normalize. Có dòng rồi:

| Tình huống | Hành động |
|---|---|
| dòng đang `unsubscribed`, đến từ form/website | **KHÔNG tự bật lại `subscribed`.** Giữ nguyên, chỉ update `ho_ten` nếu đang rỗng. Muốn nhận lại phải bấm "Hoàn tác" (mục 7) — người dùng đã nói *không* một lần rồi. |
| dòng đang `blocked` / `bounced` | không đụng gì cả |
| dòng đang `subscribed` | update `ho_ten` nếu rỗng, không đổi `subscribed_at` |
| chưa có dòng | append, `subscribed_at = now`, `trang_thai = subscribed` |

---

## 4. Hai loại user độc lập + audience & suppression

**Bookier ≠ Subscriber.** Hai tập hoàn toàn độc lập, quản bởi hai chủ thể khác nhau, giao nhau **đúng một chỗ**: lúc tính audience gửi mail.

| | `Bookiers` | `Subscribers` |
|---|---|---|
| Là ai | roster nội bộ, thành viên | khách nhận tin |
| Ai quản | **NGƯỜI** (team) | **script** (endpoint + form consent) |
| Vào bằng cách nào | team thêm tay | tick checkbox #9 / form subscribe trên site / import |
| Ra bằng cách nào | team đổi `trang_thai` | bấm unsubscribe |
| Preference nhận mail | cột `nhan_mail_su_kien` | cột `trang_thai` |

Một người **có thể ở cả hai bảng** (Bookier cũng có thể tự subscribe từ site). Dedupe theo email lúc build audience.

### Bảng audience + suppression (nguồn duy nhất — `ARCHITECTURE.md` và `ROADMAP.md` link về đây)

| Mail | Audience | Chặn bởi |
|---|---|---|
| T-31 mời (marketing) | `Subscribers[subscribed]` ∪ `Bookiers[active, nhan_mail_su_kien=yes]`, dedupe email | full suppression — **unsubscribe LUÔN thắng roster preference** |
| T-1 nhắc (transactional) | registrants của event (từ `Attendance`) | chỉ `blocked` |
| T+2 cảm ơn (transactional) | check-in list nếu có, fallback registrants | chỉ `blocked` |

Đọc kỹ dòng 1: một Bookier `active` có `nhan_mail_su_kien=yes` **nhưng** có dòng `Subscribers` ở trạng thái `unsubscribed` → **KHÔNG gửi**. Preference nội bộ không ghi đè được ý chí đã bày tỏ của người nhận. Điều luật này sẽ bị cãi ("nó là member mà, phải nhận chứ") — câu trả lời: một danh sách marketing mà unsubscribe không có hiệu lực thì không phải là danh sách marketing, mà là spam.

Footer mail do **CODE** nối vào (không nằm trong Doc nội dung → người sửa Doc không xoá nhầm được): marketing = link unsubscribe; transactional = câu "vì sao bạn nhận thư này".

---

## 5. Sync algorithm

### 5.1 Vì sao batch scan chứ không per-form trigger

Apps Script cap **20 trigger / user / script**. 3 form/event × 1 trigger = chết ở event thứ ~6, và chết im lặng. Batch scan = **1 trigger vĩnh viễn** (`dailyMailTick`), rescan là recovery path miễn phí.

### 5.2 Thuật toán

Chạy trong `dailyMailTick()`, **sync TRƯỚC — send SAU, cùng một execution** (để mail T-1 hôm nay thấy được người đăng ký đêm qua):

```
syncAll():
  for each row in Events where trang_thai == "active"
                          and datePart(row.ngay_gio_iso, "+07:00") ∈ [today-14, today+45]:
    for stage in [dang_ky, check_in, feedback]:
      formId    = row[cột form tương ứng]        # trống → skip stage
      targetTab = routing(stage)                  # xem bảng routing dưới
      since     = watermark(stage) − 5 phút        # overlap window, watermark riêng theo stage (mục 2.1)
      responses = FormApp.openById(formId).getResponses(since)
      seen      = Set(cột A của targetTab)
      rows      = responses.map(→ row theo schema targetTab).filter(key ∉ seen)
      if rows.length: targetTab.getRange(...).setValues(rows)   # MỘT lần
      watermark(stage) = now
  rebuildPeople()
```

Cửa sổ `[today-14, today+45]` tính trên **date-part** của `Events.ngay_gio_iso` theo offset `+07:00`: bọc T-45 (mở event) tới T+3 (reflection) + dư buffer; event cũ hơn 14 ngày không còn response mới. Event `trang_thai != active` bị bỏ qua hoàn toàn.

**Routing per stage** — loop ở trên gộp 3 stage nhưng chúng KHÔNG cùng đích, tách rõ để khỏi conflate:

| Loop `stage` | Tab đích | `row_key` | Cột watermark (`Events`) |
|---|---|---|---|
| `dang_ky` | `Attendance` | `<ma_su_kien>\|<email>\|dang_ky` | `sync_dangky_at` |
| `check_in` | `Attendance` | `<ma_su_kien>\|<email>\|check_in` | `sync_checkin_at` |
| `feedback` | `Feedback` | `<ma_su_kien>\|<response_id>` — **không có email** | `sync_feedback_at` |

**Lưu ý**: biến loop `stage` ở pseudocode trên (3 giá trị: `dang_ky`/`check_in`/`feedback`, gắn với 3 form nguồn) **không phải cùng một khái niệm** với enum `Attendance.stage` (mục 2.4) — enum đó chỉ có 2 giá trị (`dang_ky`/`check_in`), vì `feedback` không ghi vào tab `Attendance` mà ghi sang tab `Feedback` riêng (không có cột `stage`).

**`setValues` một lần, KHÔNG `appendRow` trong loop.** `appendRow` mỗi call là một round-trip có flush — cách kinh điển để nổ giới hạn 6 phút/execution khi số event tăng.

### 5.3 Watermark semantics — đọc kỹ trước khi tin nó

`FormApp.getResponses(afterDate)` có **boundary mờ**: không tài liệu nào cam kết inclusive/exclusive, và timestamp response so với thời điểm nó nhìn thấy được có độ trễ. Vì vậy:

> **Watermark chỉ là optimization. `row_key` set mới là correctness guarantee.**

Kéo theo 3 hệ quả ghi thẳng vào code + runbook:

1. Trừ **5 phút overlap** trước mỗi lần quét — thà đọc trùng (đã có dedupe) còn hơn miss.
2. Watermark trống → coi như `new Date(0)`, quét toàn bộ form. Không phải case lỗi.
3. **Rewind watermark về 1970 là thao tác AN TOÀN** — chỉ tốn thời gian chạy, không sinh dòng trùng. Đây là recovery path chính thức khi nghi ngờ data thiếu.

### 5.4 Error isolation

- `try/catch` **per (event, stage)**. Form bị xoá / bị unshare / id sai → log + **self-notify 1 lần** (dedupe theo `ma_su_kien+stage` trong Script Properties, tránh spam chính mình mỗi ngày) → **tiếp tục event khác**. Một event hỏng không được kéo cả tick chết.
- **`LockService.getScriptLock()` bọc mọi write path**, timeout ~10s: `syncAll`, `rebuildPeople`, `sendDue`, và cả `doPost` nhánh subscribe/unsubscribe. Lấy lock thất bại ở web app → trả `{ok:false, error:"busy"}` (client retry được); ở trigger → bỏ tick, ngày mai chạy lại.
- Heartbeat: **không có cột/cell `last_tick_at` trong Sheet** — chốt = Script Property `LAST_TICK_AT`, `dailyMailTick()` ghi timestamp hiện tại vào đó ở **cuối mỗi lần chạy** (kể cả khi một số event lỗi, miễn tick tự nó chạy xong). Staleness (`LAST_TICK_AT` cũ hơn 48h) do `auditRegistry()` (mục 8b) phát hiện → self-notify mail — trigger chết im lặng là failure mode khó thấy nhất.
- **Menu item `syncNow()`** (`onOpen` → custom menu "Bookie") để team chạy tay ngày diễn ra event, không phải chờ tick 08:00.

---

## 6. Contract endpoint public (`web.gs`, `doPost` router)

Router hiện tại kiểm `SECRET` **trước mọi thứ**. Sửa thành: **nhánh public đi TRƯỚC secret gate**, các action cũ giữ nguyên phía sau gate — không đụng gì tới `form-dang-ky.gs`.

```
doPost(e):
  body = JSON.parse(e.postData.contents)
  if body.action in [subscribe, unsubscribe, resubscribe]:   → nhánh public
  if body.secret !== SECRET: return {ok:false, error:"unauthorized"}
  ... (các action cũ)
```

### 6.1 `action=subscribe` (PUBLIC)

**Transport — bẫy đã trả giá một lần, ghi rõ để khỏi tái phát hiện:**

> Client gửi JSON qua `Content-Type: text/plain` (simple request, **không** preflight).
> **`application/json` = FAIL** — trình duyệt bắn preflight `OPTIONS`, **Apps Script không trả lời `OPTIONS`**, request chết trước khi tới code.

```js
fetch(WEBAPP_URL, {
  method: "POST",
  headers: { "Content-Type": "text/plain;charset=utf-8" },
  body: JSON.stringify({ action: "subscribe", email, ho_ten, website, ts_render })
})
```

Payload:

| Field | Bắt buộc | Ý nghĩa |
|---|---|---|
| `email` | ✔ | |
| `ho_ten` | | |
| `website` | | **honeypot** — input ẩn bằng CSS. Non-empty → trả `{ok:true}` **giả**, không ghi gì, không log ầm ĩ |
| `ts_render` | | epoch ms lúc render form. `now − ts_render < ~2000ms` = bot → xử lý như honeypot |
| `cf_token` | | chừa sẵn cho Cloudflare Turnstile — bật sau **không phải đổi page** |

Validation server-side (không tin client): syntax email (mục 3.1) · ≤ 254 ký tự · `action` trong whitelist · `ho_ten` cắt ở 100 ký tự.

**Welcome mail** (gửi ngay sau khi `subscribe` ghi thành công vào `Subscribers`): nội dung lấy từ Google Doc **`[Mail] Chào mừng`** trong thư mục `Templates/` (duyệt nội dung 1 lần bởi người — human gate giữ nguyên như các mail khác), id Doc đó nằm ở Script Property **`MAIL_WELCOME_DOC_ID`**. Thiếu `MAIL_WELCOME_DOC_ID` hoặc không mở được Doc → **không gửi welcome, nhưng subscribe vẫn được ghi nhận bình thường** vào `Subscribers` (không rollback vì thiếu mail phụ) — log lại để người biết mà điền Script Property.

**Abuse controls** — web app **không thấy IP client**, nên không rate-limit theo IP được. Thay bằng cap toàn cục qua `CacheService`:

| Cap | Giá trị | Vượt thì |
|---|---|---|
| global / giờ | ~30 | ghi `Quarantine`, không gửi welcome |
| global / ngày | ~100 | ghi `Quarantine`, không gửi welcome |
| budget welcome-mail / ngày | ~20 (counter ở Script Property, reset theo ngày) | ghi `Subscribers` bình thường nhưng **không gửi welcome** — **bảo vệ quota cho mail transactional** |

Cap toàn cục có nghĩa một kẻ spam có thể làm nghẽn đăng ký thật trong 1 giờ. Chấp nhận được ở quy mô này (list < 100); đổi lại tuyệt đối không có đường để 1 script bên ngoài đốt sạch quota 100 mail/ngày của account.

Response — đọc được ở trình duyệt nhờ redirect sang `script.googleusercontent.com` có header `Access-Control-Allow-Origin: *`:

| Case | Body |
|---|---|
| OK | `{ok:true, status:"subscribed"}` |
| OK, đã có sẵn | `{ok:true, status:"already"}` |
| honeypot / bot | `{ok:true, status:"subscribed"}` ← **giả, cố ý** |
| email sai | `{ok:false, error:"invalid_email"}` |
| quá cap | `{ok:true, status:"queued"}` (đã vào `Quarantine`) |
| lock fail | `{ok:false, error:"busy"}` |

Web app **không set được HTTP status code** → mọi lỗi đi qua body, giống contract sẵn có của `form-dang-ky.gs`.

### 6.2 `action=unsubscribe` / `resubscribe` (PUBLIC, token-gated)

Payload: `{action, email, token}`. Xác thực: tính lại token từ `email` đã normalize, so bằng **constant-time compare**. Sai → `{ok:false, error:"invalid_token"}`, không tiết lộ email có tồn tại hay không.

Đúng → set `trang_thai` + timestamp tương ứng; email chưa có dòng → tạo dòng `nguon=unsub-only`. Response: `{ok:true, status:"unsubscribed"}` / `{ok:true, status:"subscribed"}`. **Idempotent** — bấm 5 lần vẫn OK.

---

## 7. Unsubscribe token

```
token = base64url( HmacSHA256("unsub:" + email_normalized, UNSUB_SECRET) ).slice(0, 22)
```

- `Utilities.computeHmacSha256Signature(...)` → `Utilities.base64EncodeWebSafe(...)` → cắt 22 ký tự (~132 bit, thừa sức chống brute-force cho use case này).
- **`UNSUB_SECRET` là Script Property MỚI, TÁCH khỏi `SECRET`** hiện có. Lý do: `SECRET` là khoá ghi toàn quyền của `create-form.mjs`; token unsubscribe nằm trong link gửi ra ngoài cho hàng chục người. Không bao giờ derive khoá public từ khoá admin.
- **Stateless** → đúng cho **mọi** địa chỉ, kể cả địa chỉ chưa từng có dòng trong `Subscribers`. Không cần lookup, không cần lưu.
- **Không expire.** Unsubscribe phải idempotent + reversible; token hết hạn = người bấm link trong mail cũ 3 tháng thì bị chặn — đúng thứ mà spam filter và người dùng đều ghét.

**Hai route:**

1. **Chính** — footer trỏ tới `<SITE_URL>/huy-nhan-tin?e=<email>&t=<token>`. Trang tĩnh trên site, **1 nút bấm** rồi mới POST về web app.
2. **Fallback** — GET thuần Apps Script 2 bước: `?action=unsubscribe&e=…&t=…` → `doGet` render trang confirm bằng `HtmlService` + nút bấm → bấm mới thực thi.

**Vì sao 2 bước, không phải 1-click GET**: link scanner của Gmail/Outlook/antivirus **prefetch** mọi URL trong mail. GET-thực-thi = có người bị huỷ nhận tin mà không hề bấm gì. Bước xác nhận thủ công là hàng rào chống prefetch. (`SITE_URL` = Script Property mới; site chưa lên thì route 2 gánh tạm.)

Trang confirm sau khi huỷ có link **"Hoàn tác"** → `resubscribe` với **cùng token** (token buộc vào email, không buộc vào hành động).

> **Rotate `UNSUB_SECRET` = vô hiệu hoá MỌI link unsubscribe đã gửi đi.** Chỉ rotate khi secret bị lộ, và khi rotate thì phải chấp nhận: người nhận mail cũ bấm huỷ sẽ thấy `invalid_token` → phải xử lý tay. Ghi trong runbook, không phải việc làm định kỳ.

**Giới hạn đã biết**: `MailApp` **không set được header `List-Unsubscribe`** → nút "Unsubscribe" native của Gmail không hiện. Escape hatch: Gmail advanced service (v2, cần verify) — xem `ARCHITECTURE.md` § escalation ladder.

---

## 8. Contract `setupRegistry()`

Hàm one-time chạy tay từ editor (**Run ▸ chọn hàm**), **không** thuộc web app — cùng pattern với `setupTemplateForm()` / `setupEventsCalendar()` sẵn có.

Việc phải làm, theo thứ tự:

1. `SpreadsheetApp.create("Bookie Registry 2026")`.
2. Tạo 6 tab + tab phụ `Quarantine`, đúng tên và **đúng thứ tự cột** ở mục 2. Xoá sheet mặc định `Sheet1`.
3. Ghi header row 1 cho từng tab (tên cột = tên trong bảng, snake_case tiếng Việt không dấu).
4. **Freeze row 1** (`setFrozenRows(1)`) mọi tab + bold header.
5. **Data validation enum** cho các cột enum: `Events.trang_thai`, `Subscribers.trang_thai`, `Subscribers.nguon`, `Bookiers.cap_do`, `Bookiers.cap_do_muc_tieu`, `Bookiers.trang_thai`, `Bookiers.nhan_mail_su_kien`, `Attendance.stage`, `Feedback.mod_*` (10 cột) — `requireValueInList(..., true)`, `setAllowInvalid(false)`.
6. **Range protection**: bảo vệ `Attendance` và `Feedback` toàn tab (append-only, người không có việc gì phải sửa) + cột A–L của `People`; chừa `People!M:M`, `Events!R:S`, toàn bộ `Bookiers`, `Subscribers` cho người. Protection ở đây là **hàng rào chống tay trượt**, không phải security — người có quyền vẫn gỡ được.
7. Format: `ngay_gio_iso`/`submitted_at`/watermark = plain text (tránh Sheets tự parse date lệch timezone); `ty_le_den` = percent; cột dài (`cau_hoi`, `tam_su`) = wrap clip.
8. `moveTo` folder `Bookie 2026/Admin/`.
9. **`Logger.log("REGISTRY_ID = " + ss.getId())`** + log việc còn lại: điền `REGISTRY_ID`, `UNSUB_SECRET` (`openssl rand -hex 24`), `SITE_URL` vào Script Properties.

Chạy lại khi Sheet đã tồn tại: hàm **không** tạo trùng — check `REGISTRY_ID` trong Script Properties trước, có rồi thì chỉ **bổ sung tab/header còn thiếu** (idempotent) và log ra cái nó vừa thêm.

### Luật an toàn manual-edit (bắt buộc, mọi hàm đọc/ghi Sheet)

1. **Lookup cột theo TÊN HEADER, không theo index cứng.** Người sẽ chèn cột — đó là chuyện *khi nào*, không phải *có hay không*.
2. Thiếu header cần thiết → **abort bước đó + self-notify**, không đoán, không ghi bừa. Ghi sai cột còn tệ hơn không ghi.
3. **Cột `People!M` (`ghi_chu`) là bất khả xâm phạm** — range ghi luôn dừng ở `L`. Đây là chỗ duy nhất công sức của người sống trong tab derived; ghi đè nó một lần là mất niềm tin vĩnh viễn vào hệ.
4. Range protection cho `Attendance`/`Feedback` (bước 6) — hai tab append-only, sửa tay ở đó làm hỏng dedupe.
5. Đổi tên tab = hệ gãy → tên tab hardcode trong constants, log lỗi rõ ràng khi `getSheetByName` trả `null`.

### 8b. Contract `auditRegistry()`

Chạy tay hoặc theo lịch tháng (không phải một phần của `dailyMailTick()`). **Chỉ đọc, không ghi Sheet** — mọi kết quả gói vào **1 mail self-notify duy nhất** gửi về `bookie.community@gmail.com`, người đọc rồi tự xử lý (xem mục 9). Các mục kiểm tra:

1. **Near-duplicate email** — cùng `ho_ten` (hoặc gần giống) nhưng khác `email` trong `Subscribers`/`People`, gợi ý các cặp nghi trùng (kiểu `a.b@example.com` vs `ab@example.com`). Không tự merge — chỉ liệt kê cho người quyết định.
2. **Orphan** — dòng có trong `Attendance` (theo email) nhưng sau khi `rebuildPeople()` chạy xong lại không thấy dòng tương ứng trong `People`. Dấu hiệu bug ở `rebuildPeople()`, cần soi ngay.
3. **`Events` thiếu form id** — dòng `trang_thai=active` mà `form_dangky_id` trống (hoặc `form_checkin_id`/`form_feedback_id` trống với event đã qua ngày tương ứng) → event đó đang bị `syncAll()` âm thầm skip stage.
4. **Heartbeat stale** — Script Property `LAST_TICK_AT` (mục 5.4) cũ hơn **48h** so với thời điểm chạy `auditRegistry()`.

Kết quả gộp thành 1 mail tổng hợp; **không ghi gì vào Sheet** (kể cả `Quarantine`) — đây là báo cáo cho người, không phải state của hệ.

---

## 9. Operator runbook

| Tình huống | Thao tác |
|---|---|
| **Re-send 1 mail** | Xoá cell `sent_t31_at` / `sent_t1_at` / `sent_t2_at` của dòng event đó trong `Events` → chờ tick 08:00 hoặc chạy `sendDue()` tay. Nhớ: điều kiện gửi là **cell trống VÀ đúng T-offset** — quá ngày rồi thì xoá cell không đủ, phải gọi hàm gửi tay. |
| **Sync thiếu / nghi ngờ thiếu dòng** | Xoá cell watermark (`sync_*_at`) của event → tick sau quét lại từ đầu. **An toàn tuyệt đối**, dedupe theo `row_key` lo phần còn lại. Gấp thì menu **Bookie ▸ Sync now**. |
| **Merge duplicate email** | `auditRegistry()` (mục 8b, chạy tháng/tay) flag các cặp near-duplicate (`a.b@example.com` vs `ab@example.com`, khác nhau chỉ ở dấu chấm) → **người quyết định merge**, script không tự merge. Merge = giữ 1 dòng `Subscribers`, sửa `Attendance` để trống thì cứ để (lịch sử là fact, không viết lại). |
| **Xử lý bounce** (v2) | `GmailApp.search("from:mailer-daemon newer_than:7d")` → parse địa chỉ → set `Subscribers.trang_thai = bounced`. Chưa build thì làm tay khi thấy mail dội. |
| **Yêu cầu "đừng liên lạc nữa"** | Set `trang_thai = blocked` tay. Khác `unsubscribed` ở chỗ chặn cả transactional. |
| **Yêu cầu xoá dữ liệu cá nhân** | Đúng thứ tự, không đảo: **(1)** xoá response gốc trong **TỪNG Google Form** liên quan đến người đó **TRƯỚC** (Forms = system of record — không xoá ở đó thì tick sau `syncAll()` tái tạo lại dòng). **(2)** Sau đó xoá dòng khớp email ở `People`, `Subscribers`, `Bookiers`, `Attendance`, và `Feedback` nếu `email_tuy_chon` khớp (Feedback không có cột email chính — chỉ xoá được nếu người đó có điền field #10 optional). Ghi chú: xoá cả dòng ở `Subscribers` (suppression) nghĩa là người đó **có thể quay lại list** nếu sau này tự đăng ký mới — đây là đánh đổi đã chấp nhận, không phải bug. Xem `knowledge/_meta/PII-POLICY.md`. |
| **Restore Sheet** | Drive ▸ File ▸ Version history (giữ 30 ngày). Hỏng nặng hơn: **`Attendance`/`Feedback` rebuild được từ forms** — tạo Sheet mới bằng `setupRegistry()`, điền lại `Events` (form id lấy từ `event.json` trong repo), rewind toàn bộ watermark. **FORMS LÀ SYSTEM OF RECORD, SHEET CHỈ LÀ DERIVED INDEX.** `Bookiers` + cột `People!M` là hai thứ **duy nhất** không rebuild được → đó là thứ đáng backup tay (export CSV định kỳ). |
| **Rotate `UNSUB_SECRET`** | **Chỉ khi bị lộ.** Mọi link unsubscribe đã gửi chết ngay. Sau khi rotate: theo dõi mail phản ánh, xử lý huỷ tay. |
| **Cập nhật code** | `Deploy ▸ Manage deployments ▸ ✎ ▸ New version` (đổi **version** của deployment hiện có, **không tạo deployment mới**) — **URL giữ nguyên**. ⚠ **Tạo deployment MỚI = đổi URL = form subscribe trên site chết IM LẶNG** (site vẫn hiện "đăng ký thành công", data đi vào hư vô). **Nếu** vì lý do nào đó URL exec đổi, phải sửa **ĐÚNG 2 chỗ**, cùng lúc: `site/src/config.ts` (fetch target phía front-end) và `.env` key `BOOKIE_FORM_WEBAPP_URL` (dùng bởi `create-form.mjs`). |

---

> Liên quan: [ROADMAP.md](ROADMAP.md) (thứ tự slice, mail scheduler) · [README.md](README.md) (deploy, form đăng ký) ·
> `ARCHITECTURE.md` (2 ranh giới cứng, risk register, bảng quota verified) ·
> [`bieu-mau-dang-ky.md`](../../projects/bd-2026/plan/bieu-mau-dang-ky.md) (trường #9 consent) ·
> [`bieu-mau-feedback.md`](../../projects/bd-2026/plan/bieu-mau-feedback.md) (trường #10 email optional).
