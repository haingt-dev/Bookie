---
name: produce-video
description: "Master orchestration skill that automates the ENTIRE Bookie book video pipeline — from deep research to rendered video. User only needs to choose the angle; everything else runs automatically. Use this skill whenever the user wants to produce a video, create a full book video, run the complete pipeline, or start video production for a book. Triggers on: 'produce video', 'produce [book]', 'san xuat video', 'tao video cho [book]', 'full pipeline [book]', 'make video for [book]'. Also trigger when the user mentions a book name with clear intent to create video content, like 'let's do [book]' or 'new video [book]'."
argument-hint: "<book-slug>"
---

# Produce Video

End-to-end video production for Bookie book videos. Takes a book from raw source material to a rendered video in a single conversation, with one human decision: choosing the angle.

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

## Phase 1: Deep Research

Goal: Build a comprehensive knowledge base, then synthesize into angle options.

### 1a. Vault Context

Before research, check the Knowledge Vault for existing intelligence:

1. Read `knowledge-base/library.md` — what books/authors already covered
2. Check `knowledge-base/authors/<author-slug>.md` — do we already know this author?
3. Scan `knowledge-base/concepts/` — any themes that overlap with this book's topic
4. Read `knowledge-base/connections/` — existing cross-book tensions that could inform angle

Summary feeds into angle proposal (Phase 1e). If vault is empty (first book), note it and proceed.

### 1b. NotebookLM Setup

Notebooks are organized by **author**, not by book. This way research about the author (bio, interviews, controversies, other works) carries over when producing videos for multiple books by the same person.

1. Check if a notebook for this author exists via `notebook_list` (search for author name)
2. If found, reuse it — previous research is already there
3. If not found, create via `notebook_create` with name "Bookie: <Author Name>"
4. Import book source via `source_add` (type: file, url, drive, or text)

### 1c. Cast a Wide Net

Research everything connected to this book. The more diverse the sources, the more unique the angle. Import findings into NotebookLM as you go — it becomes the central research hub.

**YouTube competitors** — Find what Vietnamese creators have already covered:

```bash
yt-dlp --flat-playlist --print "%(title)s | %(view_count)s | %(url)s" \
  "ytsearch20:<book-title> sach tieng viet"
```

For the top 5-10 results by views, grab transcripts:

```bash
yt-dlp --write-auto-sub --sub-lang vi --skip-download -o "/tmp/yt-%(id)s" "<url>"
```

Import transcripts into NotebookLM via `source_add` (type: text).

**Reviews & criticism** — WebSearch for:

- Vietnamese: Spiderum, Tiki reviews, Vietnamese book blogs
- International: Goodreads top reviews, Amazon reviews, literary criticism
- Academic perspectives challenging the book's claims

**Forums & discussions** — WebSearch for:

- Reddit threads (r/books, r/selfimprovement, relevant subreddits)
- Hacker News discussions
- Vietnamese forums (Voz, Spiderum comments)

**Author background** — WebSearch for:

- Bio, career, other works
- Interviews, podcast appearances
- Controversies, criticism of the author
- Author's own admissions about the book's limitations

**Drama & debates** — WebSearch for:

- Counter-arguments to the main thesis
- "Why [book] is wrong/overrated" articles
- Academic rebuttals
- Cultural context: Western advice vs Vietnamese reality

Import all valuable findings into NotebookLM via `source_add` (type: text or url). More sources = better synthesis.

### 1d. Synthesize

Query NotebookLM via `notebook_query`:

- "What are the main themes and key insights across ALL sources?"
- "What do critics say the book gets wrong or oversimplifies?"
- "What angles have Vietnamese content creators NOT covered?"
- "What surprising connections exist between different sources?"
- "What would a Vietnamese 25-year-old find most relatable or surprising?"

### 1e. Write notes.md

Write `books/<slug>/notes.md`:

