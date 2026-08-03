# Bookie Design System — đồ hoạ sự kiện bán tự động

Hệ 2 tầng thay cho việc thiết kế tay mỗi event (Photoshop/Canva):

| Tầng | Công cụ | Tính chất |
|---|---|---|
| Nền minh hoạ theo chủ đề | `/gen-art` (cloud, anchor Bookie, prompt **không chữ**) | Sáng tạo có kiểm soát |
| Layout + logo + chữ Việt + khổ | Template HTML/CSS → headless Chrome → PNG | Khoá cứng, lặp lại được |

**Template là sản phẩm, mỗi event chỉ là dữ liệu**: điền 1 file `event.json`, render ra đủ khổ.
Chữ tiếng Việt là Unicode + font thật (Be Vietnam Pro self-host, đủ glyph — đã stress-test
`Ậ ẫ ể Ệ Ộ Ỡ Ữ…`) nên không bao giờ sai dấu — khác với để AI "vẽ" chữ.

## Dùng nhanh

```bash
cd shared/design-system
node render.mjs --template poster-feed --data <event.json>
node render.mjs --template cover-event --data <event.json> --out ../../projects/<event>/output/
node render.mjs --template cover-event --data <event.json> --debug-safe-area   # xem vùng an toàn
```

Cần `google-chrome-stable`/`chromium` trên máy (script tự dò, override bằng `CHROME_BIN`).
Skill **`/event-graphics`** chạy trọn flow: điền data → sinh nền → render → tự review.
Form đăng ký + QR cho event: skill **`/event-form`** (chạy TRƯỚC — ghi `dang_ky`/`qr` vào
event.json, xem `../event-automation/README.md`).

## Schema `event.json` (chung cho mọi khổ)

| Field | Bắt buộc | Ghi chú |
|---|---|---|
| `ma_su_kien` | ✓ | Mã event, prefix theo loại event `[A-Z]{2,4}\d+` (BD/BT/GL/MU/WS), vd `BT31`, `GL2026` — primary key xuyên hệ (registry Sheet, slug website, folder Drive per-event). Public data by definition |
| `loai_event` | ✓ | Badge: "Book!e Discussion", "Book!e Talk"… |
| `ten_sach` | ✓ | Tiêu đề lớn — tự co chữ khi dài (`data-fit`) |
| `tac_gia` | | Ẩn hàng nếu rỗng |
| `chu_de` | | Eyebrow chip cam — câu hook/chủ đề |
| `ngay_gio` | ✓ | Ví dụ: `09:00 · Chủ nhật · 27/07/2026` |
| `dia_diem` | ✓ | |
| `dien_gia` | | Chỉ role label / tên đã công bố công khai (PII policy) |
| `dang_ky` | ✓ | Link NGẮN hiển thị trên CTA — `/event-form` tự ghi (forms.gle); quá dài thì template tự co chữ |
| `hashtag` | | KHÔNG in lên poster (badge `loai_event` đã nói điều đó) — dùng cho caption bài đăng/comms. Chuẩn casing: `#BookieDiscussion` |
| `bg` | | Đường dẫn ảnh nền (tương đối so với file data); rỗng = gradient brand |
| `qr` | | Đường dẫn QR đăng ký (SVG, tương đối so với file data) — poster gắn ô "Quét để đăng ký" vào cột phải info-card **và ẩn pill link** (link full để trong caption bài đăng); rỗng = pill như cũ. `/event-form` tự sinh + ghi |
| `ngay_gio_iso` | ✓ | `{"start":"YYYY-MM-DDTHH:MM","end":"…"}` — cho `/event-form` build link Google Calendar. Bắt buộc từ S2: mail scheduler tính T-offset từ field này. Giờ local VN **không offset** (đúng format `parseIsoVn()` chấp nhận — automation tự nối `+07:00` khi ghi registry) |
| `form_edit_url` `form_published_url` `calendar_link` `calendar_event_id` | | Do `/event-form` ghi ngược — đừng điền tay (xem `shared/event-automation/README.md`) |

## Khổ (templates/)

| Template | Khổ | Nguồn spec (verify 07/2026) |
|---|---|---|
| `poster-feed` | 1080×1350 (4:5) | Hiển thị nguyên khổ trên mobile feed — không cần safe zone |
| `cover-event` | 1920×1005 (1.91:1) | Mobile crop hai bên + UI đè dải đáy → **mọi chữ/logo nằm trong safe rect** (~1000×605 giữa-trên, khai báo trong `config.json`); nền tràn full-bleed. Nguồn: Snappa 01/2026 · postfa.st 04/2026 · Moda 03/2026 |

**Thêm khổ mới**: copy một thư mục template, sửa `config.json` (width/height/safe) +
layout trong `template.html`. Token brand import từ `../../tokens/tokens.css` — không hardcode màu/font.

### `email/` — brand email template (spec, chưa build)

Build ở slice **S3** (xem `shared/event-automation/ROADMAP.md`) — mục này chỉ ghi khung đã chốt để build không lệch thiết kế.

Khung brand cố định, **duyệt 1 lần**, dùng chung cho cả 3 mail (mời T-31 / nhắc T-1 / cảm ơn T+2):

- Logo header
- Tiêu đề
- Content slots — nhận đoạn văn từ Google Doc đã duyệt (đoạn → `<p>`, link tự nhận)
- Ảnh poster
- Nút CTA "Đăng ký"
- Footer — do **code nối vào** (không nằm trong Doc → người sửa Doc không xoá nhầm được): unsubscribe (mail marketing) hoặc lý-do-nhận-thư (mail transactional)

Ràng buộc email-HTML (mail client không phải trình duyệt):

- **Table-based layout + inline CSS** — mail client không hỗ trợ flexbox/grid
- **Tổng dung lượng mail < 102KB** (Gmail clip mail dài hơn)
- **Font = system stack fallback** — Be Vietnam Pro không load được trong mail client, chỉ dùng cho web/poster
- Ảnh **v1 = `inlineImages` CID**; chuyển sang ảnh host trên `bookiecommunity.com` sau khi site chạy (S6)

Dùng chung tokens brand với poster/cover/web (`tokens/tokens.css`) — 1 nguồn brand → 4 kênh.

## Nền gen-art

- Profile: `.claude/imagegen/profile.toml` + art-direction trong `.claude/imagegen/anchor.txt`
  (mọi nền sinh ra tự cùng vibe brand). Key: `OPENAI_API_KEY` trong `Bookie/.env` (gitignored,
  xem `.env.example`).
- gpt-image-2 chỉ có 3 khổ → quy ước: **dọc `1024x1536`** cho poster, **ngang `1536x1024`**
  cho cover (template `background-size: cover` tự crop). Sinh mỗi hướng một ảnh, cùng prompt.
- Ladder: `--quality low` để chọn vibe (2–3 candidates vào `backgrounds/raw/`, gitignored) →
  bản chốt regen `high` → lưu `backgrounds/final/` (commit — thư viện nền tái dùng giữa các event).
- Prompt luôn KHÔNG chữ (anchor đã ép) — chữ do template đè lên.

## Quy ước

- Repo PUBLIC → data + ảnh commit phải PII-clean (role label, không tên/contact thành viên).
- PNG thành phẩm của event cụ thể → `projects/<event>/output/` (không commit); `out/` ở đây
  chỉ là chỗ render thử (gitignored).
- Màu/font/spacing sửa MỘT nơi: `tokens/tokens.css` (nguồn: Bookie Branding Guideline).
