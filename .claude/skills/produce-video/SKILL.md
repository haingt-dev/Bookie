---
name: produce-video
description: >-
  Full pipeline: deep research to rendered video. User chooses angle, rest is
  automated. Triggers: "produce video", "produce [book]", "full pipeline",
  "make video for [book]".
argument-hint: "<book-slug>"
---

# Produce Video

End-to-end video production for Bookie book videos. Takes a book from raw source material to a rendered video in a single conversation, with one human decision: choosing the angle.

This orchestrator delegates each creative phase to its specialist skill and handles the glue between them: voice generation, pipeline execution, content factory, and resume logic.

**Working directory**: `/home/haint/Projects/Bookie/projects/ai-book-video`

**Input**: `<book-slug>` (e.g., `atomic-habits`) + author name + book source material (PDF, Drive link, or text)

## Resuming

If `books/<slug>/` already has files from a previous run, skip completed phases:

- `notes.md` exists → skip Phase 1, read it and go to Phase 2
- `storyboard.md` exists → ask if user wants to reuse or regenerate
- `chunks.md` exists → ask if user wants to reuse or regenerate
- `audio/voiceover.wav` exists → ask if user wants to reuse or re-voice
- `image-prompts.md` exists → ask if user wants to reuse or regenerate
- `scenes/` has images → `produce.sh` skips existing images automatically

---

## Phase 1: Deep Research + Angle Selection

Invoke `/extract-notes <slug>`. This handles:
- Knowledge Vault context check (cross-book connections)
- NotebookLM research hub creation (15+ sources across 7 categories)
- Competitive analysis (YouTube + web)
- Structured notes.md output
- 3 angle proposals with template recommendations

**Output**: `books/<slug>/notes.md` with chosen angle. The skill ends with angle selection — user picks via AskUserQuestion.

---

## Phase 2: Creative Generation

### 2a. Storyboard

Invoke `/create-storyboard <slug>`. Uses the chosen angle + recommended narrative template from notes.md.

**Output**: `books/<slug>/storyboard.md` with 7-9 scenes, visual concepts, and pacing.

### 2b. Script

Invoke `/write-video <slug>`. Produces paired chunk files from storyboard.

**Output**: `books/<slug>/chunks.md` (TTS-normalized) + `books/<slug>/chunks-display.md` (natural Vietnamese for subtitles).

---

## Phase 3: Voice Production

### 3a. Check viXTTS

```bash
curl -s --max-time 3 http://127.0.0.1:8020/speakers
```

If unreachable, tell the user:

> viXTTS server is not running. Start it: `./scripts/vixtts-server.sh start`
> Then tell me to continue.

Wait for the user to confirm before proceeding.

### 3b. Generate Voice

```bash
make -C /home/haint/Projects/Bookie/projects/ai-book-video voice BOOK=<slug>
```

This produces:

- `audio/voiceover.wav` — the voiceover
- `output/section-timing.json` — **timing authority** for all subsequent steps

Report the total duration from section-timing.json.

---

## Phase 4: Visual Production

### 4a. Image Prompts

Invoke `/generate-prompts <slug>`. Reads section-timing.json + storyboard.md + brand style guide to generate per-scene Gemini prompts.

**Output**: `books/<slug>/image-prompts.md` with style-prefixed prompts per scene.

### 4b. Run Production Pipeline

```bash
/home/haint/Projects/Bookie/projects/ai-book-video/scripts/produce.sh <slug> --skip-voice
```

This runs: images → subtitle → scenes → sync → validate → render.

If it fails, report the error and suggest recovery.

---

## Phase 5: Report

After pipeline completes:

- Video file path
- Duration (mm:ss)
- File size
- "Preview your video. Publish when ready."

---

## Phase 6: Post-Production

### 6a. Metadata

Invoke `/write-metadata <slug>`. Generates YouTube title/description/tags and Facebook caption.

**Output**: `books/<slug>/metadata.md`

### 6b. Catalog Insights

Invoke `/catalog-insights <slug>`. Catalogs concepts, author profile, and cross-book connections to the Knowledge Vault. This is what makes the system compound — every video makes the next one smarter.

---

## Phase 7: Content Factory

After catalog, multiply the video into derivative audio content using NotebookLM MCP. Each artifact is independent — failures don't block others.

**Prerequisites**: Video rendered, notes.md exists in "Bookie: Library" Master notebook (added in Phase 6b).

1. Get the notebook ID for "Bookie: Library" (`cb5c5ce4-4405-44a9-9a94-c7663c896aa9`)
2. Create deep-dive podcast:
   - `studio_create(artifact_type="audio")` with style "deep_dive" focused on this book's angle
   - Poll `studio_status` every 30s (max 15min timeout)
   - On completion: `download_artifact(artifact_type="audio")` → `books/<slug>/output/podcast-deep-dive.wav`
3. Create debate podcast:
   - `studio_create(artifact_type="audio")` with style "debate" — opposing viewpoints on the book's thesis
   - Poll + download → `books/<slug>/output/podcast-debate.wav`
4. Create audio briefing:
   - `studio_create(artifact_type="audio")` with style "briefing" — 5-minute executive summary
   - Poll + download → `books/<slug>/output/brief-audio.wav`

**Report at end:**
- Which artifacts succeeded/failed
- File paths and durations
- Total content pieces produced (video + shorts + podcasts + brief)

---

## Granular Iteration

If the user wants to redo just one step, point them to individual skills:

- `/extract-notes <slug>` — redo research + angle
- `/create-storyboard <slug>` — redo story structure
- `/write-video <slug>` — redo script
- `/generate-prompts <slug>` — redo image prompts
- `/write-metadata <slug>` — redo YouTube/FB copy
- `/catalog-insights <slug>` — catalog to Knowledge Vault
- `make produce BOOK=<slug>` — rerun production pipeline
