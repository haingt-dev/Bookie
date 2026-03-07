---
name: extract-notes
description: >-
  Extract book notes via NotebookLM and choose video angle for Bookie book video.
  Use when the user wants to research a new book, start the book video pipeline,
  gather book insights, do competitive analysis, or choose a video angle.
  Triggers: "extract notes", "research book", "new book video", "start pipeline",
  "analyze book for video", "choose angle".
argument-hint: "<book-slug>"
---

# Extract Book Notes

Extract structured notes from a book using NotebookLM MCP, then propose video angles for selection.

## Context

- **When to use**: New book ready — need to extract insights and choose video angle.
- **Input**: Book sources (text, URL, or file to add to NotebookLM)
- **Output**: `notes.md` (structured notes + chosen angle)
- **Reference**: See `projects/ai-book-video/books/atomic-habits/notes.md` for the standard format.
- **MCP tools**: NotebookLM MCP (`notebook_create`, `source_add`, `notebook_query`, `notebook_describe`)

## Steps

### Step 0: Vault Context

Before any research, check what the Knowledge Vault already knows. This surfaces cross-book connections and prevents redundant angles.

1. Read `projects/ai-book-video/knowledge-base/library.md` — what books/authors are already covered
2. Check if `projects/ai-book-video/knowledge-base/authors/<author-slug>.md` exists for this book's author
   - If yes: read it — we already know their thesis, strengths, blind spots
3. `Glob` for `projects/ai-book-video/knowledge-base/concepts/*.md` — scan theme files for overlapping concepts
4. Read relevant concept files where this book's themes might connect
5. Read `projects/ai-book-video/knowledge-base/connections/` files (contradictions, agreements, evolutions) for existing cross-book tensions

**Vault summary** (include in notes.md later):
- "We've covered N books. Author [X] is [known/new]. Overlapping themes: [list]. Existing connections: [list]."
- If vault is empty (first book), note: "First book in vault — no cross-references yet."

### Step 0b: Cross-book Query

If the "Bookie: Library" Master notebook exists in NotebookLM:

1. `notebook_list` → find "Bookie: Library" notebook
2. If found, `notebook_query`: "What themes from previously added books relate to [this book's topic]? What contradictions or tensions might arise?"
3. Present findings alongside vault context — these inform angle selection later

If Master notebook doesn't exist or query fails, skip — vault files are source of truth.

### Step 1: Validate

Check that `$ARGUMENTS` is provided. If missing, ask Hai for the book slug (e.g., "atomic-habits"). Set `SLUG=$ARGUMENTS`. Check that `projects/ai-book-video/books/$SLUG/` exists.

### Step 2: Check existing notes

Read `projects/ai-book-video/books/$SLUG/notes.md`. If it already has content beyond the scaffold template, warn and ask Hai before overwriting.

### Step 3: Gather sources

Ask Hai for book sources to add. Options:
- URL(s) — author website, Wikipedia, book summary pages
- Text — pasted book excerpts or summaries
- File — local file path to book text
- Existing NotebookLM notebook ID (if already created manually)

### Step 4: NotebookLM extraction

Using MCP tools:
- Create a new notebook: `notebook_create` with name "[Book Title] — Bookie Research"
- Add sources: `source_add` for each URL/text/file
- Configure chat with Bookie analytical lens via `chat_configure`:
  ```
  Bạn là trợ lý nghiên cứu sách cho kênh Bookie (Việt Nam). Khi phân tích:
  1) Tìm mâu thuẫn với các cuốn sách đã thêm trước đó
  2) Phát hiện thiên lệch văn hóa (Western vs Vietnamese)
  3) Tìm patterns xuyên suốt nhiều nguồn
  4) Gợi ý kết nối bất ngờ giữa các tác giả/ý tưởng
  5) Đánh giá tính ứng dụng trong bối cảnh Việt Nam (20-35 tuổi, self-improvement)
  Trả lời bằng tiếng Việt.
  ```
- Query for structured insights:
  - "What are the 5 most important concepts in this book? For each, give the concept, a compelling story/example, and practical application."
  - "What are the most quotable lines from this book?"
  - "What stories or examples in this book are most dramatic and visually interesting?"
  - "What are the main criticisms or limitations of this book's arguments?"
- If any MCP tool fails, fall back: tell Hai to use NotebookLM web UI (notebooklm.google.com) and paste results manually.

### Step 5: Competitive analysis

Collaborative step — Claude cannot search YouTube directly:
- Ask Hai to search YouTube for existing Vietnamese videos about this book
- Or use WebSearch tool if available to find "[book title] tieng viet youtube"
- Note from results:
  - Which angles have been done (summary, review, criticism)
  - View counts and engagement
  - Gaps — what angles are MISSING

### Step 6: Structure notes

Follow the reference format:
```
# Notes: [Book Title] — [Author]
> **Source**: NotebookLM MCP ([N] sources)
> **Notebook ID**: [ID from step 4]
> **Extract date**: [Today's date]

## Vault Context
[Summary from Step 0 — what the vault already knows about this author/themes]
[Cross-book query results from Step 0b, if available]

## Key Insights (3-5)
### 1. [Insight title]
- **Concept**: ...
- **Story/Example**: ...
- **Application**: ...

## Quotes
> "..." (attributed)

## Stories / Examples (ranked by visual + dramatic potential)
### 1. [Story title]
- **Context**: ...
- **Details**: ...
- **Why it works for video**: ...

## Competitive Analysis
| Channel | Title | Views | Angle |
...

## Criticism & Counterarguments
- ...
```

### Step 7: Propose angles

Based on notes + competitive analysis + vault context, propose 3 ranked video angles. All Vietnamese output (working titles, hooks, key points) MUST use proper diacritics (co dau). Each angle:

- **Working title** (Vietnamese)
- **Hook** — opening sentence that creates curiosity in 3 seconds
- **Core message** — 1 sentence summary of what the video is about
- **2-3 key points** to cover
- **Why this angle works** — audience appeal + differentiation from existing videos
- **Recommended template** — which narrative template from `templates/narrative-templates.md` fits this angle (Contrarian Analysis, Hidden Connection, Meta-Pattern, Author Portrait, The Tension)

Prioritize angles that:
- Solve a specific pain point (not generic book summary)
- Have stories/examples that visualize well
- Are focused enough for 5-8 minutes
- Differentiate from existing YouTube VN coverage

**Vault-enabled angles**: After generating angles, cross-reference `templates/narrative-templates.md` and vault state:
- If vault has entries from other books on overlapping themes → highlight "Hidden Connection" option
- If vault has 3+ books on same theme → highlight "Meta-Pattern" option
- If vault has author profile with 2+ books → highlight "Author Portrait" option
- If vault has high-tension contradictions entry → highlight "The Tension" option
- Always note which templates are currently ACTIVATED by vault state

### Step 8: Decision point

Present 3 angles with template recommendations. Ask Hai to choose, modify, or suggest a different angle.

### Step 9: Write output

After angle selection, append "## Chosen Angle" section with the selected angle details + recommended template. Write to `projects/ai-book-video/books/$SLUG/notes.md`

### Step 10: Next step

Tell user to run `/create-storyboard $SLUG` (storyboard will use the recommended template as scaffold).

## Fallback

If NotebookLM MCP tools are unavailable or fail:
1. Tell Hai to create a notebook manually at notebooklm.google.com
2. Ask Hai to paste the raw notes/insights
3. Continue from step 6 (structuring) onward — the skill still handles analysis, angle proposal, and file writing
