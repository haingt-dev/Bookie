---
title: "Lần Này Là Lần Cuối Cùng (Chắc Vậy)"
date: 2026-03-06
tags: [pipeline, refactor, architecture, bookie]
project: "bookie-ai-book-video"
status: draft
---

# Lần Này Là Lần Cuối Cùng (Chắc Vậy)

## TL;DR

Bỏ ra vài ngày build prediction pipeline hoàn chỉnh để estimate voice duration trước khi generate — benchmark, linear model, vòng lặp estimate-adjust-rewrite. Rồi ngồi thực sự dùng nó mới nhận ra: mình đang optimize timing thay vì story. Đập đi hết, build lại story-first. Không nhớ đây là lần bao nhiêu rồi.

## The Problem

Bookie là một kênh video sách. Workflow: đọc sách → viết script → generate voice → dựng video. Đơn giản trên giấy.

Vấn đề đầu tiên gặp phải: viết xong script rồi không biết video sẽ dài bao nhiêu phút. viXTTS — TTS engine mình self-host — nói tiếng Việt với tốc độ khoảng 17 CPS (chars per second, không kể khoảng trắng). Nhưng "khoảng" đó biến động tùy chunk dài ngắn, tùy có từ tiếng Anh không, tùy gap giữa câu. Muốn target 7 phút? Viết 1400 từ là ra 7 phút? Không chắc.

Câu hỏi mình muốn trả lời: *trước khi chạy voice, script này sẽ ra bao nhiêu phút?*

Nghe có vẻ hợp lý. Cần một cái gì đó để predict.

## The Journey

### Build cái prediction pipeline

Session đầu: benchmark viXTTS. 16 đoạn văn thuần Việt, đo thời gian thực tế, fit linear regression. Ra được: `duration_sec ≈ 0.047 × bytes_nospace + 2.1`, R²=0.96. Đẹp, confident.

Session kế: benchmark chunking. viXTTS quality thay đổi tùy chunk dài ngắn — benchmark 27 đoạn, 9 target lengths từ 30 đến 300 chars. Tìm ra sweet spot 75-250 chars, 160 chars là lowest variance. Ra thêm một cái `tts-config.json` với chunk parameters, min/max/target, cả `en_to_vn` dictionary để auto-translate EN terms dài sang Việt.

Rồi build pipeline: `/write-script` → `/split-script` → `make estimate` → xem predicted timing → nếu lệch target thì sửa script → lặp lại.

Trên giấy trông rất professional. Có empirical data. Có config. Có vòng lặp.

### Bắt đầu thực sự dùng

Đến lúc ngồi viết script cho Atomic Habits thì mọi thứ bắt đầu thấy kỳ kỳ.

Mình viết một đoạn. Chạy estimate. Estimate báo lệch 40 giây so với target. Mình nhìn vào đoạn vừa viết — câu này kể chuyện hay, cần giữ nguyên — nhưng "phải cắt bớt vì estimate lệch". Rồi mình viết câu khác cho có vẻ ngắn hơn. Rồi lại chạy estimate.

Ở một thời điểm nào đó, mình nhận ra: *mình đang viết để satisfy số liệu, không phải để kể chuyện.*

Mà cái số liệu đó — timing — chỉ thực sự quan trọng *sau khi voice đã generate xong*. Và voice chạy trong 5-10 phút. Không phải bottleneck. Không ai đang chờ trong khi voice chạy.

Vậy mình đang optimize cái gì, cho ai?

### Câu hỏi sai

Câu hỏi "script này dài bao nhiêu phút?" nghe như câu hỏi hợp lý. Nhưng nó mặc định rằng *duration là constraint phải hit chính xác trước khi viết xong*.

Thực ra không phải. Duration là output — nó ra bao nhiêu thì ra, tùy story cần bao nhiêu không gian để thở. Nếu story hay mà ra 5m30s thay vì 7 phút đúng, thì không sao. Nếu phải ép story vào 7 phút bằng cách cắt những đoạn đang kể chuyện tốt — thì đang làm sai.

Câu hỏi đúng hơn: *story này có đủ mạnh chưa?*

### Đập đi

Ra quyết định trong khoảng 5 phút suy nghĩ.

Xóa `estimate-timing.sh`. Xóa `benchmark-voice.sh`, `benchmark-chunk.sh`. Xóa cả `output/benchmark/` và `output/chunk-benchmark/` — 16 + 27 WAV files, ~23MB. Xóa `books/atomic-habits/script.md` (bản cũ viết theo predict-and-loop), `predicted-timing.json`. Xóa `books/test-prediction/` — cả folder test.

Làm trong khoảng 2 phút, sau khi mất vài ngày build cái đống đó.

Build lại: `/create-storyboard` → `/write-video` → `make voice`. Không có bước estimate. Timing thực tế ra sau khi voice xong, và đó là authority duy nhất.

## The Insight

Có những thứ kỹ thuật hoàn toàn đúng nhưng giải quyết bài toán không ai đặt ra. Prediction pipeline model chính xác (R²=0.96 là tốt), config clean, vòng lặp hoạt động. Nhưng nó đang tối ưu một metric không phải constraint thực sự.

Bài học không mới — "đừng optimize premature", ai cũng biết. Nhưng lần này premature không phải ở code level mà ở kiến trúc: đã build cả một workflow xung quanh một assumption sai về production constraint.

Có lẽ cái đáng suy nghĩ hơn là tại sao lại sa vào đó. Khi không chắc chắn về một con số — video dài bao nhiêu phút — phản ứng tự nhiên là *đi đo và predict*. Nó nghe khoa học. Nhưng đôi khi câu trả lời đúng là *không cần biết trước, cứ làm đi*.

Và không biết đây là lần thứ bao nhiêu phải học lại điều đó.

## Technical Details

Pipeline cũ (prediction-first):

```
/write-script → /split-script → make estimate → (xem lệch → sửa → lặp) → make voice
```

Pipeline mới (story-first):

```
/create-storyboard → /write-video → make voice → /generate-prompts + make subtitle
```

`/write-video` output hai file paired: `chunks-display.md` (natural Vietnamese, subtitle source) + `chunks.md` (TTS-normalized, for viXTTS). Cùng `[NNN]` numbering cho 1:1 mapping. `section-timing.json` từ actual voice là timing authority duy nhất — không có prediction step nào khác.
