# Sáu Layer Phủ Lên Một Nền Phẳng

**Date**: 2026-03-07
**Tags**: remotion, visual-design, animation, architecture
**Status**: draft

## TL;DR

Xây 6 visual overlay components trong một buổi sáng để Remotion video trông cinematic hơn — AmbientParticles, LightLeak, CornerAccents, WaveformDecor, GrainOverlay, Vignette. WaveformDecor qua 6 iteration mới ra neon edge spectrum. Cuối buổi mới nhận ra: tất cả 6 layer này là band-aid cho một vấn đề gốc rễ hơn.

## The Problem

Video lúc đầu chỉ là ảnh flat + Ken Burns pan/zoom. Trông OK với 5-10s clips. Nhưng với 20-60s mỗi scene, mắt người xem bắt đầu mỏi. Thiếu texture, thiếu depth, thiếu cái cảm giác "đang xem video" chứ không phải "đang xem slideshow."

Mục tiêu: thêm motion và atmosphere mà không làm rối thông điệp. Tất cả overlays phải subtle — hỗ trợ, không lấn át.

## The Journey

**AmbientParticles** — xây đầu tiên, logic đơn giản nhất: floating bokeh circles với seeded random để mỗi scene có pattern riêng nhưng reproducible. Layout-aware: framed mode thì particles ở bên ngoài panel.

**LightLeak** — cinematic sweep gradient di chuyển qua scene. 6 presets (top-left gold, top-right amber, bottom-left green...) xoay vòng theo scene index. `mixBlendMode: "screen"` để hòa vào ảnh tự nhiên.

**CornerAccents** — editorial brackets kiểu magazine print. SVG path đơn giản, nhưng phải tính toán để offset đúng khi switch giữa bleed và framed layout.

**WaveformDecor** — mất nhiều nhất thời gian. Ý tưởng ban đầu: waveform bars dọc theo cạnh màn hình. V1 trông như equalizer karaoke. V2-3: thử bar chart theo hình tròn — phức tạp hơn nhưng không fit với 16:9. V4: back to edge bars nhưng với harmonic wave (4 harmonics, mỗi bar là tổng hợp của 4 sine waves). V5: thêm breathing cycle 8s. V6: neon tube glow effect — SVG `feGaussianBlur` sharp inner + wide bloom merge. Peak sparkles trên bars cao nhất. Kết quả: neon edge spectrum thở theo nhạc.

**GrainOverlay + Vignette** — cuối cùng nhất. Đơn giản nhất. Film grain CSS noise + vignette gradient. 3% opacity — invisible riêng lẻ, nhưng làm cả canvas có texture.

Z-order sau khi hoàn thiện: SceneSlide → AmbientParticles → WaveformDecor → LightLeak → SceneTitleOverlay → Vignette → CornerAccents → GrainOverlay → BrandBar → Subtitle.

## The Insight

Khi ngồi nhìn lại 6 components đã xây, câu hỏi tự nhiên nảy ra: *tại sao cần nhiều layer đến vậy?*

Câu trả lời: vì nền ảnh quá flat. Flat illustration với clean edges và solid colors — đẹp với mắt designer, nhưng trên screen video thì sterile. GrainOverlay 3% không đủ để cứu một ảnh đã mặc định là flat.

6 overlays là cách đúng để thêm atmosphere — nhưng chúng không thể thay thế base layer có texture. Đó là lý do buổi chiều cùng ngày, sau khi nhìn từ góc độ brand strategist + designer, quyết định chuyển toàn bộ visual style sang **Textured Editorial Illustration**: risograph grain, visible brushwork, soft shadows. Zero pipeline change — chỉ update 2 files (`style-guide.md` + `/generate-prompts` SKILL.md), Gemini tự pick up style mới.

6 layer overlays + textured base = cinematic depth thực sự, thay vì 6 layer overlays trên nền flat.

## Technical Details

```
Z-order (bottom → top):
SceneSlide (Ken Burns image)
  → AmbientParticles (floating bokeh)
  → WaveformDecor (neon edge spectrum)
  → LightLeak (cinematic sweep)
  → SceneTitleOverlay (chapter label)
  → Vignette (depth gradient)
  → CornerAccents (editorial brackets)
  → GrainOverlay (film texture 3%)
  → BrandBar (progress + chapter dots)
  → Subtitle (SRT overlay)
```

WaveformDecor dùng `seededRandom(sceneIndex * 4217)` — mỗi scene có waveform pattern riêng, nhưng deterministic giữa các lần render. Không bị flickering giữa preview và export.
