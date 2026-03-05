---
name: write-storyboard
description: >-
  Write storyboard with per-scene visual descriptions and AI image prompts
  for a Bookie book video. Use when the user wants to create a storyboard,
  generate image prompts, or build visual descriptions from an approved script.
  Triggers: "write storyboard", "storyboard cho [book]", "generate image prompts",
  "visual prompts", "create storyboard from script".
argument-hint: "<book-slug>"
---

# Write Storyboard

Generate per-scene visual descriptions and AI image prompts for a Bookie book video.

## Context

- **Khi nao dung**: Script da duoc approve, voice da ok. Can viet visual prompts cho tung scene.
- **Input**: `script.md` (approved, with scene markers) + `brand/style-guide.md`
- **Output**: `storyboard.md` (per-scene visual + image prompts)
- **Reference**: Xem `books/atomic-habits/storyboard.md` de nam format chuan.

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided. If missing, ask Hai for the book slug (e.g., "atomic-habits"). Set `SLUG=$ARGUMENTS`. Check that `projects/ai-book-video/books/$SLUG/` exists. If `storyboard.md` already exists with content, ask Hai whether to overwrite or revise specific scenes.

2. **Read input files**:
   - Read `projects/ai-book-video/books/$SLUG/script.md` — extract scene markers, section content, timestamps
   - Check scene markers exist (`<!-- scene: scene-XX, pace: ... -->`). If not found, abort and tell user to add scene markers to script.
   - Read `projects/ai-book-video/brand/style-guide.md` — extract Bookie brand colors and style rules
   - If `projects/ai-book-video/books/$SLUG/output/section-timing.json` exists, use actual timestamps from voice. Otherwise use script's estimated timestamps.

3. **Read reference**: Read `projects/ai-book-video/books/atomic-habits/storyboard.md` to match the exact output format and quality level.

4. **Build style prefix**: Read `projects/ai-book-video/brand/style-guide.md` and extract the Bookie brand colors and style instruction block. Use this as the prefix for every image prompt. The style guide is the single source of truth for colors — do NOT hardcode hex values in this skill.

5. **Generate storyboard**: For each scene in script.md, write:
   - **Scene header**: `### Scene XX — [Short description]`
   - **Timestamp**: From timing.json or script estimates
   - **Script excerpt**: Key line from that section (in quotes)
   - **Visual description**: What the scene communicates visually. Focus on metaphor and emotion, not literal depiction. Think editorial illustration.
   - **Image prompt**: Full prompt in natural language (Gemini format). Each prompt should be self-contained, ready to paste into Gemini. Start with the style instruction, then describe the scene in complete sentences. Include "no text, no watermark" inline — Gemini does not use separate negative prompts.
   - **Layers**: `Flat/Ken Burns` for most scenes
   - **Status**: `[ ] Generated  [ ] Approved`

6. **Add summary table**: Scene number, description, effect type.

7. **Visual guidelines**:
   - NO text in images
   - NO realistic faces (simple character design)
   - Focus on metaphor and emotion, not literal scenes
   - Use green (#368C06) for positive/growth elements
   - Use orange (#C86108) for tension/emphasis elements
   - Maintain consistent style across all scene prompts

8. **Decision point**: Present the storyboard. Ask Hai to review visual concepts. He may want to change metaphors for specific scenes or adjust composition.

9. **Write output**: Write complete storyboard to `projects/ai-book-video/books/$SLUG/storyboard.md`

## Format

Output must follow this structure (matching atomic-habits reference):

```
# Storyboard & Image Prompts: [Book Title] — [Angle]

> [Brief context: word count, duration, scene count, angle]

## Style Instruction (dung cho MOI prompt — Gemini natural language)
[Style instruction block]

---

## Scenes

### Scene 01 — [Description]
- **Timestamp**: X:XX - X:XX
- **Script**: "[Key line]"
- **Visual**: [Visual description]
- **Image prompt**: [Full prompt with style prefix]
- **Layers**: Flat/Ken Burns
- **Status**: [ ] Generated  [ ] Approved

[... repeat for each scene ...]
```
