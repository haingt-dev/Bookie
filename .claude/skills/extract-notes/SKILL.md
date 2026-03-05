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

- **Khi nao dung**: Co sach moi, can extract insights va chon angle cho video.
- **Input**: Book sources (text, URL, or file to add to NotebookLM)
- **Output**: `notes.md` (structured notes + chosen angle)
- **Reference**: Xem `projects/ai-book-video/books/atomic-habits/notes.md` de nam format chuan.
- **MCP tools**: NotebookLM MCP (`notebook_create`, `source_add`, `notebook_query`, `notebook_describe`)

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided. If missing, ask Hai for the book slug (e.g., "atomic-habits"). Set `SLUG=$ARGUMENTS`. Check that `projects/ai-book-video/books/$SLUG/` exists.

2. **Check existing notes**: Read `projects/ai-book-video/books/$SLUG/notes.md`. If it already has content beyond the scaffold template, warn and ask Hai before overwriting.

3. **Gather sources**: Ask Hai for book sources to add. Options:
   - URL(s) — author website, Wikipedia, book summary pages
   - Text — pasted book excerpts or summaries
   - File — local file path to book text
   - Existing NotebookLM notebook ID (if already created manually)

4. **NotebookLM extraction** (using MCP tools):
   - Create a new notebook: `notebook_create` with name "[Book Title] — Bookie Research"
   - Add sources: `source_add` for each URL/text/file
   - Query for structured insights:
     - "What are the 5 most important concepts in this book? For each, give the concept, a compelling story/example, and practical application."
     - "What are the most quotable lines from this book?"
     - "What stories or examples in this book are most dramatic and visually interesting?"
     - "What are the main criticisms or limitations of this book's arguments?"
   - If any MCP tool fails, fall back: tell Hai to use NotebookLM web UI (notebooklm.google.com) and paste results manually.

5. **Competitive analysis** (collaborative step — Claude cannot search YouTube directly):
   - Ask Hai to search YouTube for existing Vietnamese videos about this book
   - Or use WebSearch tool if available to find "[book title] tieng viet youtube"
   - Note from results:
     - Which angles have been done (summary, review, criticism)
     - View counts and engagement
     - Gaps — what angles are MISSING

6. **Structure notes** following the reference format:
   ```
   # Notes: [Book Title] — [Author]
   > **Source**: NotebookLM MCP ([N] sources)
   > **Notebook ID**: [ID from step 4]
   > **Ngay extract**: [Today's date]

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

7. **Propose angles**: Based on notes + competitive analysis, propose 3 ranked video angles. Each angle:
   - **Working title** (Vietnamese)
   - **Hook** — opening sentence that creates curiosity in 3 seconds
   - **Core message** — 1 sentence summary of what the video is about
   - **2-3 key points** to cover
   - **Why this angle works** — audience appeal + differentiation from existing videos

   Prioritize angles that:
   - Solve a specific pain point (not generic book summary)
   - Have stories/examples that visualize well
   - Are focused enough for 5-8 minutes
   - Differentiate from existing YouTube VN coverage

8. **Decision point**: Present 3 angles. Ask Hai to choose, modify, or suggest a different angle.

9. **Write output**: After angle selection, append "## Angle da chon" section with the selected angle details. Write to `projects/ai-book-video/books/$SLUG/notes.md`

10. **Next step**: Tell user to run `/write-script $SLUG`

## Fallback

If NotebookLM MCP tools are unavailable or fail:
1. Tell Hai to create a notebook manually at notebooklm.google.com
2. Ask Hai to paste the raw notes/insights
3. Continue from step 6 (structuring) onward — the skill still handles analysis, angle proposal, and file writing
