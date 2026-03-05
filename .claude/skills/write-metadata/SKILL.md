---
name: write-metadata
description: >-
  Generate YouTube and Facebook metadata (title, description, tags, shorts,
  Facebook caption) for a Bookie book video. Use when the user wants to
  write metadata, prepare upload info, or generate titles/tags for a video.
  Triggers: "write metadata", "metadata cho [book]", "YouTube title",
  "generate tags", "Facebook post", "prepare upload".
argument-hint: "<book-slug>"
---

# Write Video Metadata

Generate YouTube and Facebook metadata for a Bookie book video.

## Context

- **Khi nao dung**: Video da render (hoac sap render), can viet title/description/tags de upload.
- **Input**: `script.md` (content, timestamps, shorts candidates) + `notes.md` (book info, angle)
- **Output**: `metadata.md` (YouTube + Facebook metadata)
- **Reference**: Xem `books/atomic-habits/metadata.md` de nam format chuan.

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided. If missing, ask Hai for the book slug (e.g., "atomic-habits"). Set `SLUG=$ARGUMENTS`. Check that `projects/ai-book-video/books/$SLUG/` exists.

2. **Read input files**:
   - Read `projects/ai-book-video/books/$SLUG/script.md` — extract sections, timestamps, `[SHORT]` candidates
   - Read `projects/ai-book-video/books/$SLUG/notes.md` — extract book title, author, angle, key points
   - If either file is empty or just a template scaffold, abort and tell user which file to prepare first.

3. **Read reference**: Read `projects/ai-book-video/books/atomic-habits/metadata.md` to match the exact output format.

4. **Generate YouTube metadata**:

   **Title** (3 options):
   - Tieng Viet, toi da 60 ky tu
   - Gay to mo, co benefit ro rang
   - Khong clickbait re tien
   - Ten sach phai xuat hien trong title

   **Description**:
   - Book/author credit line
   - 2-3 cau hook (tu script HOOK section)
   - Timestamps tu script section headers
   - Buy links (placeholder)
   - Social links: bookiecommunity.com | facebook.com/bookie.community
   - Hashtags cuoi description

   **Tags** (15-20):
   - Mix: ten sach (VN + EN), ten tac gia, chu de, "tom tat sach", "review sach", "doc sach", "self improvement", keywords VN + EN, "bookie"

5. **Generate Shorts metadata**:
   - For each `[SHORT]` candidate in script.md:
     - Title ngan (max 40 ky tu)
     - 5 hashtags
     - Full short description with hook text (30-60s standalone content)

6. **Generate Facebook metadata**:
   - Post caption: emoji formatting, numbered key points from script, CTA comment
   - Hashtags (Vietnamese + English mix, include #Bookie #BookieInspiresEveryone)

7. **Decision point**: Present the full draft (steps 4-6 produce a draft, NOT written to disk yet). Present 3 title options. Ask Hai to pick preferred title (or suggest revision).

8. **Write output**: After Hai approves, write complete metadata to `projects/ai-book-video/books/$SLUG/metadata.md`

## Important

- This skill runs after script is written. Prerequisites: `script.md` and `notes.md` with chosen angle.
- After metadata is done, next step: upload to YouTube/Facebook (manual).

## Format

Output must follow this structure (matching atomic-habits reference):

```
# Video Metadata: [Book Title] — [Angle/Subtitle]

## YouTube
### Title (chon 1)
### Description
### Tags (N)
### Shorts
### Shorts Descriptions

## Facebook
### Post Caption
### Hashtags
```
