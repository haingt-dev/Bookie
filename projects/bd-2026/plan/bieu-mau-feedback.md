# Biểu mẫu Feedback sau sự kiện — Book!e Discussion

Spec để dựng Google Form thu feedback sau buổi Book Discussion/Book Talk. Điểm mạnh của form: tách nhỏ đánh giá theo từng module chương trình thay vì chỉ hỏi "hài lòng chung chung" — nhờ đó biết chính xác bước nào cần cải thiện. Team dựng form copy đúng thứ tự trường bên dưới.

## Các trường của form (theo thứ tự)

| # | Tên trường | Loại câu hỏi | Bắt buộc | Ghi chú |
|---|-----------|-------------|----------|---------|
| 1 | Timestamp | Tự động (Google Form) | Tự động | Không cần tạo thủ công |
| 2 | Sự kiện được feedback | Multiple choice / Dropdown | Bắt buộc | Điền tên buổi cụ thể, vd [Book Discussion — "Tên sách", Ngày] |
| 3 | Mức độ hài lòng | Scale (thang 1-5) | Bắt buộc | 1 = rất không hài lòng, 5 = rất hài lòng |
| 4 | Điều muốn cải thiện | Text (trả lời mở, đoạn dài) | Không bắt buộc | |
| 5 | Điều thấy thú vị | Text (trả lời mở, đoạn dài) | Không bắt buộc | |
| 6 | Đánh giá riêng từng module chương trình | Multiple choice (grid) | Bắt buộc | Mỗi module chọn 1 trong 3: "Cũng ổn đấy chứ" / "Không ý kiến" / "Cần cải thiện" — xem danh sách module bên dưới |
| 7 | Mong chờ ở hoạt động tiếp theo | Text (trả lời mở, đoạn dài) | Không bắt buộc | |
| 8 | Chỗ tâm sự tự do | Text (trả lời mở, đoạn dài) | Không bắt buộc | |
| 9 | Tên | Text (câu trả lời ngắn) | Không bắt buộc (optional) | |

### Trường #6 — danh sách module cần đánh giá riêng

Mỗi module là một dòng trong grid, đáp án chọn 1 trong 3: **"Cũng ổn đấy chứ" / "Không ý kiến" / "Cần cải thiện"**:

- [ ] Checkin
- [ ] Welcome
- [ ] Pitching
- [ ] Voting
- [ ] Speech
- [ ] Q&A
- [ ] Formative Evaluation
- [ ] Discussion 1on1
- [ ] Listener Questions
- [ ] Summary + Photo

## Checklist dựng form (Google Form)

- [ ] Copy đúng thứ tự 9 trường ở trên
- [ ] Trường #2 (Sự kiện) — cập nhật tên buổi hiện tại: [Tên buổi], [Ngày]
- [ ] Trường #3 — set thang Linear scale 1-5
- [ ] Trường #6 — dựng dạng "Multiple choice grid": 10 dòng module × 3 cột đáp án
- [ ] Set bắt buộc (Required) đúng theo cột "Bắt buộc" ở bảng trên
- [ ] Gửi link form ngay sau khi kết thúc sự kiện (trong lúc network/wrap-up hoặc qua kênh sau sự kiện)
- [ ] Sau khi đóng form, tổng hợp kết quả vào sheet feedback chung để theo dõi xu hướng qua các buổi

## Insight thường gặp từ các đợt feedback trước

Tham khảo khi thiết kế nội dung câu hỏi mở / diễn giải kết quả — đây là các insight vận hành đã ghi nhận (ẩn danh), KHÔNG phải checklist bắt buộc:

- Câu hỏi check-in dành cho diễn giả đôi khi chưa phù hợp → cần điều chỉnh nội dung câu hỏi.
- Đề xuất tổ chức training **facilitation skills** cho host để nâng chất lượng dẫn dắt buổi BD/BT.
- Mong Bookie cải thiện truyền thông để tiếp cận nhiều người tham dự hơn.
- Đề xuất hoạt động tiếp theo: thử thách đọc sách, viết review, nhóm đọc & thảo luận.
- Trải nghiệm tích cực được ghi nhận: 2 người đọc 2 bản dịch khác nhau (Việt/Anh) của cùng cuốn sách vẫn có trải nghiệm tương đồng.

---

> Nguồn: chưng cất từ [BD playbook](../../../knowledge/03-playbook/quy-trinh-van-hanh.md)
