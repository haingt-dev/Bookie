# AI Book Video — Production Workflow

> **Format**: Video dai (5-8 min) + 2-3 shorts
> **Platform**: YouTube, Facebook, Shorts/Reels
> **Style**: Flat illustration + Ken Burns motion
> **Voice**: AI voice clone (viXTTS self-hosted)

---

## Pipeline

> Legend: `Skill` = Claude Code skill (`/skill-name`) | `Script` = automated (`make target`) | `Manual` = requires Hải

```
[/extract-notes] -------------- Skill (Claude+MCP)
    ↓ notes.md + chosen angle
[/create-storyboard] ---------- Skill (story direction)
    ↓ storyboard.md
[/write-video] ←──────────────── Skill (iterative)
    ↓ chunks-display.md + chunks.md
    │
[make voice] --- Script
  voiceover.wav + section-timing.json
    │
    v
[Review voice] --- Manual ────> (iterate write-video if needed)
    │
    │ (voice approved)
    │
    ├───────────────────────┐
    │                       │
    v                       v
[/generate-prompts] Skill  [make subtitle] --- Script
[make images] --- Script      chunks-display.md → SRT
  -> scenes/                 │
    │                       │
    ├───────────────────────┘
    v
[make scenes] --- Script
  scenes.json (from timing + images)
    ↓
[make sync] -> [make studio] -> [make render] --- Script
    ↓
[/write-metadata] ------------ Skill
    ↓
[/catalog-insights] ---------- Skill (Knowledge Vault)
    ↓
[Content Factory] --- NotebookLM MCP (podcast, debate, brief)
    ↓
[make render-shorts] --- Script (9:16 shorts from isShort scenes)
    ↓
[Publish] --- Manual (YouTube + Facebook)
```

> **Story-first**: Focus on the best story (`/create-storyboard` → `/write-video`), then generate voice.
> No timing prediction — `make voice` produces actual timing per chunk, which is the only timing authority.
> After voice approved: image prompts + subtitles run in parallel. Converge at `make scenes` → `make sync`.

## Pipeline Steps

| # | Step | Type | Command | Output |
|---|------|------|---------|--------|
| 1 | Init project | Script | `make init BOOK=<slug>` | Book folder scaffold |
| 2 | Extract notes | Skill | `/extract-notes <slug>` | `notes.md` + angle (incl. YouTube competitive analysis via `yt-dlp`) |
| 3 | Create storyboard | Skill | `/create-storyboard <slug>` | `storyboard.md` (story direction, no timing) |
| 4 | Write video | Skill | `/write-video <slug>` | `chunks-display.md` (natural VN) + `chunks.md` (TTS-normalized) |
| 5 | Generate voice | Script | `make voice BOOK=<slug>` | `voiceover.wav` + `section-timing.json` |
| 6 | Review voice | Manual | Listen + iterate 4→5 | Approved voice |
| 7a | Generate prompts | Skill | `/generate-prompts <slug>` | `image-prompts.md` (Gemini prompts with actual timing) |
| 7b | Generate images | Script | `make images BOOK=<slug>` | `scenes/*.png` |
| 7c | Generate subtitles | Script | `make subtitle BOOK=<slug>` | `subtitles.srt` (from chunks-display.md + timing) |
| 8 | Generate scenes.json | Script | `make scenes BOOK=<slug>` | `scenes.json` |
| 9 | Preview + Render | Script | `make studio` / `make render` | `video.mp4` |
| 10 | Write metadata | Skill | `/write-metadata <slug>` | `metadata.md` |
| 11 | Catalog insights | Skill | `/catalog-insights <slug>` | `knowledge-base/` updates |
| 12 | Publish | Manual | YouTube Studio + Meta | Live video |

## Quick Start