```markdown
# Notes: <Book Title> — <Author>

> **Source**: NotebookLM MCP (<N> sources)
> **Notebook**: Bookie: <Author> (shared across author's works)
> **Notebook ID**: <id>

## Key Insights
### 1. <Theme>
- **Concept**: ...
- **Story**: ...
- **Application**: ...

## Competitive Landscape
- <What Vietnamese creators have covered>
- <Gaps nobody has explored>

## Controversies & Counter-Arguments
- <Criticism, debates, drama>

## Author Context
- <Background that informs the angle>

## Potential Angles
1. <Angle with rationale>
2. <Angle with rationale>
3. <Angle with rationale>
```

### 1f. Present Angles

Present 3-4 angles via `AskUserQuestion`. Each angle should:

- Have a clear contrarian or surprising thesis
- Differ from what competitors have done
- Be supportable with evidence from the research
- Appeal to target audience (Vietnamese 20-35, self-improvement)

---

## Phase 2: Angle Selection

**This is the ONLY user interaction in the entire pipeline.**

Use `AskUserQuestion` with the angles as options, each with a brief rationale. After the user picks, proceed immediately to Phase 3.

---

## Phase 3: Creative Generation

### 3a. Storyboard

Write `books/<slug>/storyboard.md` with 7-9 scenes.

**Narrative arc**:

1. **HOOK** — Surprising statement that challenges assumptions (~20s, pace: slow)
2. **CONTEXT** — Why this matters, establish fairness (~25s, pace: normal)
3-6. **BODY** — 3-4 scenes alternating blind spots and evidence (~40-55s each, pace: normal)
7. **LIEN_HE** — Connect to viewer's life (~25s, pace: normal)
8. **TRADE_OFF** — Nuanced conclusion, not cynical (~50s, pace: normal)
9. **CTA** — Call to action (~15s, pace: fast)

**Each scene**:

```markdown
### Scene NN — LABEL
- **Purpose**: What this scene achieves
- **Emotion**: The feeling it evokes
- **Key content**: Core narration idea
- **Visual concept**: What the viewer sees (for image prompts later)
- **Pace**: slow | normal | fast
- **Shorts**: Yes | No (potential short-form clip?)
```

Total target: 5-7 minutes. Contrarian/surprising angles drive engagement.

### 3b. Script (Paired Chunk Files)

Generate TWO paired files with identical `[NNN]` numbering:

**`books/<slug>/chunks-display.md`** — Natural Vietnamese, subtitle source:

```markdown
<!-- scene: scene-01, pace: slow -->
## HOOK

[001] "Moi ngay tot hon 1%, mot nam sau ban se gioi hon 37 lan."
[002] "Nghe quen khong? Con so nay xuat hien trong hang tram video."
```

**`books/<slug>/chunks.md`** — TTS-normalized for viXTTS:

```markdown
<!-- scene: scene-01, pace: slow -->
## Scene 01

[001] "Moi ngay tot hon mot phan tram, mot nam sau ban se gioi hon ba muoi bay lan."
[002] "Nghe quen khong? Con so nay xuat hien trong hang tram video."
```

#### TTS Rules

viXTTS is a **pure Vietnamese** model — it cannot speak English.

- **Pure Vietnamese** for all narration
- **Short Vinglish** (1-2 syllables) OK: gym, blog, fan, team, ok, feedback, trend, style, app, web, like, share
- **Long EN terms** (>2 syllables) — translate to Vietnamese. viXTTS spells them out phonetically, timing becomes unpredictable
- **Names** (James Clear, etc.) — keep as-is, acceptable with VN phonetics
- **Numbers** in chunks-display.md: natural (37, 1%). In chunks.md: words ("ba muoi bay", "mot phan tram")

#### Chunk Sizing

- Sweet spot: **75-250 chars** per chunk (160 chars = lowest variance)
- Below 50 chars: inconsistent timing. Above 250 chars: CPS drifts

#### Script Length Guide

| Target | Words | Chars (no space) |
|--------|-------|-------------------|
| 5 min  | ~1050 | ~5400             |
| 7 min  | ~1470 | ~7500             |

### 3c. Metadata

Write `books/<slug>/metadata.md`:

