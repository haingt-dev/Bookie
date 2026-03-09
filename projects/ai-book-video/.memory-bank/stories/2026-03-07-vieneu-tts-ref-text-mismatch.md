---
title: "Lỗi ảo giác của VieNeu-TTS: ref_text mismatch và hành trình đánh giá TTS blind test"
date: 2026-03-07
tags: [tts, voice-cloning, blind-test, debugging]
status: draft
---

## TL;DR

VieNeu-TTS liên tục hallucinate nội dung lạ vào audio output — không phải lỗi engine, mà là bug setup: chúng ta dùng transcript của một file audio khác làm ref_text. Cái giá của sự cẩu thả là 12/21 chunk bị nhiễm content không liên quan.

## The Problem

Đang preview voice cho video "Sans Famille / Gia đình" của Hector Malot, dải voice 6666-6800 có vấn đề — nghe không ra phát âm gì. Thay vì debug từng chunk, quyết định đánh giá toàn diện: so sánh blind A/B giữa viXTTS (engine hiện tại) và VieNeu-TTS (ứng viên thay thế).

## The Journey

Thiết kế 21 neutral test chunks — không lấy từ video có sẵn vì sẽ bias về viXTTS. Chunks cover 8 category: narration chuẩn, đầu câu khó (Nhưng/Vì vậy/Thế nhưng), số (2024, 320, 5,3 tỷ), lặp từ, code-switching VN+EN, câu hỏi, tên người nước ngoài, emotional, và stress test (3 chars đến 537 chars).

Kết quả blind test lần 1: VieNeu-TTS thảm họa. CPS dao động 2.9 - 155.8 (trong khi viXTTS ổn định 12-16). Hải nghe thấy "tính chiến đấu", "phòng dự thi" xuất hiện trong các chunk về sách hoàn toàn không liên quan. 12/21 chunk bị hallucination. Ban đầu nghi sample rate mismatch (fonos 22kHz vs VieNeu 24kHz) — đúng một phần, nhưng không phải root cause.

Root cause thực sự: VieNeu-TTS dùng kiến trúc continuation-based. Prompt format:

```
{ref_text_phones} {input_text_phones}
```

Model được bảo "audio reference nói [ref_text], hãy tiếp tục nói [input_text]." Chúng ta đã dùng `fonos.wav` làm reference audio, nhưng `ref_text` là transcript copy từ VieNeu's example — transcript của `example_ngoc_huyen.wav`, một file hoàn toàn khác. "Tác phẩm dự thi bảo đảm tính khoa học, tính đảng, tính chiến đấu" là lời thoại của Ngọc Huyền, không phải fonos.

Model bị confused tại boundary giữa ref và input → hallucinate ref content vào output.

Fix: dùng whisper large transcribe chính xác fonos (segment 2s-7.5s, continuous speech). Transcript thực: "Anh ta nhìn vào linh hồn chính mình." Update `REF_TEXT`, re-generate. CPS về 7-14 range, stable.

Kết quả blind test lần 2: VieNeu-TTS sạch hơn đáng kể, nhưng vẫn thua viXTTS (voice quality thấp hơn, pace chậm khi clone fonos). viXTTS thắng 14/21, avg 3.4/5. Verdict: giữ nguyên viXTTS.

## The Insight

Với continuation-based TTS (VieNeu, F5-TTS, nhiều model khác): `ref_text` phải khớp CHÍNH XÁC với audio reference. Không phải "gần đúng" hay "copy từ model ví dụ". Mismatch → model không biết boundary ref kết thúc ở đâu → hallucinate. Whisper large để transcribe là cần thiết, không đoán mò.

Thêm nữa: điểm yếu của viXTTS (không đọc số, giới hạn EN terms) đã được `/write-video` skill cover bằng normalization khi viết script — không phải production issue, chỉ là raw engine limit.

## Technical Details

- VieNeu-TTS `base.py:304-306`: `f"<|TEXT_PROMPT_START|>{ref_text_phones} {input_text_phones}<|TEXT_PROMPT_END|>"`
- Fonos reference: 15s, 22050Hz. Segment tốt nhất: 2s-7.5s ("Anh ta nhìn vào linh hồn chính mình"), resample lên 24kHz trước khi dùng với VieNeu
- Sanity check pattern: dùng VieNeu's own `example_ngoc_huyen.wav` + matched ref_text trước → CPS 15-21 → confirm engine hoạt động → sau đó mới debug ref audio custom
