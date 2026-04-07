---
name: create-storyboard
description: "Plan story direction, scenes, narrative arc, pacing"
disable-model-invocation: false
argument-hint: "<book-slug>"
---

# Create Storyboard

Plan story direction for a Bookie book video. This is pure narrative planning — no script text, no timestamps, no image prompts. Those come later in the pipeline.

## Context

- **When to use**: After `/extract-notes` produces notes.md with a chosen angle. Before `/write-video`.
- **Input**: `notes.md` (book insights, stories, criticism research, chosen angle)
- **Output**: `storyboard.md` (story arc + per-scene direction)

## Pipeline Position

```
/extract-notes → notes.md + angle
        ↓
/create-storyboard → storyboard.md  ← YOU ARE HERE
        ↓
/write-video → chunks-display.md + chunks.md
        ↓
make voice → audio + timing
        ↓
/generate-prompts → image-prompts.md
```

The storyboard guides `/write-video` — it defines WHAT each scene should accomplish and FEEL like, so the script writer can focus on HOW to say it.

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided. If missing, ask Hai for the book slug (e.g., "atomic-habits"). Set `SLUG=$ARGUMENTS`. Check that `projects/ai-book-video/books/$SLUG/` exists.

2. **Read input**: Read `projects/ai-book-video/books/$SLUG/notes.md`. Extract:
   - Book title and author
   - Key insights (concepts, stories, examples)
   - Chosen angle (from "Angle đã chọn" section)
   - Recommended template (if specified in chosen angle)
   - Criticism research (if contrarian angle)
   - Competitive analysis (what others have done)
   - Vault context (if present — cross-book connections, existing themes)

   If notes.md has no "Angle" section or is empty, abort: tell user to run `/extract-notes` first.

3. **Template selection**:

   Read `projects/ai-book-video/templates/narrative-templates.md` and `projects/ai-book-video/knowledge-base/` to evaluate which templates are activated by vault state.

   a. Check vault state:
      - Read `knowledge-base/library.md` — how many books covered
      - Read `knowledge-base/connections/` — any cross-book tensions/agreements
      - Read relevant `knowledge-base/concepts/` files — theme overlap

   b. Evaluate each template's trigger condition:
      - **Contrarian Analysis**: 1+ book in library, mainstream reception, gap in VN YouTube → always available after first book
      - **Hidden Connection**: 1+ entry in connections/ linking 2 books → available when vault has cross-book data
      - **Meta-Pattern**: 3+ entries in one concepts/ file from different books → available when theme has depth
      - **Author Portrait**: Substantial authors/ file, 2+ books by same author → available for well-researched authors
      - **The Tension**: High-tension entry in contradictions/ → available when clear author-vs-author clash exists

   c. Present activated templates with rationale. If notes.md already recommends a template, highlight it. Ask Hai to pick a template or "custom" (freeform arc).

4. **Detect mode**:
   - If `storyboard.md` exists with content → ask Hai whether to overwrite or revise specific scenes
   - If missing or empty → new draft mode

5. **Plan the story arc**: Based on the chosen angle + selected template, design the narrative shape.

   **If template selected**: Use its scene structure as the skeleton. The template defines the scene labels, purposes, and emotional arc. The storyboard fills in specific content from notes.md.

   **If custom**: Design from scratch. Think about:
   - What's the emotional journey? (curiosity → realization → action)
   - Where's the tension? Where's the release?
   - What's the "one thing" the viewer should remember?
   - How many scenes? (typically 7-10 for a 5-8 minute video)

6. **Design each scene**: For every scene, define:
   - **Purpose**: What this scene accomplishes in the story (one sentence)
   - **Emotion**: What the viewer should feel during this scene
   - **Key content**: Which insight/story/example from notes.md drives this scene
   - **Visual concept**: A metaphor or image that communicates the idea visually. Think editorial illustration — abstract, symbolic, evocative. Not literal.
   - **Pace**: `slow` (dramatic, reflective), `normal` (narration), or `fast` (energetic)
   - **Shorts candidate**: Could this scene work as a standalone 15-60s clip?

7. **Present to Hai**: Show the storyboard. This is naturally iterative — Hai may want to:
   - Reorder scenes
   - Change the emotional arc
   - Swap visual metaphors
   - Add or remove scenes
   - Adjust pacing

8. **Write output**: Write to `projects/ai-book-video/books/$SLUG/storyboard.md`

## Output Format

```markdown
# Storyboard: [Book Title] — [Angle/Subtitle]

> **Tác giả**: [Author]
> **Angle**: [Chosen angle from notes.md]
> **Template**: [Template name or "Custom"]
> **Scenes**: [N] scenes

## Story Arc

[One-paragraph summary of the narrative shape. What's the emotional journey?
Where does tension build? Where does it release? What's the takeaway?]

## Scenes

### Scene 01 — [Short label, e.g., HOOK]
- **Purpose**: [What this scene does for the story]
- **Emotion**: [What the viewer feels]
- **Key content**: [Which insight/story from notes.md]
- **Visual concept**: [Metaphor or symbolic image]
- **Pace**: slow | normal | fast
- **Shorts**: Yes | No

### Scene 02 — [Label]
...

## Summary

| Scene | Label | Emotion | Pace | Shorts |
|-------|-------|---------|------|--------|
| 01 | HOOK | Curiosity → doubt | slow | Yes |
| 02 | CONTEXT | Respect | normal | No |
...
```

## What This Skill Does NOT Include

These are handled by other pipeline steps:

- **Narration text**: That's `/write-video`. The storyboard says "this scene should make the viewer feel doubt" — the script writer decides the exact words.
- **Timestamps**: Timing comes from `make voice` (actual TTS output). The storyboard doesn't predict duration.
- **Image prompts**: Those are generated by `/generate-prompts` after voice, when actual scene timing is known.

The storyboard is a direction document, not a production spec. Keep it lean and focused on story intent.

## Scene Design Guidelines

- **HOOK** should be provocative or surprising — not "Xin chào" or channel intro
- **CONTEXT** establishes credibility and fairness before diving into content
- Each **content scene** should follow: concept → specific story/example → real-world connection
- **TAKEAWAY** gives the viewer one actionable thing they can do today
- **CTA** is light — subscribe, comment, suggest next book. Never pushy.
- Visual concepts should be metaphorical, not literal. "A cracking graph" not "a person reading a book."
- Pace variety matters — if everything is `normal`, the video feels flat. Use `slow` for dramatic moments and `fast` for energy.
- Mark strong shorts candidates — these drive discovery on YouTube/TikTok.

## Important

- All output content in Vietnamese (scene labels can mix Vietnamese and English where natural)
- The storyboard is a living document — it guides the script but doesn't constrain it rigidly
- Focus on emotional arc over information density. A video that makes viewers feel something gets shared; one that dumps information gets forgotten.
