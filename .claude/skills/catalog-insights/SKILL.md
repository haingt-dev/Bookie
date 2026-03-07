---
name: catalog-insights
description: >-
  Catalog knowledge from a completed book video into the persistent knowledge base.
  Extracts concepts, author positions, cross-references, and production metadata.
  Runs after video production, before publish. Use when the user wants to catalog
  insights, update the knowledge vault, or save learnings from a completed video.
  Triggers: "catalog insights", "catalog [book]", "update vault",
  "add to vault", "save insights for [book]".
argument-hint: "<book-slug>"
---

# Catalog Insights

Extract knowledge from a completed book video and persist it in the Knowledge Vault for cross-book intelligence.

## Context

- **When to use**: After video production is complete (voice, images, render done). Before publish.
- **Input**: `books/<slug>/notes.md` + `books/<slug>/storyboard.md`
- **Output**: Updates to `knowledge-base/` files (append-only) + source added to Master notebook
- **Pipeline position**: After `/write-metadata`, before publish. Also integrated into `/produce-video` Phase 6.5.

## Pipeline Position

```text
/produce-video or manual pipeline
    ↓
/write-metadata → metadata.md
    ↓
/catalog-insights → knowledge-base/ updates  ← YOU ARE HERE
    ↓
Publish (Manual)
```

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided. If missing, ask Hai for the book slug. Set `SLUG=$ARGUMENTS`. Verify `projects/ai-book-video/books/$SLUG/notes.md` exists.

2. **Read inputs**:
   - Read `projects/ai-book-video/books/$SLUG/notes.md` — key insights, author, angle, criticism
   - Read `projects/ai-book-video/books/$SLUG/storyboard.md` — scene structure, template used, emotional arc
   - Extract: book title, author name, chosen angle, key concepts, blind spots, cross-references

3. **Check duplicates**: Read `projects/ai-book-video/knowledge-base/library.md`. If this book slug already exists in the table, warn Hai and ask whether to update existing entries or skip.

4. **Extract concepts**: For each key insight/concept from notes.md:
   - List existing theme files: `Glob` for `knowledge-base/concepts/*.md`
   - Determine which theme each concept fits (habits, identity, productivity, focus, etc.)
   - If concept fits existing theme: append a new `###` entry to that file
   - If concept needs a new theme: propose theme name to Hai via `AskUserQuestion`, then create new file
   - Each entry follows the format:
     ```markdown
     ### [Concept name]
     - **Source**: [Book Title] ([Author])
     - **Position**: [Author's claim/argument]
     - **Nuance**: [Criticism, limitation, or deeper insight from Bookie research]
     - **Cross-ref**: → connections/[type].md #[anchor] (if applicable)
     ```

5. **Extract author profile**:
   - Check if `knowledge-base/authors/<author-slug>.md` exists
   - If exists: append new book's data under a new `## Books Covered` entry + update blind spots
   - If not: create author file with: Background, Core Thesis, Strengths, Blind Spots, Books Covered, Cross-references, NotebookLM info

6. **Identify connections**: Read ALL existing `knowledge-base/concepts/` files. For entries from OTHER books on overlapping themes:
   - If positions contradict: append entry to `knowledge-base/connections/contradictions.md`
   - If positions agree/reinforce: append to `knowledge-base/connections/agreements.md`
   - If one extends/evolves another: append to `knowledge-base/connections/evolutions.md`
   - Each connection entry includes: Position A, Position B, Tension/Common ground, Discovered in

7. **Record production metadata**: Append row to `knowledge-base/production.md`:
   ```
   | [Book] | [Template] | [Duration] | [Scenes] | [Hook line] | [Date] |
   ```

8. **Update library index**: Append row to `knowledge-base/library.md`:
   ```
   | [Book] | [Author] | [Angle] | [Template] | [Date] | [Slug] |
   ```

9. **Add to Master notebook**:
   - Find "Bookie: Library" notebook via `notebook_list`
   - Add `books/$SLUG/notes.md` as text source via `source_add`
   - If NotebookLM fails: log warning but continue — local files are source of truth

10. **Report**: Summarize what was cataloged:
    - Concepts added (which themes, how many entries)
    - Author profile created/updated
    - New connections discovered (this is the exciting part!)
    - Production metadata recorded
    - Master notebook updated (yes/no)
    - Suggest: "Next time you research a book on [overlapping theme], the vault will surface these connections automatically."

## Important

- All concept/connection content in Vietnamese (matching notes.md language)
- Append-only operations — never delete or overwrite existing vault entries
- Cross-references use `→` arrow syntax with file path + anchor
- Theme files are indexed by THEME, not by book — one book may contribute to multiple themes
- When in doubt about theme classification, ask Hai
- The Knowledge Vault is the long-term competitive moat — quality of entries matters more than speed
