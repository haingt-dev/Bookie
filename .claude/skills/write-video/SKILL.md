---
name: write-video
description: >-
  Write a book video script as paired TTS-ready chunks (chunks.md + chunks-display.md).
  Triggers: "write video", "write script", "viết script", "script cho [book]",
  "revise script", "draft video".
argument-hint: "<book-slug>"
---

# Write Video Script

Write a Bookie book video script directly as numbered chunks, outputting paired files for display (subtitles) and TTS (voice generation). This replaces the old write-script + split-script + estimate flow.

## Context

- **When to use**: After `/create-storyboard` produces storyboard.md. Before `make voice`.
- **Input**: `storyboard.md` (story direction) + `notes.md` (insights) + `tts-config.json` (normalization rules)
- **Output**: `chunks-display.md` (readable script + subtitle source) + `chunks.md` (TTS-normalized)

## Pipeline Position

```
/create-storyboard → storyboard.md
        ↓
/write-video → chunks-display.md + chunks.md  ← YOU ARE HERE
        ↓
make voice → audio + section-timing.json
        ↓
/generate-prompts → image-prompts.md
```

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided. If missing, ask Hai for the book slug. Set `SLUG=$ARGUMENTS`. Check that `projects/ai-book-video/books/$SLUG/` exists.

2. **Read input files**:
   - Read `projects/ai-book-video/books/$SLUG/storyboard.md` — scene plan, story arc, pacing
   - Read `projects/ai-book-video/books/$SLUG/notes.md` — book title, author, insights, angle, stories
   - Read `projects/ai-book-video/tts-config.json` — chunk params and `en_to_vn` dictionary
   - Read `projects/ai-book-video/brand/style-guide.md` — tone reference

   If storyboard.md is missing, warn and ask if Hai wants to proceed without it (using notes.md only) or run `/create-storyboard` first.

3. **Detect mode**:
   - If `chunks-display.md` exists with actual narration content → **revision** mode: ask Hai what to change
   - If missing or empty → **new draft** mode

4. **Write display chunks** (new draft):

   Follow the storyboard's scene plan. Write narration as numbered chunks `[NNN] "text"`. Each chunk is one natural speech unit — a complete thought that sounds right when spoken aloud.

   **Structure** follows the storyboard scenes. Typical flow:
   - **HOOK**: Provocative opening. Never "Xin chào" or channel intro.
   - **CONTEXT**: Establish fairness, introduce book, setup video structure.
   - **Content scenes**: Concept → specific story/example → real-world connection.
   - **TAKEAWAY**: One actionable thing the viewer can do today.
   - **CTA**: Light — subscribe, comment. Never pushy.

   Word count is flexible — write the best story, don't hit a target. The video is as long as the story needs.

5. **Generate TTS chunks**: For each display chunk, create its TTS-normalized version. Apply these rules (from `tts-config.json`):

   **Numbers → Vietnamese words**:
   - Integers: `37` → `"ba mươi bảy"`, `1000` → `"một nghìn"`
   - Percentages: `1%` → `"một phần trăm"`
   - Decimals: `13.5` → `"mười ba phẩy năm"`
   - Ordinals: `thứ 3` → `"thứ ba"`
   - Numbers already as words → pass through

   **EN terms → Vietnamese** (from `en_to_vn` dictionary):
   - Look up multi-word EN phrases. Replace if found in dictionary.
   - Short Vinglish (1-2 syllables: gym, blog, fan, team, ok, feedback, trend, style, app, web, like, share) → keep as-is. viXTTS handles these.
   - Proper nouns (James Clear, PayPal, Stanford) → keep as-is.
   - Long EN terms (>2 syllables) NOT in dictionary → flag with `<!-- WARNING: unknown EN "term" -->`.
   - **Fail gate**: If >2 unmapped long EN terms, STOP. List them all. Ask Hai to add translations to `tts-config.json` `en_to_vn` or rephrase. Do NOT write output files with unmapped terms — they cause poor TTS quality.

   **Avoid patterns** (from `avoid_patterns` in tts-config.json):
   - `...` → `.` — ellipsis causes TTS artifacts.

6. **Validate TTS chunks**: Check each TTS chunk's character count (Python `len()`, not byte count).
   - Sweet spot: 75-250 chars
   - Flag chunks outside range with `<!-- WARNING: X chars -->`
   - Chunks <30 chars are noise — consider merging with a neighbor
   - Chunks >250 chars risk TTS instability — consider splitting at a clause boundary

7. **Write both files** to `projects/ai-book-video/books/$SLUG/`

8. **Print summary**:
   - Total chunks, total words
   - Per-scene breakdown (scene, chunk count, shorts candidates)
   - Normalizations applied (numbers converted, EN terms translated)
   - Any warnings (short/long chunks, unknown EN terms)
   - Next step: `make voice BOOK=$SLUG`

## Output: `chunks-display.md`

This is the human-readable script AND the subtitle source. Viewers see this text.

