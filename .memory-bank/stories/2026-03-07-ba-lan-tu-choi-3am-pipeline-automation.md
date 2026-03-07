# Ba lần từ chối lúc 3 giờ sáng: Khi pipeline automation có thêm một bộ óc nghiên cứu

**Date**: 2026-03-07
**Tags**: pipeline, automation, skills, architecture
**Status**: draft

## TL;DR

Mất 3 lần từ chối mới có plan được duyệt — không phải vì implementation sai, mà vì vision Phase 1 (research) cứ phải mở rộng thêm mỗi lần. Cuối cùng xây được `/produce-video` + `produce.sh`, lúc 3 giờ sáng, và để live test đến trưa.

## The Problem

Pipeline của Bookie hiện tại có 11 bước với ~6 điểm dừng thủ công: 5 skill invocations, review giọng, paste ảnh vào Gemini, rồi publish. Hải muốn rút xuống còn 2: **chọn angle** và **preview video**. Mọi thứ còn lại tự chạy.

## The Journey

Plan đầu tiên trình bày xong — bị từ chối ngay. Lý do: "Nếu cần tạo skill mới, phải dùng `/skill-creator`, không phải viết SKILL.md thủ công." Sửa, trình bày lại.

Bị từ chối lần hai. "Phase 1 Research — nếu dùng NotebookLM thì phải tạo notebook, import nguồn vào, càng nhiều càng tốt. yt-dlp competitive analysis cũng phải import vào NotebookLM luôn." Sửa. NotebookLM trở thành central hub, không chỉ là một bước trong pipeline.

Bị từ chối lần ba. "Còn đánh giá phê bình trong và ngoài nước, diễn đàn, thảo luận, thông tin tác giả, drama — toàn bộ mọi thứ có liên quan."

Đến đây mới hiểu: từ chối không phải vì implementation. Mà là Hải đang iteratively mô tả một tầm nhìn — Phase 1 phải là một *chiến dịch trinh sát* thực sự, không phải chỉ đọc cuốn sách. Mỗi lần từ chối là thêm một lớp vào bức tranh.

Sau lần ba, plan được duyệt. Và plan cuối cùng có Phase 1 bao gồm: book source + YouTube competitors via yt-dlp (transcript + view counts) + Goodreads/Amazon/Spiderum reviews + Reddit/HackerNews/Voz threads + author bio/controversies + academic rebuttals + "anything tangentially connected" — tất cả import vào NotebookLM, rồi query để synthesize angles.

Implementation sau đó chạy thẳng:
- `produce.sh`: bash orchestrator 7 bước (voice → images → subtitle → scenes → sync → validate → render), skip flags, ffprobe summary
- Makefile: thêm `produce` target với ARGS passthrough
- `/produce-video` skill qua `/skill-creator`: 6 phases, ~300 dòng
- `WORKFLOW.md`: thêm "Full Auto Mode" section

Dry-run với `--skip-voice --skip-images --skip-render` trên atomic-habits: pass. Lúc đó là 3 giờ sáng.

## The Insight

Ba lần từ chối không phải là lỗi trong quá trình planning. Đó *là* quá trình design. Khi làm việc với AI, người dùng thường không biết chính xác mình muốn gì cho đến khi thấy một draft để phản ứng. Draft đó là công cụ tư duy, không phải sản phẩm.

Và cái thay đổi căn bản nhất không phải là code — mà là triết lý của Phase 1. "Đọc sách rồi tóm tắt" → "Cast the widest possible net. The more diverse the sources, the more unique the angle."

## Technical Details

```bash
# The final interface:
/produce-video atomic-habits    # → choose angle → ~15min → video.mp4

# Or production-only:
make produce BOOK=atomic-habits ARGS="--skip-voice"
```

Skip flags trong produce.sh cho phép partial re-runs: `--skip-voice` (reuse voiceover), `--skip-images` (reuse scenes), `--skip-render` (dừng trước render để preview qua Remotion Studio).

Architecture: master skill chạy creative phases inline (research, storyboard, script, image prompts), sau đó gọi `produce.sh` cho deterministic bash chain. Hai thứ này tách biệt có chủ đích — skill xử lý sáng tạo + judgement, bash xử lý deterministic pipeline.
