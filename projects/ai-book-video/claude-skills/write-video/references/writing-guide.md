# Writing Guide

Contains: chunk-aware writing guidelines, hook/context patterns, revision mode procedure, tone and style rules.
Read this when: drafting new chunks, choosing how to structure a scene, handling revision requests, or applying tone/language rules.

---

## Chunk-Aware Writing

The key difference from the old write-script approach: think in chunks from the start. Each chunk is a speech unit that viXTTS will voice individually.

**What makes a good chunk:**
- One complete thought — it sounds natural spoken alone
- 75-250 characters (TTS text after normalization). Sweet spot is 100-200.
- Sentence boundaries align with chunk boundaries wherever possible
- A chunk can contain multiple short sentences if they form one thought
- A chunk should never split a sentence across two chunks

**Paragraph breaks** (`---`) indicate a longer pause. Use them at emotional transitions, topic shifts, or before a punchline.

**Short dramatic chunks** (<75 chars) are fine for pacing — a punchy one-liner like `"Con người không cộng dồn đều như lãi kép."` works great even at 41 chars. Flag them but don't force-merge if the drama serves the story.

## Scene Structure

Follow the storyboard's scene plan. Typical flow:

- **HOOK**: Provocative opening. Never "Xin chào" or channel intro. Start mid-tension — a surprising claim, a contradiction, a question that destabilizes.
- **CONTEXT**: Establish fairness, introduce the book, set up the video structure. Acknowledge the book's real value before critique or exploration.
- **Content scenes**: Concept → specific story/example → real-world connection. Each scene should stand alone but build on the prior.
- **TAKEAWAY**: One actionable thing the viewer can do today. Concrete and specific, not vague advice.
- **CTA**: Light — subscribe, comment. Never pushy.

Word count is flexible — write the best story, don't hit a target. The video is as long as the story needs.

## Tone and Style

**Voice:**
- Vietnamese, natural storytelling — like telling a friend over coffee
- First person: "mình"
- Not academic, not preachy, not robotic
- All Vietnamese with proper diacritics (có dấu)

**Language rules** (viXTTS is a pure Vietnamese model):
- Pure Vietnamese is the default
- Short Vinglish (1-2 syllables) OK: `gym`, `blog`, `fan`, `team`, `ok`, `feedback`, `trend`, `style`, `app`, `web`
- Long EN terms (>2 syllables) → translate to Vietnamese. Check `en_to_vn` in tts-config.json.
- Proper nouns (James Clear, PayPal) → keep as-is
- Numbers: write naturally in display text (37, 1%, 365). The TTS version normalizes them.

**TTS-friendly sentence construction:**
- Keep sentences 75-200 chars. Break longer ones at natural clause boundaries.
- Avoid em dashes in long clauses — viXTTS pauses awkwardly. Use period + new sentence instead.
- Avoid ellipsis (...) — causes TTS artifacts. Use question or period instead.
- Prefer simple structures: Subject + Verb + Object. Nested clauses cause unpredictable pauses.
- Avoid fragments <30 chars — they produce unreliable TTS output.

## Revision Mode

Triggered when `chunks-display.md` exists with actual narration content.

**Procedure:**
1. Read both chunk files
2. Ask Hai what to change
3. Revise specific chunks/scenes — keep surrounding chunks intact
4. Regenerate TTS versions for changed chunks only
5. Revalidate chunk sizes for all modified chunks

**Common feedback patterns:**
- "Hook not strong enough" → rewrite opening chunks more provocatively, start with a harder claim
- "This sounds robotic" → more natural phrasing, shorter sentences, conversational particles
- "Scene 3 too long" → tighten, split, or merge chunks; cut repetition
- "Missing short candidates" → mark additional `**[SHORT]**` segments where a 30-60 sec standalone clip works
