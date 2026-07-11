# PII Scan Report — 2026-07-11

Point-in-time verification that the knowledge base is PII-clean before its first commit. Counts only — no raw PII reproduced here.

## Pipeline coverage (reconciliation)

| Metric | Count |
|---|---|
| Drive nodes inventoried | 2,417 |
| Folders crawled | 216 / 216 discovered (0 errors) |
| Readable docs extracted | 335 / 335 (334 docs + 1 draw.io diagram, 0 failures) |
| — of which truncated (very large sheets, partial content) | 17 (flagged `truncated` in inventory + ⚠ in knowledge files) |
| Google Forms (metadata-only, content not readable via API) | 82 |
| Shortcuts recorded | 10 |
| Media files skipped (never read/downloaded) | 1,774 |
| Knowledge files synthesized | 24 + 3 inventory docs + README |

## PII scrub layers

1. **Extraction-time** (335 docs): every extraction agent stripped PII while summarizing; per-doc "Ghi chú PII" records what was removed.
2. **Name-map sanitization** of Drive file/folder *names* across inventory, tree, SOURCES and all knowledge files: 27 map entries + 11 person-named media files (Gala certificates, testimonial photos) masked to role labels.
3. **Adversarial model scan**: 27 files each audited by an independent agent instructed to over-flag → **48 findings**, all adjudicated and fixed:
   - Internal member/CTV names in source filenames → `[CTV-xx]` / `[Ứng viên BCN xx]` labels (33 findings)
   - Internal BD host names + personal details (birth year, hometown) in history tables → `[Host — ẩn tên]` labels (12)
   - Google account ID (`ouid=` URL parameter) present in every Drive link → stripped from all URLs (1)
   - Name-fragment example from HR sheet + advisory-outreach target name → genericized (2)
4. **Final regex sweep** (VN phones, emails, 9+ digit runs, personal FB/Zalo links, residual names): **0 unresolved hits**. Remaining emails are organizational only (`bookie.community@gmail.com`, `npo@linvn.org`, `raceforknowledge2023@gmail.com`).

## Whitelisted (kept by policy)

- "Hải"/"Hai" — founder, repo owner (incl. his own 2016 BCN application file)
- External speakers publicly credited in event marketing (e.g. Nguyễn Hải Minh — Wisdom Agency)
- Partner organization names + org-level contacts
- Book authors and public figures as subjects of events

## Known limitations

- Extraction summaries are lossy by design; 17 sources were truncated by the reader API — refresh may recover more.
- The original Drive remains unsanitized (it's private); links in SOURCES.md lead back to raw docs containing PII — access controlled by Drive permissions, not this repo.
- ⚠ Security note (Drive-side, not in this repo): one operational sheet stores shared-account credentials in plaintext; flagged to the owner for rotation.
