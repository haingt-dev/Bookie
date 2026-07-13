# Tin nhắn Zalo — mở group khởi động chuỗi BT

> Placeholder `[tên khách mời]` / `[a Hiển]` / `[link Proposal]` — thay khi gửi.
> Giọng: như Hải nhắn thường ngày, không trịnh trọng. Hải tự dẫn nhập về Bookie
> (khách mời đã hiểu rõ cộng đồng) — không gửi doc briefing; artifact duy nhất
> gửi nhóm là bản Proposal (automation copy: `create-form.mjs --new-proposal "BT31"`).

## Tin 1 — mở group

```
Chào [tên khách mời] với [a Hiển], em lập group này để mình bàn cụ thể vụ mở lại sinh hoạt
cho nhóm bạn của [tên khách mời] nhé.

Mô hình em đề xuất đơn giản như hồi trước: nhóm mình chủ động phần nội dung, Bookie lo
trọn hậu cần + truyền thông (giờ đã tự động hoá gần hết nên duy trì đều đặn rất nhẹ).

Mỗi kỳ nhóm chỉ cần điền 1 bản proposal — em gửi bản của kỳ đầu tiên đây, trong đó có
sẵn phần tóm tắt tinh thần + format Bookie cho các bạn mới, đọc 2 phút là nắm được:

👉 [link Proposal]

Trước mắt cần chốt 3 thứ:

1. Chủ đề kỳ đầu ([tên khách mời] với các bạn đề xuất 1-2 phương án he — quản trị hay phát
   triển bản thân đều hợp)
2. Ngày giờ — em đề xuất sáng CN 02/08 theo nhịp cũ của Book!e Talk, đủ 2 tuần
   truyền thông
3. Offline hay online — offline thì em liên hệ lại địa điểm

Còn lại (tên gọi chuỗi, tần suất, quy mô...) mình bàn dần trong group ạ.
```

## Tin 2 — bổ sung phân vai (gửi kèm ngay sau nếu cần)

```
Nói rõ hơn phần ai lo gì cho các bạn dễ hình dung:

📌 Nhóm [tên khách mời]: chọn chủ đề, xây agenda, nhận các slot Speech (mỗi buổi 2 bài
~10 phút — chỗ luyện thuyết trình chính), điều phối buổi.

📌 Bookie: form đăng ký + QR + poster + email + bài đăng fanpage + lịch — tất cả sinh
tự động từ bản proposal nhóm điền, xong em gửi lại nhóm duyệt trước khi đăng.

Format chi tiết có ngay trong file proposal (phần A) — [tên khách mời] quen rồi he,
các bạn mới đọc 2 phút là nắm nha.
```

## Ghi chú gửi

- Tạo proposal kỳ đầu trước khi mở group: `cd shared/event-automation && node create-form.mjs --new-proposal "BT31"` → lấy link.
- Gửi tin 1 → đợi mọi người vào group → tin 2 nếu cần.
- Nhóm điền xong proposal → xử lý theo `../plan/xu-ly-proposal.md` (event.json → /event-form → /event-graphics → comms).
