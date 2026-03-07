---
name: extract-notes
description: >-
  Deep-research a book using NotebookLM as a multi-source hub (wiki, academic,
  YouTube, Vietnamese context, reader reviews) and propose differentiated video
  angles for Bookie. This is the FIRST step for any new book video — it must run
  before storyboard, script, or production. Use this skill whenever the user wants
  to research a book for video, build a NotebookLM research hub, find a video angle,
  do competitive analysis on YouTube/blogs, gather book insights across languages,
  or start the book video pipeline from scratch. Also use when comparing multiple
  books to choose which one to make a video about. Triggers: "extract notes",
  "research book", "new book video", "start pipeline", "analyze book for video",
  "choose angle", "find angle", "tìm angle", "research [book name]", "build hub",
  "competitive analysis", "gather insights", "cuốn tiếp theo", "bắt đầu research".
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

#### 3b. Enrich: 6 source categories

Systematically search and add sources across ALL 6 categories below. Use `WebSearch` to find URLs, then `source_add` (type=url) for each. Run searches in parallel where possible.

**Category 1 — Wikipedia & Encyclopedias** (target: 3-5 sources)
Search for and add:
- Wikipedia page for the book (English)
- Wikipedia page for the book (Vietnamese, if exists)
- Wikipedia page for the book (French/original language, if applicable)
- Wikipedia page for the author
- Britannica or other encyclopedia entry for the author

Search queries: `"[book title]" wikipedia`, `"[author]" wikipedia`, `"[book title Vietnamese]" wikipedia`

**Category 2 — Academic & Literary Criticism** (target: 2-4 sources)
Search for and add:
- Scholarly analysis from Cairn.info, OpenEdition, JSTOR, Google Scholar
- University press publications about the book/author
- University course materials or thesis excerpts
- Comparative literary analysis

Search queries: `"[author]" "[book title]" analysis literary criticism`, `"[author]" scholarly article`, `"[book title]" academic analysis comparison`

**Category 3 — Adaptations & Cultural Impact** (target: 1-3 sources)
Search for and add:
- Anime/film/TV adaptations (Wikipedia or fan wiki pages)
- Adaptation comparison articles
- Cultural impact articles

Search queries: `"[book title]" anime adaptation`, `"[book title]" film movie adaptation`, `"[book title]" cultural impact`

**Category 4 — Vietnamese Context** (target: 3-5 sources)
This is critical — Bookie's audience is Vietnamese 20-35. Search for and add:
- Vietnamese Wikipedia entry
- Vietnamese book review blogs (Bến Nghé Books, BILA, NhânVăn, etc.)
- Vietnamese educational analysis (Studocu, university sites, school sites)
- Vietnamese news articles about the book (Thanh Niên, ZNews, etc.)
- Vietnamese forum discussions (Tinhte, etc.)

Search queries: `"[Vietnamese book title]" review cảm nhận`, `"[Vietnamese book title]" phân tích giáo dục`, `"[Vietnamese book title]" diễn đàn`

**Category 5 — Reader Reviews & Discussions** (target: 2-4 sources)
Search for and add:
- Goodreads page (English)
- Goodreads page (Vietnamese edition, if separate)
- TV Tropes page (excellent for narrative structure analysis)
- Reddit discussions
- Blog reviews with substantive analysis

Search queries: `"[book title]" goodreads`, `"[book title]" reddit discussion`, `"[book title]" tv tropes`, `"[book title]" book review blog`

**Category 6 — Author Deep Dive** (target: 1-3 sources)
Search for and add:
- Dedicated author websites or fan sites
- Author biography articles
- Interviews or letters (if available)
- Other works by the same author (context for their evolution)

Search queries: `"[author]" biography website`, `"[author]" interview`, `"[author]" dedicated site fan`

**Category 7 — YouTube Analysis** (target: 3-6 sources)

YouTube analysis/review videos show how people *talk* about the book — which angles resonate, what the audience already knows, and what emotional beats land. NotebookLM accepts YouTube URLs directly as sources and extracts the transcript automatically, so these become fully cross-referenceable with the book text and academic sources.

Search in **multiple languages** — not just Vietnamese. An English video essay, a French literary analysis, or a Japanese anime discussion can surface angles that no Vietnamese creator has covered. Bookie can always adapt a foreign angle for Vietnamese audience. The goal is maximum data diversity.