```bash
# 1. [Script] Init project
make init BOOK=atomic-habits

# 2. [Skill] Extract notes + choose angle
/extract-notes atomic-habits

# 3. [Skill] Plan story direction (scenes, arc, pacing)
/create-storyboard atomic-habits

# 4. [Skill] Write video script as paired chunk files
/write-video atomic-habits
#   → chunks-display.md (natural VN, subtitle source)
#   → chunks.md (TTS-normalized for viXTTS)

# 5. [Script] Generate voice
make voice BOOK=atomic-habits

# 6. [Manual] Listen, tweak if needed (iterate 4→5)

# 7a. [Skill] Generate image prompts (uses actual timing)
/generate-prompts atomic-habits

# 7b. [Script] Generate scene images via Gemini API
make images BOOK=atomic-habits

# 7c. [Script] Generate subtitles (from chunks-display.md + timing)
make subtitle BOOK=atomic-habits

# 8. [Script] Generate scenes.json (from timing + images)
make scenes BOOK=atomic-habits

# 9. [Script] Preview + Render
make studio BOOK=atomic-habits
make render BOOK=atomic-habits

# 10. [Skill] Write metadata
/write-metadata atomic-habits

# 11. [Manual] Publish to YouTube + Facebook

# Or run automated steps (voice -> render with skip flags)
make produce BOOK=atomic-habits
```

## Project Structure

```
books/                          # 1 book = 1 folder
  └── atomic-habits/
      ├── chunks-display.md     # readable script + subtitle source (natural VN)
      ├── chunks.md             # TTS-ready chunks (normalized text)
      ├── storyboard.md         # story direction (scenes, arc, pacing)
      ├── image-prompts.md      # Gemini image prompts per scene
      ├── notes.md              # NotebookLM extract + chosen angle
      ├── metadata.md           # YouTube/FB metadata
      ├── scenes/               # AI-generated scene images
      ├── audio/                # voiceover.wav (generated)
      └── output/               # subtitles.srt, section-timing.json
knowledge-base/                 # persistent cross-book intelligence (Knowledge Vault)
  ├── library.md                # master book index
  ├── production.md             # production metadata
  ├── concepts/                 # ideas indexed by THEME
  ├── authors/                  # author profiles
  └── connections/              # cross-book links (contradictions, agreements, evolutions)
scripts/                        # pipeline automation
  ├── init-book.sh              # scaffold new book
  ├── generate-voice.sh         # voice generation + actual timing
  ├── generate-images.sh        # scene images via Gemini API
  ├── generate-subtitle.sh      # SRT from chunks-display.md + timing
  ├── generate-scenes.sh        # auto-gen scenes.json for Remotion
  ├── validate-subtitle.sh      # SRT quality checks
  ├── vixtts-server.sh          # TTS server management
  └── sync-assets.sh            # symlink to remotion/public
remotion/                       # React video renderer
brand/                          # shared branding + voice reference
templates/                      # reusable templates
```

## Chunk File Format

`/write-video` outputs two paired files with identical `[NNN]` numbering:

**chunks-display.md** — Natural Vietnamese, human-readable, subtitle source:

```markdown
<!-- scene: scene-01, pace: slow -->
## HOOK

[001] "Mỗi ngày tốt hơn 1%, một năm sau bạn sẽ giỏi hơn 37 lần."
[002] "Nghe quen không? Con số này xuất hiện trong hàng trăm video."
```

**chunks.md** — TTS-normalized, for viXTTS:

```markdown
<!-- scene: scene-01, pace: slow -->
## Scene 01

[001] "Mỗi ngày tốt hơn một phần trăm, một năm sau bạn sẽ giỏi hơn ba mươi bảy lần."
[002] "Nghe quen không? Con số này xuất hiện trong hàng trăm video."
```

Pace levels (calibrated to viXTTS ~18 cps mean):

- `slow` (~18 cps, large gaps: 0.40s/0.80s) — dramatic hooks, reflective moments
- `normal` (~18 cps, standard gaps: 0.15s/0.40s) — standard narration
- `fast` (~18 cps, tight gaps: 0.08s/0.20s) — energetic CTA

### Script Language Rules

viXTTS là model **thuần Việt** — không nói được tiếng Anh. Khi gặp EN, nó cố đánh vần bằng phonetics Việt → thời gian phát âm không đoán được, chất lượng kém.

