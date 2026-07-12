# BD 2026 — Book!e Discussion Event Kit

Bộ kit tổ chức một buổi **Book!e Discussion** (BD) — chưng cất từ [BD playbook](../../knowledge/03-playbook/book-discussion.md) trong knowledge base của tổ chức. Mỗi file là một template làm việc: copy ra, điền [placeholder], dùng ngay.

> Tên `bd-2026` là tên tạm — đổi khi dự án có tên chính thức.

## Status

- Created: 2026-07-11
- Status: **Incubating**

## Event kit

### `plan/` — ban Operation

| File | Dùng để |
|---|---|
| [de-xuat-de-tai.md](plan/de-xuat-de-tai.md) | Proposal 8 mục cho Host đề xuất đề tài buổi BD |
| [checklist-chuan-bi.md](plan/checklist-chuan-bi.md) | Checklist 27 đầu việc T-45 → T+3, vocab trạng thái + luật delay-tracking |
| [phan-cong-vai-tro.md](plan/phan-cong-vai-tro.md) | Bảng 8 vai trò trong buổi + trình tự phối hợp, deadline T-10/T-7 |
| [bieu-mau-dang-ky.md](plan/bieu-mau-dang-ky.md) | Spec form gốc đăng ký — `/event-form` tự clone + điền per-event, không copy tay |
| [bieu-mau-feedback.md](plan/bieu-mau-feedback.md) | Spec dựng Google Form feedback sau sự kiện |

### `content/` — Host / MC

| File | Dùng để |
|---|---|
| [kich-ban-chuong-trinh.md](content/kich-ban-chuong-trinh.md) | Rundown: flow 10 phần, agenda theo phút, hệ thẻ G/Y/R, khung 12 slide MC |
| [cau-hoi-thao-luan.md](content/cau-hoi-thao-luan.md) | Khung câu hỏi: warm-up → Q&A → thảo luận nhóm (3 format mẫu) → review |
| [khung-danh-gia-cr.md](content/khung-danh-gia-cr.md) | Khung Comment–Recommendation cho Evaluator đánh giá speaker |

### `comms/` — ban MarCom

| File | Dùng để |
|---|---|
| [email-moi.md](comms/email-moi.md) | Mail mời tham dự (mail 1) |
| [email-nhac-1-ngay.md](comms/email-nhac-1-ngay.md) | Mail nhắc "còn 1 ngày" (mail 2) + checklist chống bug copy-template |
| [bai-dang-fb.md](comms/bai-dang-fb.md) | Bài công bố + teaser T-7/T-1 + 3 biến thể recap |
| [thu-cam-on.md](comms/thu-cam-on.md) | Thư cảm ơn khách tham dự (T+2) |

### Thư mục khác

- `assets/` — event.json + QR + ảnh/file thiết kế của sự kiện (form + QR sinh bằng `/event-form` từ [event-automation](../../shared/event-automation/README.md); poster/cover sinh bằng `/event-graphics` từ [design system](../../shared/design-system/README.md))
- `output/` — deliverables cuối, gồm comms đã điền từ template (không commit)

## Quy ước

- Repo này **PUBLIC** — mọi thứ commit vào đây phải PII-clean theo [PII-POLICY](../../knowledge/_meta/PII-POLICY.md): chỉ role label (Host, MC, Operation Lead…), không tên thành viên/contact cá nhân.
- Template là bản gốc — làm event cụ thể thì copy sang thư mục làm việc (hoặc `output/`) rồi điền, đừng sửa đè bản gốc.
- Tri thức nền (lịch sử BD, mô hình 3 thế hệ, bài học rút ra) nằm ở playbook trong `knowledge/` — kit này chỉ chứa phần dùng-ngay.