WebFetch cannot access YouTube. Use `yt-dlp` (installed locally) for discovery and metadata.

**Search broadly across languages and content types:**
```bash
# Vietnamese — analysis, review, summary
yt-dlp "ytsearch5:[Vietnamese book title] phân tích review" --dump-json --flat-playlist 2>/dev/null | jq -r '[.title, .channel, .view_count, .duration, .id] | @tsv'

# English — essay, analysis, deep dive
yt-dlp "ytsearch5:[English book title] analysis essay" --dump-json --flat-playlist 2>/dev/null | jq -r '[.title, .channel, .view_count, .duration, .id] | @tsv'

# Original language (French, Japanese, etc.) — if applicable
yt-dlp "ytsearch5:[Original title] analyse critique" --dump-json --flat-playlist 2>/dev/null | jq -r '[.title, .channel, .view_count, .duration, .id] | @tsv'

# Author-focused — any language
yt-dlp "ytsearch5:[author name] book analysis" --dump-json --flat-playlist 2>/dev/null | jq -r '[.title, .channel, .view_count, .duration, .id] | @tsv'
```

Vary search terms across runs: `analysis`, `essay`, `deep dive`, `explained`, `review`, `comparison`, `phân tích`, `cảm nhận`, `tóm tắt`. Combine all results, deduplicate by video ID, rank by view count.

**Add top videos to NotebookLM** via `source_add(source_type=url, url="https://youtube.com/watch?v=VIDEO_ID")`. Prioritize:
- Analytical depth over surface-level plot summaries (analysis gives NotebookLM richer cross-reference material)
- Unique angles — especially foreign-language videos with perspectives absent from Vietnamese content
- Higher view count (indicates the angle resonated with audience)
- Diversity of perspectives — mix Vietnamese, English, and original-language sources when available

Save the full yt-dlp search metadata — you'll reuse it in Step 4 for competitive analysis.

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

Now that the hub has rich context, query for structured insights. These queries benefit from ALL sources — not just the book text.

First, detect the book configuration and run the matching query set:

**Base queries (always run):**
- "What are the 5 most important concepts? For each, give the concept, a compelling story/example, and practical application."
- "What are the most quotable lines? Include exact quotes with context."
- "What stories or examples are most dramatic and visually interesting? Describe in detail."
- "What are the main criticisms or limitations? Use evidence from all sources."
- "What do Vietnamese readers and reviewers say? What resonates most with Vietnamese audiences?"
- "How has this been adapted (anime, film, etc.)? How do adaptations differ from the original?"

**Twin/multi-book same author — add these queries:**
- "Compare [Book A] vs [Book B] in detail: character journeys, themes, tone, structure. What's symmetric? What's opposite?"
- "How did the author's thinking evolve between the books? What changed in their worldview, and why?"
- "What does reading both books together reveal that reading either one alone doesn't?"

**Multi-book different authors — add these queries:**
- "Where do these authors fundamentally agree? Where do they contradict each other?"
- "What does NONE of these books address? What's the blind spot they all share?"
- "If these authors debated each other, what would the core disagreement be?"

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

Follow the reference format. The notes should reflect the depth of the research hub — not just book text, but academic insights, author bio, Vietnamese context, and adaptations.

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
> "..." — [speaker/context]

## Stories / Examples (ranked by visual + dramatic potential)
### 1. [Story title]
- **Context**: ...
- **Details**: ...
- **Visual**: [why it works for video illustration]

## Competitive Analysis
| Channel | Title | Views | Angle |
...
**Keywords gap**: [untapped search terms]

## Author Bio
- Key biographical facts sourced from wiki + academic sources
- Personal connection to the work (why they wrote it)
- Influences, literary relationships
- Vietnamese cultural relevance

## Academic Insights
- Scholarly perspectives not obvious from just reading the book
- Literary criticism positions
- Comparative analysis with other works

## Adaptations
- Anime, film, TV adaptations (if any)
- How adaptations changed the source material
- Adaptation popularity in different markets

## Vietnamese Reception
- How Vietnamese readers receive this book
- Educational context (school curriculum, if applicable)
- Vietnamese-specific resonance points

## Criticism & Counterarguments
- ...
```

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
