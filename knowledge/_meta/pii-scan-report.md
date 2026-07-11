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

## Recovery pass — 2026-07-11 (second commit)

All 17 truncated sources were re-processed:

| Outcome | Count | Detail |
|---|---|---|
| Recovered in full (re-read) | 9 | incl. the data-dense Bookie HR 2023 (19 full rows) and the 2017 Bookier responses (58 rows — original flag was a false positive) |
| Recovered in full (text export) | 2 | Proposal "Làm chủ nhịp sinh học", Công bố BT16 |
| Source itself unfinished (not truncation) | 4 | annotated "tài liệu gốc dở dang" in the knowledge files |
| Export complete but zero data rows | 1 | FEEDBACK FRIENDS 2024: CSV export returns only the 33-column header — either no responses were collected or data sits on a non-default tab (verify in Drive) |
| Still partially capped | 1 | Recap BT #19: two independent reads cut at the same point; content substantially improved, remainder documented |

Method note: binary xlsx export through the MCP layer proved unusable (base64 must transit the model → zip CRC corruption); text/plain and text/csv exports degrade gracefully and were verified against the overlap region of prior partial reads. Newly recovered content went through the same 3-layer scrub; an adversarial rescan of the 7 updated files produced 1 finding (quasi-identifier stack next to a masked host name — profession + hometown + birth year), fixed before commit. The name-sanitization map was consolidated to a single source of truth (59 entries) after one masked nickname briefly reappeared during merge.

## Known limitations

- Extraction summaries are lossy by design; 1 source (Recap BT #19) remains partially capped by the reader API — see recovery table above.
- The original Drive remains unsanitized (it's private); links in SOURCES.md lead back to raw docs containing PII — access controlled by Drive permissions, not this repo.
- ⚠ Security note (Drive-side, not in this repo): one operational sheet stores shared-account credentials in plaintext; flagged to the owner for rotation.