```markdown
# Metadata: <Book Title>

## YouTube
- **Title**: [Compelling, <60 chars, Vietnamese]
- **Description**: [300-500 chars, hook + key points + CTA]
- **Tags**: [15-20 tags, mix of VN and EN]
- **Category**: Education

## Facebook
- **Caption**: [Engaging post for Bookie fanpage, question for engagement]

## Shorts Ideas
- [2-3 short-form content ideas from the video]
```

---

## Phase 4: Voice Production

### 4a. Check viXTTS

```bash
curl -s --max-time 3 http://127.0.0.1:8020/speakers
```

If unreachable, tell the user:

> viXTTS server is not running. Start it: `./scripts/vixtts-server.sh start`
> Then tell me to continue.

Wait for the user to confirm before proceeding.

### 4b. Generate Voice

```bash
make -C /home/haint/Projects/Bookie/projects/ai-book-video voice BOOK=<slug>
```

This produces:

- `audio/voiceover.wav` — the voiceover
- `output/section-timing.json` — **timing authority** for all subsequent steps

Report the total duration from section-timing.json.

---

## Phase 5: Visual Production

### 5a. Image Prompts

Read `output/section-timing.json` for actual timing per scene.
Read `storyboard.md` for visual concepts.

Write `books/<slug>/image-prompts.md`:

```markdown
# Image Prompts: <Book Title> — <Angle>

> Generated by /produce-video
> Scenes: N | Source timing: section-timing.json

## Style Prefix

> Prepend to every Gemini prompt:

Flat minimal editorial illustration. Warm, approachable, inspiring tone. Color palette: dark green #368C06 for growth and positive elements, bright green #4AC808 for accents and highlights, orange #C86108 for tension and emphasis, very light green-tinted background #FAFDF5. Simple character design with no realistic faces — use silhouettes or abstract figures. No text, no watermark. 16:9 aspect ratio.

---

## Prompts

### Scene 01 — LABEL (start - end)
- **Duration**: Xs
- **Script**: "First narration line..."
- **Visual concept**: From storyboard
- **Prompt**: "Full style prefix + detailed visual for Gemini"
- **Layers**: Ken Burns (slow zoom in) | Flat
- **Status**: [ ] Generated  [ ] Approved
```

Each prompt must be **self-contained** — include the full style prefix. Gemini has no memory between calls.

**Layer selection**: Ken Burns for scenes >30s, Flat for scenes <30s.

### 5b. Run Production Pipeline

```bash
/home/haint/Projects/Bookie/projects/ai-book-video/scripts/produce.sh <slug> --skip-voice
```

This runs: images → subtitle → scenes → sync → validate → render.

If it fails, report the error and suggest recovery.

---

## Phase 6: Report

After pipeline completes:

- Video file path
- Duration (mm:ss)
- File size
- "Preview your video. Publish when ready."

---

## Phase 6.5: Catalog Insights

After render, automatically catalog this book's knowledge into the vault. This is what makes the system compound — every video makes the next one smarter.

1. Read `books/<slug>/notes.md` and `books/<slug>/storyboard.md`
2. Check `knowledge-base/library.md` — if already cataloged, skip
3. Extract concepts → append to relevant `knowledge-base/concepts/` theme files
4. Create/update author profile in `knowledge-base/authors/`
5. Scan for cross-book connections → append to `knowledge-base/connections/` (contradictions, agreements, evolutions)
6. Append production metadata to `knowledge-base/production.md`
7. Append row to `knowledge-base/library.md`
8. Add `notes.md` to "Bookie: Library" Master notebook via `source_add`
9. Report: new concepts cataloged, connections discovered, vault state

If any step fails, log warning and continue — local vault files are source of truth.

For full catalog with user interaction (theme classification, connection review), use `/catalog-insights <slug>` standalone.

---

## Phase 7: Content Factory

After catalog, multiply the video into derivative audio content using NotebookLM MCP. Each artifact is independent — failures don't block others.

**Prerequisites**: Video rendered, notes.md exists in "Bookie: Library" Master notebook (added in Phase 6.5).

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