1. **Pure Vietnamese** là default cho mọi narration text
2. **Vinglish ngắn** (1-2 syllable) được phép: từ Việt hóa phổ biến mà viXTTS đọc OK (gym, blog, fan, team, ok, feedback, trend, style, app, web, like, share)
3. **EN terms dài** (>2 syllables: deliberate practice, accountability, growth mindset) → **phải dịch sang VN** hoặc giải thích bằng VN. viXTTS không nói được, mất 3-4x thời gian
4. **Tên riêng EN** (James Clear, PayPal, Stanford) → giữ nguyên, viXTTS đọc theo phonetics VN, acceptable
5. **Numbers**: viết tự nhiên trong chunks-display.md (34, 13.5 tỷ). `/write-video` tự chuyển thành chữ trong chunks.md cho TTS (34 → "ba mươi bốn"). EN terms dài cũng được auto-translate qua dictionary trong `tts-config.json`

### viXTTS Speaking Rate (Benchmark 2026-03-05)

> 10 passages, 11-102 words, pure speech (no gaps).

| Metric | Mean | Median | Range |
|--------|------|--------|-------|
| CPS (chars no-space/sec) | 17.7 | 17.7 | 14.7 - 20.6 |
| WPM (Vietnamese) | 209 | 213 | 172 - 252 |

**viXTTS limitation**: Model thuần Việt — không nói được tiếng Anh. EN words bị đánh vần bằng phonetics Việt, CPS rớt xuống ~12 (unpredictable). Giải pháp: loại bỏ EN dài khỏi script (xem Script Language Rules ở trên).

- Max ~500 chars per API call (enable_text_splitting=false)
- Validated: ~1.9% error on production scripts (pure VN + Vinglish short)

### TTS Chunk Optimization (Benchmark 2026-03-06)

> 27 passages, 9 target lengths (30-300 chars), 3 sources each. Config: `tts-config.json`

| Range | CPS | Quality | Notes |
|-------|-----|---------|-------|
| <50 chars | ~12 | SLOW/NOISE | Too short, inconsistent output |
| 50-75 chars | ~15 | OK | Acceptable but below baseline |
| **75-250 chars** | **17-19** | **GOOD** | Sweet spot, low variance |
| 160 chars | 17.7 | BEST | Lowest variance (std=0.24) |
| >250 chars | ~20 | OK/drift | CPS starts drifting up |

**Script length guide** (pure speech, add ~10-15s for normal-pace gaps):

| Target | Words | Chars (no space) |
|--------|-------|-------------------|
| 5 min | ~1050 | ~5400 |
| 7 min | ~1470 | ~7500 |
| 10 min | ~2100 | ~10700 |

> Vietnamese: 1 word = 1 syllable, avg ~5.1 chars/word (no space).

## Enriched scenes.json (Phase 3)

`make scenes` auto-populates enriched fields from existing pipeline files — no new user input:

| Field | Source | Purpose |
|-------|--------|---------|
| `meta` (bookTitle, author, angle) | `notes.md` + `storyboard.md` headers | Content-forward Intro |
| `chapters[]` | Scene labels (auto-detected) | ChapterIndicator component |
| Per-scene `layout` | `image-prompts.md` Layers field | Override bleed/framed alternation |
| Per-scene `panDir`/`zoomDir` | `image-prompts.md` Layers field | Override Ken Burns presets |
| Per-scene `isShort` | `storyboard.md` Shorts field | Dynamic BookShort compositions |

## Shorts Pipeline

Scenes marked `isShort: true` in storyboard.md generate dynamic `BookShort-NN` compositions (9:16, 1080x1920).

```bash
# Render all shorts for a book
make render-shorts BOOK=atomic-habits
# → output/BookShort-01.mp4, BookShort-02.mp4, ...
```

## Content Factory (Phase 3)

After video render + catalog, `/produce-video` Phase 7 generates derivative audio via NotebookLM:
- Deep-dive podcast → `output/podcast-deep-dive.wav`
- Debate podcast → `output/podcast-debate.wav`
- Audio briefing → `output/brief-audio.wav`

Each artifact independent — failures don't block others.

