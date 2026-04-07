---
name: write-metadata
description: "Generate YouTube and Facebook metadata for book video"
disable-model-invocation: false
argument-hint: "<book-slug>"
---

# Write Video Metadata

Generate YouTube and Facebook metadata for a Bookie book video.

## Context

- **When to use**: Video rendered (or about to render) — need title/description/tags for upload.
- **Input**: `chunks-display.md` (content, shorts candidates) + `storyboard.md` (scene structure) + `notes.md` (book info, angle)
- **Output**: `metadata.md` (YouTube + Facebook metadata)
- **Reference**: See `books/atomic-habits/metadata.md` for the standard format.

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided. If missing, ask Hai for the book slug (e.g., "atomic-habits"). Set `SLUG=$ARGUMENTS`. Check that `projects/ai-book-video/books/$SLUG/` exists.

2. **Read input files**:
   - Read `projects/ai-book-video/books/$SLUG/chunks-display.md` — extract sections, `[SHORT]` candidates
   - Read `projects/ai-book-video/books/$SLUG/storyboard.md` — extract scene structure, shorts markers
   - Read `projects/ai-book-video/books/$SLUG/notes.md` — extract book title, author, angle, key points
   - If either file is empty or just a template scaffold, abort and tell user which file to prepare first.

3. **Read reference**: Read `projects/ai-book-video/books/atomic-habits/metadata.md` to match the exact output format.

4. **Generate YouTube metadata**:

   **Title** (3 options):
   - Vietnamese, max 60 characters
   - All Vietnamese text MUST use proper diacritics (có dấu). Exception: hashtags/tags (no diacritics OK)
   - Curiosity-driven, clear benefit
   - No cheap clickbait
   - Book title must appear in the title

   **Description**:
   - Book/author credit line
   - 2-3 hook sentences (from HOOK section in chunks-display.md)
   - Scene labels from storyboard.md
   - Buy links (placeholder)
   - Social links: bookiecommunity.com | facebook.com/bookie.community
   - Hashtags at end of description

   **Tags** (15-20):
   - Mix: book title (VN + EN), author name, topic, "tom tat sach", "review sach", "doc sach", "self improvement", keywords VN + EN, "bookie"

5. **Generate Shorts metadata**:
   - For each `[SHORT]` candidate in chunks-display.md:
     - Short title (max 40 characters)
     - 5 hashtags
     - Full short description with hook text (30-60s standalone content)

6. **Generate Facebook metadata**:
   - Post caption: emoji formatting, numbered key points from chunks-display.md, CTA comment
   - Hashtags (Vietnamese + English mix, include #Bookie #BookieInspiresEveryone)

7. **Decision point**: Present the full draft (steps 4-6 produce a draft, NOT written to disk yet). Present 3 title options. Ask Hai to pick preferred title (or suggest revision).

8. **Write output**: After Hai approves, write complete metadata to `projects/ai-book-video/books/$SLUG/metadata.md`

## Important

- This skill runs after script is written. Prerequisites: `chunks-display.md`, `storyboard.md`, and `notes.md` with chosen angle.
- After metadata is done, next step: upload to YouTube/Facebook (manual).

## Format

Output must follow this structure (matching atomic-habits reference):

```
# Video Metadata: [Book Title] — [Angle/Subtitle]

## YouTube
### Title (pick one)
### Description
### Tags (N)
### Shorts
### Shorts Descriptions

## Facebook
### Post Caption
### Hashtags
```
