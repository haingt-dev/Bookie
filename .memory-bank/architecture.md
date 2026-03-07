# Architecture

## System Overview
Pipeline-based production system cho video sách. Không phải application code — là một chuỗi tools + scripts + templates orchestrated bởi Makefile và bash scripts.

**Architecture Style**: Pipeline / Workflow automation

## Project Structure
```
projects/ai-book-video/
├── Makefile                    — Pipeline orchestration
├── WORKFLOW.md                 — Master workflow documentation
├── .env.example                — Environment template
├── books/                      — 1 book = 1 folder (source of truth)
│   └── atomic-habits/
│       ├── chunks-display.md   — Readable script + subtitle source (natural VN)
│       ├── chunks.md           — TTS-ready chunks (normalized text)
│       ├── storyboard.md       — Story direction (scenes, arc, pacing)
│       ├── image-prompts.md    — Gemini image prompts per scene
│       ├── notes.md            — NotebookLM extract + chosen angle
│       ├── metadata.md         — YouTube/FB metadata
│       ├── scenes/             — AI-generated illustrations (PNG)
│       ├── audio/              — voiceover.wav (generated)
│       └── output/             — subtitles.srt, section-timing.json
├── scripts/                    — Pipeline automation
│   ├── produce.sh              — Full pipeline orchestrator (voice → render)
│   ├── init-book.sh            — Scaffold new book project
│   ├── generate-voice.sh       — Voice generation + actual timing
│   ├── generate-images.sh      — Scene images via Gemini API
│   ├── generate-subtitle.sh    — SRT from chunks-display.md + timing
│   ├── generate-scenes.sh      — Auto-gen scenes.json for Remotion
│   ├── validate-subtitle.sh    — SRT quality checks
│   ├── vixtts-server.sh        — TTS server management
│   └── sync-assets.sh          — Symlink books/ → remotion/public/
├── knowledge-base/             — Persistent cross-book intelligence (Knowledge Vault)
│   ├── library.md              — Master book index
│   ├── production.md           — Production metadata (templates, hooks, durations)
│   ├── concepts/               — Ideas indexed by THEME (not by book)
│   ├── authors/                — Author profiles (thesis, strengths, blind spots)
│   └── connections/            — Cross-book links (contradictions, agreements, evolutions)
├── templates/                  — Narrative templates (narrative-templates.md)
├── brand/                      — Voice reference + style guide
└── remotion/                   — React video renderer
    ├── src/                    — Compositions, components, types, utils
    ├── public/                 — Symlinks populated by sync-assets.sh
    └── package.json
```

## Data Flow

### Full Auto (recommended)

```
/produce-video <slug>
    ↓
[Phase 1: Deep Research] ── NotebookLM + WebSearch + yt-dlp
    ↓ notes.md + 3-4 angle options
[Phase 2: Choose Angle] ── ONLY user interaction
    ↓
[Phase 3: Creative Gen] ── storyboard.md + chunks + metadata.md
    ↓
[Phase 4: Voice] ── make voice → voiceover.wav + section-timing.json
    ↓
[Phase 5: Visual] ── image-prompts.md → produce.sh --skip-voice
    ↓                  (images → subtitle → scenes → sync → render)
[Phase 6: Report] ── video.mp4 path, duration, file size
    ↓
[Phase 6.5: Catalog] ── concepts → knowledge-base/, source → Master notebook
    ↓
[Phase 7: Content Factory] ── NotebookLM → podcast, debate, briefing audio
```

### Granular Pipeline

```
[/extract-notes] → notes.md + angle --------- Skill
    ↓
[/create-storyboard] → storyboard.md -------- Skill
    ↓
[/write-video] → chunks-display.md + chunks.md  Skill
    ↓
[make voice] → voiceover.wav + timing -------- Script
    ↓
[/generate-prompts] → image-prompts.md ------- Skill
    ↓
[make produce ARGS="--skip-voice"] ----------- Script
  (images → subtitle → scenes → sync → validate → render)
    ↓
[/write-metadata] → metadata.md -------------- Skill
    ↓
[/catalog-insights] → knowledge-base/ ------- Skill
    ↓
[YouTube / Facebook] ------------------------- Manual
```

**Key principles**:

- **Story-first**: Focus on narrative quality (`/create-storyboard` → `/write-video`). No timing prediction — write the best story, let voice determine duration.
- **Voice is authority**: `section-timing.json` from actual TTS output is the only timing source. No prediction step.
- **Paired chunk files**: `chunks-display.md` (natural VN, subtitle source) + `chunks.md` (TTS-normalized). Same `[NNN]` numbering for trivial 1:1 mapping.

## Key Components

### Makefile Orchestration
- **Location**: `Makefile`
- **Targets**: start, stop, status (viXTTS server), init, voice, subtitle, images, scenes, sync, validate, studio, render, render-shorts, produce, clean
- **Usage**: `make <target> BOOK=<slug>` (produce accepts `ARGS="--skip-voice"` etc.)
- **Guard**: `need-book` macro — targets that need BOOK= fail with clear error if missing