## viXTTS Server

```bash
# First time setup
./scripts/vixtts-server.sh setup

# Start/stop
./scripts/vixtts-server.sh start
./scripts/vixtts-server.sh stop
./scripts/vixtts-server.sh status
```

Requires: Podman + NVIDIA GPU (>=4GB VRAM)

## Timing Source of Truth

| Stage | File | Authority | Used by |
|-------|------|-----------|---------|
| After `make voice` | `output/section-timing.json` | **Actual (post-voice)** | `make scenes`, `/generate-prompts`, `make subtitle` |
| After `make voice` | `output/voice-timing.json` | Diagnostics only | Debugging |

**Rule**: `section-timing.json` là timing authority duy nhất. Nó được tạo bởi `make voice` từ actual TTS output. Không có timing prediction step — focus on story quality, let voice determine duration.

## Full Auto Mode

> One command, one interaction (choose angle), video ready.

```bash
/produce-video atomic-habits
# → Deep research (NotebookLM + web + competitors)
# → Choose angle (ONLY interaction)
# → Auto: storyboard → script → voice → prompts → images → subtitles → render → metadata
# → "Done! Preview your video."
```

Or production-only (creative assets already exist):

```bash
make produce BOOK=atomic-habits
# Runs: voice → images → subtitle → scenes → sync → validate → render

# Skip flags for partial re-runs:
make produce BOOK=atomic-habits ARGS="--skip-voice"    # reuse voiceover
make produce BOOK=atomic-habits ARGS="--skip-images"   # reuse scene images
make produce BOOK=atomic-habits ARGS="--skip-render"   # stop before render (preview in Studio)
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `init` | Scaffold new book project |
| `voice` | Generate voiceover + section-timing.json (authority) |
| `subtitle` | Generate SRT from chunks-display.md + timing |
| `images` | Generate scene images via Gemini API (Nano Banana 2) |
| `scenes` | Auto-generate scenes.json from timing + images |
| `sync` | Symlink book assets to remotion/public |
| `validate` | Validate SRT quality |
| `studio` | Open Remotion Studio preview |
| `render` | Render final video |
| `produce` | Full production pipeline (voice → render) with skip flags |
| `render-shorts` | Render all `BookShort-NN` compositions to `output/` |
| `clean` | Remove generated files |

All targets require `BOOK=<slug>` parameter.

## n8n Workflows

An alternative to the CLI pipeline above. n8n provides a web UI with form-based inputs, visual workflow management, and execution logs.

**Setup:** See [n8n/README.md](n8n/README.md) for Docker setup and quick start.

**Requirement:** The host bridge must be running (`./n8n/host-bridge/bridge.sh`) for n8n to execute any host commands (voice, render, images, etc.).

### Workflow Mapping

| n8n Workflow | Replaces CLI Step |
|---|---|
| 00 — Sheet Orchestrator | Google Sheets control panel → auto-runs pipeline |
| 01 — Pipeline Dashboard | Main orchestrator (no CLI equivalent) |
| 02 — Book Research | `/extract-notes` skill |
| 03 — Storyboard Creation | `/create-storyboard` skill |
| 04 — Script Writing | `/write-video` skill |
| 05 — Voice Production | `make voice` |
| 06 — Visuals Production | `/generate-prompts` + `make images` |
| 07 — Assembly & Render | `make scenes` + `make sync` + `make render` |
| 08 — Post-production | `/write-metadata` + `make subtitle` + `/catalog-insights` |
| 09 — Status Dashboard | `make status` |

All workflows use form triggers — submit via the n8n form UI. Creative steps (02-04, 08) call Claude via Anthropic API. Production steps (05-07) call make targets through the host bridge.

### Google Sheets Control Panel

The **00 — Sheet Orchestrator** workflow polls a Google Sheet every 1 minute. Add a book row with status `▶ Start` → orchestrator auto-runs production phases sequentially. LLM phases pause and tell you which workflow to run manually.

Sheet columns: `book_slug | status | phase | progress | angle_choice | notes | error`

Sheet ID: configured in workflow (see n8n/README.md for setup).
