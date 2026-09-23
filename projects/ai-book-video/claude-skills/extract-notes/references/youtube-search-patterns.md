# YouTube Analysis — Category 7 (target: 3-6 sources)

YouTube analysis/review videos show how people *talk* about the book — which angles resonate, what the audience already knows, and what emotional beats land. NotebookLM accepts YouTube URLs directly as sources and extracts the transcript automatically, so these become fully cross-referenceable with the book text and academic sources.

Search in **multiple languages** — not just Vietnamese. An English video essay, a French literary analysis, or a Japanese anime discussion can surface angles that no Vietnamese creator has covered. Bookie can always adapt a foreign angle for Vietnamese audience. The goal is maximum data diversity.

WebFetch cannot access YouTube. Use `yt-dlp` (installed locally) for discovery and metadata.

## Search commands

Search broadly across languages and content types:

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

## Adding to NotebookLM

Add top videos via `source_add(source_type=url, url="https://youtube.com/watch?v=VIDEO_ID")`. Prioritize:
- Analytical depth over surface-level plot summaries (analysis gives NotebookLM richer cross-reference material)
- Unique angles — especially foreign-language videos with perspectives absent from Vietnamese content
- Higher view count (indicates the angle resonated with audience)
- Diversity of perspectives — mix Vietnamese, English, and original-language sources when available

Save the full yt-dlp search metadata — you'll reuse it in Step 4 for competitive analysis.
