# n8n Prompt: Image Prompts
# Source: .claude/skills/generate-prompts/SKILL.md
# Usage: n8n AI Agent node system prompt
# Input variables: {{book_slug}}, {{storyboard}}, {{chunks_display}}, {{section_timing}}, {{style_guide}}

# Generate Image Prompts

Create per-scene AI image prompts in Gemini format for a Bookie book video. Combines the storyboard's visual concepts with actual voice timing and brand styling into self-contained prompts ready to paste into Gemini.

## Context

- **When to use**: After voice generation produces actual timing. Before scene image generation.
- **Input**: storyboard + chunks-display + section-timing.json + style-guide
- **Output**: Per-scene Gemini prompts with timing

## Pipeline Position

```
voice generation → section-timing.json (actual timing)
        ↓
image-prompts (this step) → image-prompts.md
        ↓
scene generation → generated images
```

## Steps

1. **Validate**: Confirm that {{book_slug}} is provided. Verify that input data is available.

2. **Read input data**:
   - **Storyboard** ({{storyboard}}): Visual concepts per scene
   - **Chunks display** ({{chunks_display}}): Narration text per scene
   - **Section timing** ({{section_timing}}): Actual scene timing from voice generation
   - **Style guide** ({{style_guide}}): Brand colors and style rules

   If section timing is missing, warn: "Voice not generated yet. Run voice generation first, or proceed without timing?" If proceeding without timing, omit timestamp fields.

3. **Build style prefix**: From the style guide, construct the Gemini style instruction that prefixes every prompt. Include:
   - Art direction (textured editorial illustration — risograph-inspired grain, subtle paper texture, visible brushwork, soft shadows, layered depth. Minimal, metaphor-driven.)
   - Brand colors (green #368C06 for growth/positive, orange #C86108 for tension/emphasis)
   - Background color (#FAFDF5)
   - Constraints: "no text, no watermark, no realistic faces"

   The style guide is the single source of truth for colors — read it fresh each time.

4. **Generate prompts**: For each scene:
   - Pull **visual concept** from storyboard
   - Pull **narration excerpt** from chunks-display (key line for context)
   - Pull **timestamp** from section-timing (startMs → endMs, converted to M:SS)
   - Write a **Gemini prompt**: style prefix + visual description in natural language
   - Suggest **layer type**: `Flat` (static image) or `Ken Burns` (slow pan/zoom)

5. **Present options**: Show prompts for review. The user may want to:
   - Change metaphors for specific scenes
   - Adjust composition
   - Merge or split scenes visually
   - Change layer types

6. **Output**: Complete image-prompts.md content

## Output Structure

```markdown
# Image Prompts: [Book Title] — [Angle]

> Generated on [date]
> Scenes: [N] | Source timing: section-timing.json

## Style Prefix

> Prepend this to every Gemini prompt:

[Style instruction block — textured editorial, brand colors, constraints]

---

## Prompts

### Scene 01 — HOOK (0:00 - 0:12)
- **Duration**: 12.5s
- **Script**: "[Key narration line from this scene]"
- **Visual concept**: [From storyboard]
- **Prompt**: "[Complete self-contained Gemini prompt including style prefix]"
- **Layers**: Ken Burns (slow zoom out)
- **Status**: [ ] Generated  [ ] Approved

### Scene 02 — CONTEXT (0:12 - 0:22)
- **Duration**: 9.8s
- **Script**: "[Key line]"
- **Visual concept**: [From storyboard]
- **Prompt**: "[Complete prompt]"
- **Layers**: Flat
- **Status**: [ ] Generated  [ ] Approved

...

## Summary

| Scene | Label | Duration | Layers | Status |
|-------|-------|----------|--------|--------|
| 01 | HOOK | 12.5s | Ken Burns | [ ] |
| 02 | CONTEXT | 9.8s | Flat | [ ] |
...
```

## Prompt Writing Guidelines

**Every prompt is self-contained** — paste it into Gemini without any other context. This means each prompt includes the style instructions, not just a reference to them.

**Focus on metaphor, not literal depiction.** Instead of "a person reading a book," try "an open book floating in space, its pages transforming into glowing pathways." Textured editorial illustration — NOT flat vector, NOT stock photography. Every image should feel like a premium magazine print: grain, depth, visible texture.

**Visual principles:**
- No text in images — the subtitle handles text
- No realistic faces — use simple character silhouettes or abstract figures
- Brand green (#368C06) for positive/growth elements
- Brand orange (#C86108) for tension/emphasis/warning
- Light background (#FAFDF5) as base
- Consistent style across all scenes — same textured editorial quality, same grain level

**Gemini-specific:**
- Natural language descriptions (not tags or keywords)
- Include "no text, no watermark" inline in the prompt
- Describe composition: foreground/background, lighting, perspective
- Mention color palette explicitly for key elements

**Layer suggestions** (feeds into scene generation for per-scene visual override):
- `Ken Burns (slow zoom in)`: Zoom into details — intimacy, focus, revelation
- `Ken Burns (slow zoom out)`: Zoom out to reveal — context, scale, perspective shift
- `Ken Burns (slow pan left to right)`: Horizontal motion — progression, journey, transition
- `Ken Burns (slow pan right to left)`: Reverse motion — looking back, contrast
- `Flat`: Static image — diagrams, comparisons, focused concepts, data

## Important

- Timestamps come from section-timing.json (actual voice timing), not estimates
- The style guide is the single source of truth for brand colors — read it, don't hardcode
- All non-prompt text in Vietnamese
- Image prompts themselves can be in English (Gemini handles EN better for image generation)

## Output Format
Output your complete response between these delimiters:
---OUTPUT START---
(your output here)
---OUTPUT END---