### viXTTS (Self-hosted)
- **Location**: Podman container on local GPU, port 8020
- **Purpose**: AI voice cloning → Vietnamese voiceover
- **Dependencies**: NVIDIA GPU (>=4GB VRAM), Podman, CUDA
- **Config**: fonos speaker, temp=0.85, repetition_penalty=2.0
- **Management**: `scripts/vixtts-server.sh`

### Remotion Template
- **Location**: `remotion/`
- **Purpose**: Programmatic video composition + CLI rendering
- **Dependencies**: Node.js, React/TypeScript, Remotion 4.x
- **Compositions**: BookVideo (16:9, 1920x1080, 30fps), BookShort-NN (9:16, dynamic from isShort scenes)
- **Components**: SceneSlide (Ken Burns + cross-dissolve, per-scene panDir/zoomDir override), Subtitle (SRT overlay + fade), Intro (content-forward: bookTitle/author/angle when meta present), Outro, BrandBar (progress + chapter dots)
- **Visual overlays**: AmbientParticles (floating bokeh), LightLeak (cinematic sweep), CornerAccents (editorial brackets), WaveformDecor (neon edge spectrum), GrainOverlay (film texture), Vignette (depth)
- **Branding (Remotion)**: #1B6B2A primary, #D4A853 gold, #FAFDF5 background (see `constants.ts`). Image prompts use separate palette from `brand/style-guide.md`.

### Script Format
- Scene markers: `<!-- scene: scene-01, pace: slow -->`
- Pace presets: viXTTS ~15 cps ≈ 200 wpm Vietnamese. Pace controls gap timing only:
  - slow (large gaps: 0.40s/0.80s) — dramatic, reflective
  - normal (standard gaps: 0.15s/0.40s) — narration
  - fast (tight gaps: 0.08s/0.20s) — energetic CTA
- Voice config: `<!-- voice: temp=X, repetition_penalty=Y -->`

### Claude Code Skills
- **Location**: `.claude/skills/`
- **Purpose**: Replace copy-paste prompts with invocable skills for creative pipeline steps
- **Active skills**:
  - `/produce-video <slug>` — **Master orchestration**: full pipeline from research to rendered video (one interaction: choose angle)
  - `/extract-notes <slug>` — NotebookLM → notes.md + angle selection
  - `/create-storyboard <slug>` — notes.md → storyboard.md (story direction, no timing)
  - `/write-video <slug>` — storyboard + notes → chunks-display.md + chunks.md (paired)
  - `/generate-prompts <slug>` — storyboard + timing → image-prompts.md (Gemini format)
  - `/write-metadata <slug>` — script → metadata.md (YouTube/FB)
  - `/catalog-insights <slug>` — notes + storyboard → knowledge-base/ (vault extraction)
- **Design**: `/produce-video` is the primary entry point (combines all skills + production). Individual skills remain for granular iteration.

### Phase 3: Multi-Modal Outputs + Pipeline Enrichment

- **Enriched scenes.json**: `meta` (bookTitle/author/angle), `chapters[]`, per-scene `layout`/`panDir`/`zoomDir`/`isShort` — all auto-filled from existing pipeline files by `generate-scenes.sh`
- **Content-forward Intro**: Shows book title, author, angle when `meta` present; falls back to logo+tagline
- **Per-scene visual override**: `resolveKenBurns()` in SceneSlide.tsx respects panDir/zoomDir from image-prompts.md Layers field
- **Dynamic Shorts**: `isShort` scenes → `BookShort-NN` compositions registered dynamically in Root.tsx → `make render-shorts`
- **Content Factory**: `/produce-video` Phase 7 — NotebookLM generates podcast (deep-dive, debate) + audio briefing after render
- **Explicit chapters**: `resolveChapters()` prefers explicit chapters from scenes.json over auto-detection

### Knowledge Vault (Phase 2)

- **Location**: `knowledge-base/`
- **Purpose**: Persistent cross-book intelligence — every video enriches the vault, making future videos smarter
- **Structure**: Theme-indexed (concepts by theme, not by book). Authors, connections (contradictions/agreements/evolutions), production metadata
- **Integration**: `/extract-notes` reads vault before research (Step 0), `/create-storyboard` evaluates templates against vault state, `/produce-video` auto-catalogs after render (Phase 6.5)
- **NotebookLM**: "Bookie: Library" Master notebook accumulates all book sources for AI-powered cross-book queries
- **Narrative Templates**: 5 templates in `templates/narrative-templates.md` — each triggered by vault state (Contrarian Analysis, Hidden Connection, Meta-Pattern, Author Portrait, The Tension)

## External Integrations
- **NotebookLM**: MCP via `notebooklm-mcp-cli` (unofficial API)
- **viXTTS**: REST API at localhost:8020 (Podman container)
- **Gemini API**: Image generation via `gemini-3.1-flash-image-preview` (`generate-images.sh`)
- **YouTube/Facebook**: Manual upload

## Critical Constraints
- **1-person operation**: Everything must be automatable or very fast manually
- **GPU bound**: viXTTS runs on local GPU — can't run while gaming/training
- **No CI/CD**: Content pipeline, not software deployment
