# Product Context

## 🎯 Problem Statement
**The Problem**:
Bookie community muốn mở rộng reach qua video content (YouTube/Facebook) nhưng sản xuất video tốn thời gian và effort lớn, đặc biệt với team nhỏ.

**Current State**:
- Bookie hoạt động chủ yếu qua Facebook fanpage, website, events offline
- Chưa có video content channel
- Content dạng text/event là chính

**Desired State**:
- Video kênh hoạt động ổn định: 1 video dài + 2-3 shorts/tuần
- Pipeline tự động hóa tối đa, 1 người có thể vận hành
- Dùng AI voice + automation để giảm effort từ 15h+ xuống <10h/tuần

## 👥 Users & Personas
### Primary User: Hải (Producer)
- **Profile**: Backend dev, admin Bookie community
- **Goals**: Sản xuất video sách chất lượng, consistent, ít effort nhất có thể
- **Pain Points**: Limited time, không phải professional video editor
- **Success Metrics**: Publish 1 video/tuần, <10h effort

### Secondary User: Bookie Audience
- **Profile**: Người Việt 20-35 tuổi, quan tâm self-improvement, đọc sách
- **Goals**: Tìm sách hay, hiểu nhanh key insights, inspiration
- **Pain Points**: Không đủ thời gian đọc, cần người tóm tắt hay
- **Success Metrics**: Watch time >50%, subscribe, comment

## 💎 Value Proposition
**For** người Việt trẻ thích self-improvement
**Who** muốn tiếp cận tri thức từ sách nhưng không đủ thời gian đọc
**This is a** kênh video sách tiếng Việt
**That** kể chuyện hấp dẫn từ góc nhìn thực tế, không tóm tắt khô khan
**Unlike** các kênh review sách kiểu book report
**Our solution** chọn 1 angle cụ thể, kể bằng câu chuyện, visual đẹp

## 📊 Key Metrics & KPIs
- **Videos/tuần**: 1 video dài + 2-3 shorts — consistency
- **Watch time avg**: >50% cho video dài — content quality
- **Subscriber growth**: Tracking monthly — channel health
- **Production time**: <10h/video — sustainability

## 🚧 Constraints & Requirements
### Technical Constraints
- GPU: RTX 4070 Super Ti (16GB VRAM) — đủ cho viXTTS self-host
- 1-person operation — phải automate tối đa
- Internet: cần cho NotebookLM, image gen APIs

### Business Constraints
- Budget: Minimize — ưu tiên free/open-source tools
- No dedicated video editor — dùng Remotion (code-based)
