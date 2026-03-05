# Current Context

> **Last Updated**: 2026-03-05
> **Updated By**: Claude Code (với Hải)

## Current Sprint/Focus
**Goal**: Sản xuất video đầu tiên (Atomic Habits) cho kênh Bookie
**Deadline**: Không cố định — ưu tiên chất lượng trước tốc độ
**Progress**: Voice-first pipeline refactored and verified. Voice + subtitle generated. Skills improved. Awaiting scene images for preview.

## Active Workstreams
1. **AI Book Video Pipeline**
   - **Status**: Pipeline verified (voice-first). Scenes in progress (0/9 images).
   - **Owner**: Hải
   - **Priority**: High
   - **Next Action**: Generate 9 scene images → `make sync` → `make studio`

2. **Skill Quality**
   - **Status**: Complete — all 5 skills evaluated and improved
   - **Changes**: Expanded descriptions with trigger phrases, fixed content gaps

## Recent Changes (Last 30 Days)
- **2026-03-05** `chore`: Improve all 5 skills — descriptions + trigger phrases + content fixes
  - extract-notes, write-script, write-storyboard, write-metadata, new-subproject
  - Used skill-creator workflow: evaluate → plan → improve
- **2026-03-05** `chore`: Project review + pipeline reset for full test
  - Fixed `tech.md` Gemini reference, rewrote `image-prompt.md` template
  - Expanded `make clean` to cover all generated files (voice-timing, scenes, symlinks)
  - Updated `.env.example` with optional viXTTS container vars
  - Reset atomic-habits: deleted all generated outputs, kept source files
- **2026-03-05** `chore`: Switch image gen from Leonardo to Gemini Nano Banana 2
  - Storyboard prompts converted from comma-separated keywords to natural language
  - `/write-storyboard` skill updated for Gemini format
  - `atomic-habits/storyboard.md` — all 9 scene prompts rewritten
- **2026-03-05** `feat`: Claude Code skills for creative pipeline steps
  - 4 skills: `/extract-notes`, `/write-script`, `/write-storyboard`, `/write-metadata`
  - Replace copy-paste prompts from `templates/claude-prompts.md`
  - Skills auto-read input files + write output, keep human decision points
  - Not auto-called from Makefile — creative steps need human judgment
- **2026-03-05** `feat`: Auto-generate scenes.json (`make scenes`) from timing + images
  - Derives durations from section-timing.json (start-to-start), images from scenes/
  - Eliminates manual maintenance of remotion/src/data/scenes.json
- **2026-03-05** `feat`: Whisper-based subtitle generation (replaces proportional char timing)
  - faster-whisper large-v3 with word timestamps → accurate SRT
  - Anti-hallucination: repetition_penalty, dedup, word rate filter
  - No longer depends on section-timing.json for subtitles
- **2026-03-05** `feat`: Rewrite Atomic Habits — contrarian angle "Điều mà Atomic Habits không nói với bạn"
  - New script: 913 words, 9 scenes, 3 blind spots + positive trade-off
  - New storyboard: all flat/Ken Burns (no parallax), Bookie style prefix
  - New metadata: YouTube + Facebook + 3 Shorts
  - Research: NotebookLM + 7 criticism sources
- **2026-03-05** `refactor`: Voice-first pipeline
  - Flipped pipeline: voice → subtitle → sync → validate (was subtitle → voice)
  - Voice is authority — section-timing.json from actual measurements
  - SRT derives from actual voice timing (no prediction)
  - Pace-aware gaps (slow: 0.40/0.80s, normal: 0.15/0.40s, fast: 0.08/0.20s)
- **2026-03-05** `chore`: Cleanup old assets
  - Removed: 13 old scene PNGs, voiceover.wav, subtitles.srt, section-timing.json
  - Removed: Remotion symlinks, test renders, fish-speech-server Podman image (11.4 GB)
- **2026-03-05** `refactor`: Major project restructure — unified `books/` layout + Makefile pipeline
  - Branch: `restructure/clean-pipeline`
- **2026-03-03** `feat`: Full pipeline infrastructure (viXTTS, Remotion, scripts)

## Context Carry-Forward
**For Next Session**:
- Generate 9 scene illustrations from storyboard.md prompts (paste into Gemini)
- `make sync BOOK=atomic-habits` → `make studio` to preview
- Voice + subtitle already generated and verified

## Known Issues & Workarounds
- **Issue**: viXTTS Podman container cần start thủ công mỗi session
  - **Workaround**: `./scripts/vixtts-server.sh start`
- **Issue**: NotebookLM CLI (`nlm`) dùng internal APIs — có thể break
  - **Workaround**: Dùng NotebookLM web UI nếu CLI lỗi
- **Issue**: Pre-existing TS error `Root.tsx:47` BookShort Composition typing
  - **Workaround**: Cosmetic only, doesn't affect render

## Key Files & Locations
- `WORKFLOW.md` — Pipeline docs + Makefile usage
- `Makefile` — `make voice/subtitle/sync/validate/studio/render BOOK=<slug>`
- `books/atomic-habits/` — Script, scenes, audio, output (single source of truth)
- `scripts/generate-voice.sh` — Voice-first: voiceover + section-timing.json (authority)
- `scripts/generate-subtitle.sh` — SRT timed to actual voice
- `scripts/generate-scenes.sh` — Auto-gen scenes.json for Remotion
- `scripts/sync-assets.sh` — Symlink books/ → remotion/public/
- `scripts/init-book.sh` — Scaffold new book project
- `scripts/vixtts-server.sh` — Manage viXTTS container
- `brand/` — Style guide + voice reference
- `templates/` — Script/prompt/checklist templates
- `remotion/src/data/scenes.json` — Per-video config
