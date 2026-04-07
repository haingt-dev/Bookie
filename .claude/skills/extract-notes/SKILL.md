---
name: extract-notes
description: "Deep-research a book and propose video angles"
disable-model-invocation: false
argument-hint: "<book-slug>"
---

# Extract Book Notes

Research a book deeply using NotebookLM as a center hub, then propose video angles for selection.

The NotebookLM notebook is the **research center hub** for each author — not a book dump. Every book gets surrounded by wiki, academic criticism, adaptations, Vietnamese context, reader discussions, and competitive landscape. The richer the hub, the sharper the angles.

## Context

- **When to use**: New book ready — need to extract insights and choose video angle.
- **Input**: Book slug + primary sources (text, URL, or file)
- **Output**: `notes.md` (structured notes + chosen angle)
- **Reference**: See `projects/ai-book-video/books/atomic-habits/notes.md` for the standard format.
- **MCP tools**: NotebookLM MCP (`notebook_create`, `source_add`, `notebook_query`, `chat_configure`)

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

### Step 3: Build Research Center Hub

This is the most important step. The NotebookLM notebook becomes a research hub that enables deep cross-referencing between the book, its author, scholarly analysis, cultural context, and audience reception.

#### 3a. Create notebook + add primary book text

- `notebook_create` with name "Bookie: [Author Name]" (per-author convention — multiple books by same author share 1 notebook)
- If author already has a notebook from a previous book, use that notebook instead of creating a new one
- Check `projects/ai-book-video/books/$SLUG/` for existing text files (`.txt`, `.pdf`, `.md`). If found, `source_add` (type=file) for each — no need to ask Hai.
- If no text files found in the folder, ask Hai: "Book text chưa có trong folder. Cung cấp file path, URL, hoặc paste text?"

#### 3b. Enrich: 7 source categories

Systematically search and add sources across all categories. Run searches in parallel where possible.

Read `references/search-categories.md` for Categories 1-6 (Wikipedia, Academic, Adaptations, Vietnamese Context, Reader Reviews, Author Deep Dive) with search queries and targets per category.

Read `references/youtube-search-patterns.md` for Category 7 (YouTube Analysis) with yt-dlp commands and selection criteria. Save the yt-dlp search metadata — reused in Step 4 for competitive analysis.

#### 3c. Verify hub completeness

After enrichment, verify:
- **Minimum 15 total sources** (primary + reference). If under 15, search harder.
- **At least 5 of 7 categories** have sources. If a category is empty, do one more targeted search.
- **Vietnamese sources present** — this is non-negotiable for Bookie's audience.
- **YouTube sources present** — at least 1 YouTube video added. If no analysis videos exist for this book, note that as a competitive gap.

Report the hub status to Hai: "Notebook has N sources across K categories: [breakdown]."

#### 3d. Configure chat lens

Configure chat with Bookie analytical lens via `chat_configure`:
```
Bạn là trợ lý nghiên cứu sách cho kênh Bookie (Việt Nam). Khi phân tích:
1) Tìm mâu thuẫn với các cuốn sách đã thêm trước đó
2) Phát hiện thiên lệch văn hóa (Western vs Vietnamese)
3) Tìm patterns xuyên suốt nhiều nguồn
4) Gợi ý kết nối bất ngờ giữa các tác giả/ý tưởng
5) Đánh giá tính ứng dụng trong bối cảnh Việt Nam (20-35 tuổi, self-improvement)
Trả lời bằng tiếng Việt.
```

#### 3e. Deep queries

Now that the hub has rich context, query for structured insights. Read `references/notebooklm-queries.md` for the base query set and conditional multi-book queries. Detect the book configuration (single book, twin/multi-book same author, multi-book different authors) and run the matching query set.

If any MCP tool fails, fall back: tell Hai to use NotebookLM web UI (notebooklm.google.com) and paste results manually.

### Step 4: Competitive analysis

Two sources: yt-dlp for YouTube landscape, WebSearch for non-YouTube (blogs, podcasts, courses).

#### 4a. YouTube landscape (yt-dlp)

Reuse the yt-dlp search metadata from Category 7 (Step 3b). If you need broader coverage, run additional searches:

```bash
# Broader search — top 10 results
yt-dlp "ytsearch10:[Vietnamese book title] phân tích review tóm tắt" --dump-json --flat-playlist 2>/dev/null | jq -r '[.title, .channel, .view_count, .duration, .id] | @tsv'
```

If multi-book video: also search for comparison content (`[book A] vs [book B]`, `[author] hai cuốn`).

From the results, note:
- Which angles have been done (summary, review, criticism, comparison)
- View counts and engagement (actual numbers from yt-dlp — not estimates)
- Top channels covering this book/genre
- Gaps — what angles are MISSING
- Whether anyone has done a similar multi-book or author portrait angle

#### 4b. Non-YouTube competition (WebSearch)

Search multilingual — same principle as YouTube. Foreign blog posts, English literary essays, and original-language criticism can reveal angles absent from Vietnamese content.

Use `WebSearch` across languages:

**Vietnamese:**
1. `"[Vietnamese book title]" review phân tích blog`
2. `"[Vietnamese book title]" podcast cảm nhận`

**English:**
3. `"[English book title]" analysis essay blog`
4. `"[author]" "[English book title]" literary criticism`

**Original language (if applicable):**
5. `"[Original title]" analyse critique blog`

Note angles and depth — written content often goes deeper than YouTube summaries. Foreign-language articles with unique angles are especially valuable as potential Bookie adaptations.

### Step 5: Structure notes

Read `references/notes-template.md` for the full output format. The notes should reflect the depth of the research hub — not just book text, but academic insights, author bio, Vietnamese context, and adaptations. See `projects/ai-book-video/books/atomic-habits/notes.md` as a reference example.

### Step 6: Propose angles

Based on notes + competitive analysis + vault context, propose 3 ranked video angles. All Vietnamese output (working titles, hooks, key points) MUST use proper diacritics (có dấu). Each angle:

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

### Step 7: Decision point

Present 3 angles with template recommendations. Ask Hai to choose, modify, or suggest a different angle.

### Step 8: Write output

After angle selection, append "## Chosen Angle" section with the selected angle details + recommended template. Write to `projects/ai-book-video/books/$SLUG/notes.md`

### Step 9: Next step

Tell user to run `/create-storyboard $SLUG` (storyboard will use the recommended template as scaffold).

## Fallback

If NotebookLM MCP tools are unavailable or fail:
1. Tell Hai to create a notebook manually at notebooklm.google.com
2. Ask Hai to paste the raw notes/insights
3. Continue from step 6 (structuring) onward — the skill still handles analysis, angle proposal, and file writing
