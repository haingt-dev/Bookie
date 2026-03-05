---
name: write-script
description: >-
  Write or revise a Bookie book video script with scene markers and pace control.
  Use when the user wants to write a script from notes, draft a new script,
  revise an existing script, or fix specific sections.
  Triggers: "write script", "viet script", "revise script", "fix hook",
  "script cho [book]", "script dai qua", "rewrite section".
argument-hint: "<book-slug>"
---

# Write Video Script

Write or revise a Bookie book video script with scene markers and pace control.

## Context

- **Khi nao dung**: Da co notes.md voi angle da chon, can viet script cho video.
- **Input**: `notes.md` (with chosen angle section)
- **Output**: `script.md` (narration + scene/pace markers)
- **Reference format**: Xem `templates/script-template.md` va `books/atomic-habits/script.md`

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided. If missing, ask Hai for the book slug (e.g., "atomic-habits"). Set `SLUG=$ARGUMENTS`. Check that `projects/ai-book-video/books/$SLUG/` exists.

2. **Read input files**:
   - Read `projects/ai-book-video/books/$SLUG/notes.md` — extract book title, author, chosen angle, key insights
   - If notes.md has no "Angle" section or is empty/scaffold, abort: tell user to run `/extract-notes $SLUG` first.
   - Read `projects/ai-book-video/templates/script-template.md` — structure reference
   - Read `projects/ai-book-video/brand/style-guide.md` — tone reference

3. **Detect mode**:
   - Read `projects/ai-book-video/books/$SLUG/script.md`
   - If content is just the template scaffold (has bracket placeholders like `[Viết hook ở đây]`, `[...]` etc.) → **new draft** mode
   - If content has actual narration → **revision** mode: ask Hai what to change before proceeding

4. **New draft mode** — Write script following this structure:

   **Header**:
   ```
   # Script: [Book Title] — [Angle/Subtitle]
   > **Tac gia**: [Author]
   > **The loai**: [Genre]
   > **Target length**: ~1350-1400 tu (7 phut)
   > **Angle**: [Chosen angle from notes.md]
   > **Ngay tao**: [Today's date]
   ```

   **Sections** (with scene markers before each):
   - **HOOK** (0:00-0:15, ~50 words): 1 provocative question or surprising statement. NEVER start with "Xin chao" or channel intro.
   - **CONTEXT** (0:15-0:45, ~100 words): Introduce book, why it's relevant, setup the video structure.
   - **INSIGHT 1-3** (0:45-6:00, ~300-350 words each): concept → specific story/example → real-world connection. Each insight gets its own scene(s).
   - **TAKEAWAY** (6:00-7:00, ~160 words): 1 specific action audience can do TODAY.
   - **CTA** (7:00-7:30, ~60 words): Light touch — subscribe, suggest next book in comments.

   **Required markers**:
   - Scene markers: `<!-- scene: scene-XX, pace: slow|normal|fast -->` before each visual section
   - Voice config: `<!-- voice: temp=0.80 -->` (default 0.80, lower=more controlled)
   - Shorts: `**[SHORT]**` on segments that work as standalone 15-60s clips

   **Pace guide** (viXTTS ~15 cps, pace controls gap timing only):
   - `slow`: Large gaps (0.40s/0.80s) — dramatic hooks, reflective moments
   - `normal`: Standard gaps (0.15s/0.40s) — narration
   - `fast`: Tight gaps (0.08s/0.20s) — energetic CTA

   **Tone rules**:
   - Vietnamese, natural storytelling — like telling a friend
   - First person: "minh"
   - NOT academic, NOT preachy, NOT robotic
   - Default target: 1350-1400 words (~7 minutes at ~200 wpm). Adjust per book — shorter angles (e.g., contrarian) may need only ~900 words (~5 min). Confirm target with Hai before drafting.

5. **Revision mode** — Read existing script, ask Hai what to change. Revise specific sections while keeping scene markers and overall structure intact.

6. **Decision point**: Present draft (or revision). Hai reviews. This is naturally iterative — expect 2-3 rounds of feedback within the conversation. Common feedback:
   - "Doan nay nghe robotic" → rewrite more naturally
   - "Insight 2 dai qua" → tighten
   - "Hook chua du manh" → make more provocative
   - "Thieu short candidate" → mark additional segments

7. **Write output**: Write final version to `projects/ai-book-video/books/$SLUG/script.md`

8. **Print summary**:
   - Word count
   - Number of scenes
   - Estimated duration (words / 200 wpm)
   - Shorts candidates listed

## Important

- This skill does NOT write storyboard. Per voice-first pipeline, storyboard happens after `make voice` is approved.
- After script is done, next step: `make voice BOOK=$SLUG`
