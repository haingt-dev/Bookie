# Current Context

> **Last Updated**: 2026-03-07
> **Updated By**: Claude Code (with Hai)

## Current Focus
**Goal**: Complete gia-dinh-hector-malot production + publish both videos
**Progress**: Second book (Không Gia Đình & Trong Gia Đình) fully produced — research, storyboard, script, voice, images, subtitles, render all done. Knowledge vault cataloged. Extract-notes skill upgraded with deep research hub methodology.

## Active Workstreams
1. **AI Book Video Pipeline**
   - **Status**: Two videos produced. Pipeline improvements shipped (Makefile UX, Remotion render quality, extract-notes deep research).
   - **Owner**: Hai
   - **Priority**: High
   - **Next Actions**:
     1. `/write-metadata atomic-habits` — YouTube/FB metadata
     2. `/write-metadata gia-dinh-hector-malot` — YouTube/FB metadata
     3. Publish both videos (YouTube + Facebook)
     4. Pick next book → `/produce-video <slug>`

## Recent Changes (Last 30 Days)

- **2026-03-07** `feat`: Second book produced — Không Gia Đình & Trong Gia Đình (Hector Malot)
  - Full pipeline: research → storyboard → script → voice → images → subtitle → render
  - Author Portrait template, 8 scenes, 4:39 duration
  - Knowledge vault cataloged (identity, family concepts + cross-book connections)
  - Extract-notes skill upgraded: deep research hub (7 source categories, min 15 sources, multilingual yt-dlp)
  - Makefile: added `make start/stop/status` (viXTTS), `need-book` guard macro, `--audio-bitrate 320k`
  - Remotion: YouTube-optimal render (H.264, CRF 18, GPU accel, auto concurrency)
- **2026-03-07** `feat`: Visual identity upgrade — flat → textured editorial
  - Updated `brand/style-guide.md` (single source of truth) and `/generate-prompts` skill
  - Risograph-inspired grain, paper texture, visible brushwork, soft shadows, layered depth
  - Zero pipeline change — Gemini prompts pick up new style automatically
  - Atomic Habits ships with flat style; new books use textured editorial
- **2026-03-07** `chore`: Pipeline cleanup
  - Deleted dead files: 3 SUPERSEDED templates, content-calendar, ffmpeg temp, 3 stale plan files
  - Fixed WORKFLOW.md broken `make all` reference → `make produce`
  - Updated all memory bank docs for accuracy
  - Added `ffmpeg2pass*` to .gitignore
- **2026-03-07** `feat`: Visual overlay system
  - 4 ambient overlay components: AmbientParticles (bokeh), LightLeak (cinematic sweep), CornerAccents (editorial brackets), WaveformDecor (neon edge spectrum)
  - Plus GrainOverlay (film texture) and Vignette (depth)
  - Z-order: SceneSlide → AmbientParticles → WaveformDecor → LightLeak → SceneTitle → Vignette → CornerAccents → Grain → BrandBar → Subtitle
- **2026-03-07** `feat`: Phase 3 — Multi-Modal Outputs + Pipeline Enrichment
  - Enriched scenes.json: meta, chapters, per-scene visual overrides, isShort
  - Content-forward Intro, dynamic BookShort compositions, Content Factory (NotebookLM audio)
- **2026-03-07** `feat`: Phase 2 — Knowledge Vault + Narrative Engine
  - knowledge-base/ (theme-indexed concepts, author profiles, cross-book connections)
  - 5 narrative templates, /catalog-insights skill, Master notebook in NotebookLM
- **2026-03-07** `feat`: Full pipeline automation
  - produce.sh orchestrator + /produce-video master skill
- **2026-03-06** `feat`: Story-first pipeline redesign
  - /create-storyboard, /write-video, /generate-prompts skills
  - Paired chunk files, balanced subtitle splitting
- **2026-03-05** `feat`: Full pipeline build-out (viXTTS, Remotion, scripts)
- **2026-03-03** `feat`: Infrastructure setup

## Context Carry-Forward
**For Next Session**:

- Write metadata for both videos → publish
- Pick next book and run `/produce-video <slug>`
- Test `make render-shorts` for both books if shorts needed

## Known Issues & Workarounds
- **viXTTS manual start**: Podman container needs `./scripts/vixtts-server.sh start` each session
- **NotebookLM CLI fragility**: `nlm` uses internal APIs — may break on Google updates. Fallback: web UI
- **vixtts-server.sh speaker mismatch**: `setup` creates speaker `bookie-hai` but pipeline uses `fonos`. Works because `fonos` already exists. Would break on fresh setup.
- **Gap config duplication**: generate-voice.sh and generate-subtitle.sh define pace gaps independently. Must sync manually if changed.

## Key Files & Locations
- `WORKFLOW.md` — Pipeline docs + Full Auto Mode + Makefile usage
- `Makefile` — `make <target> BOOK=<slug>` (produce, voice, subtitle, images, etc.)
- `scripts/produce.sh` — Full pipeline orchestrator (skip flags)
- `.claude/skills/produce-video/` — Master orchestration skill
- `books/<slug>/` — Per-book content (script, scenes, audio, output)
- `knowledge-base/` — Cross-book intelligence vault
- `templates/narrative-templates.md` — 5 narrative templates (only surviving template file)