```markdown
# Script: [Book Title] — [Angle/Subtitle]

> **Tác giả**: [Author]
> **Angle**: [Chosen angle]
> **Ngày tạo**: [Today's date]

<!-- voice: temp=0.80 -->

<!-- scene: scene-01, pace: slow -->
## HOOK

[001] "Mỗi ngày tốt hơn 1%, một năm sau bạn sẽ giỏi hơn 37 lần."

[002] "Nghe quen không? Con số này xuất hiện trong hàng trăm video, hàng ngàn bài viết."

[003] "Nó là lời hứa đẹp nhất của cuốn sách bán chạy nhất thế giới về thói quen. Atomic Habits."

---

[004] "Nhưng nếu mình nói với bạn rằng con số đó không thật thì sao?"

**[SHORT]**

<!-- scene: scene-02, pace: normal -->
## CONTEXT

[005] "Đừng hiểu nhầm. Đây không phải video chỉ trích Atomic Habits. Cuốn sách này thay đổi cuộc đời hàng triệu người, và nó xứng đáng với sự tôn trọng đó."
...
```

## Output: `chunks.md`

TTS-normalized version. Same structure, normalized text. This is what viXTTS speaks.

```markdown
# Chunks (TTS): [Book Title]
> Generated by /write-video on [date]
> Config: min=75 target=140 max=250 chars

<!-- scene: scene-01, pace: slow -->
## Scene 01

[001] "Mỗi ngày tốt hơn một phần trăm, một năm sau bạn sẽ giỏi hơn ba mươi bảy lần."

[002] "Nghe quen không? Con số này xuất hiện trong hàng trăm video, hàng ngàn bài viết."

---

[003] "Nhưng nếu mình nói với bạn rằng con số đó không thật thì sao?"

<!-- scene: scene-02, pace: normal -->
## Scene 02

[004] "Đừng hiểu nhầm. Đây không phải video chỉ trích Atomic Habits. Cuốn sách này thay đổi cuộc đời hàng triệu người, và nó xứng đáng với sự tôn trọng đó."
...
```

## Format Rules

Both files share this structure:
- Scene markers: `<!-- scene: scene-XX, pace: slow|normal|fast -->`
- Section headings: `## HOOK`, `## CONTEXT`, etc. (in chunks-display.md) or `## Scene 01` (in chunks.md)
- Chunks: `[NNN] "text"` — sequential numbering across all scenes
- Paragraph breaks: `---` between chunks (indicates longer pause in voice)
- Shorts markers: `**[SHORT]**` (only in chunks-display.md)
- Voice config: `<!-- voice: temp=0.80 -->` (only in chunks-display.md header)
- Blank line between every chunk

## Chunk-Aware Writing

The key difference from old write-script: you think in chunks from the start. Each chunk is a speech unit that viXTTS will voice individually.

**What makes a good chunk:**
- One complete thought — it sounds natural spoken alone
- 75-250 characters (TTS text after normalization). Sweet spot is 100-200.
- Sentence boundaries align with chunk boundaries wherever possible
- A chunk can contain multiple short sentences if they form one thought
- A chunk should never split a sentence across two chunks

**Short dramatic chunks** (<75 chars) are fine for pacing — a punchy one-liner like `"Con người không cộng dồn đều như lãi kép."` works great even at 41 chars. Flag them but don't force-merge if the drama serves the story.

**Paragraph breaks** (`---`) indicate a longer pause. Use them at emotional transitions, topic shifts, or before a punchline.

## Writing Guidelines

**Tone**:
- Vietnamese, natural storytelling — like telling a friend over coffee
- First person: "mình"
- Not academic, not preachy, not robotic
- All Vietnamese with proper diacritics (có dấu)

**Language rules** (viXTTS is a pure Vietnamese model):
- Pure Vietnamese is the default
- Short Vinglish (1-2 syllables) OK: gym, blog, fan, team, ok, feedback, trend, style, app, web
- Long EN terms (>2 syllables) → translate to Vietnamese. Check `en_to_vn` in tts-config.json.
- Proper nouns (James Clear, PayPal) → keep as-is
- Numbers: write naturally in display text (37, 1%, 365). The TTS version normalizes them.

**TTS-friendly sentences**:
- Keep sentences 75-200 chars. Break longer ones at natural clause boundaries.
- Avoid em dashes in long clauses — viXTTS pauses awkwardly. Use period + new sentence.
- Avoid ellipsis (...) — causes TTS artifacts. Use question or period instead.
- Prefer simple structures: Subject + Verb + Object. Nested clauses cause unpredictable pauses.
- Avoid fragments <30 chars — they produce unreliable TTS output.

## Revision Mode

When chunks-display.md exists with content:
1. Read both chunk files
2. Ask Hai what to change
3. Revise specific chunks/scenes — keep surrounding chunks intact
4. Regenerate TTS versions for changed chunks
5. Revalidate chunk sizes

Common feedback:
- "Hook not strong enough" → rewrite opening chunks more provocatively
- "This sounds robotic" → more natural phrasing
- "Scene 3 too long" → tighten, split, or merge chunks
- "Missing short candidates" → mark additional `**[SHORT]**` segments

## Important

- Both files have identical chunk numbering — `[001]` in display maps to `[001]` in TTS
- Scene markers and pace values identical in both files
- The display file IS the readable script — there's no separate script.md
- Vietnamese text: count chars with `len()` (Python), not byte count. Config values are character counts.
- After writing, next step: `make voice BOOK=$SLUG`
