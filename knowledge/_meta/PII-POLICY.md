# PII Policy — Bookie Knowledge Base

This knowledge base lives in a **public** GitHub repo. All content synthesized from Bookie's Google Drive was scrubbed under these rules before commit.

## Never committed
- Full names of ordinary members, collaborators (CTV), applicants, or attendees
- Phone numbers, emails, home addresses, student/citizen IDs, birth dates
- Personal Facebook/Zalo profile links, bank account numbers
- Individual payment records (who paid/owes what)
- Individual form responses tied to an identity
- Internal assignment/feedback docs naming people → replaced by **role** ("trưởng ban MarCom", "thành viên Op")

## Allowed
- Aggregate numbers ("32 thành viên đặt áo CLB 2017", "38 người đăng ký")
- Names of **publicly announced** event hosts/speakers (already published on Bookie's public Facebook page as part of event marketing)
- Founders in official docs
- Partner **organization** names (A&M, Beli Coffee, VOH…) — individual partner contacts are PII
- Book titles/authors, program names, dates, venues

## Whitelist (public figures in this context)
- Hải (founder, owner of this repo)
- Event hosts/speakers named in public event announcements (e.g. host of BD "A Way Of Being")

## Where sanitization was applied
1. **Extraction time**: every extraction agent stripped PII while summarizing (per-doc "Ghi chú PII" records what was removed).
2. **Synthesis time**: synthesis agents replace any leaked names with roles.
3. **Inventory names**: Drive file/folder *names* containing person names were masked in `00-inventory/inventory.json`, `cay-thu-muc-drive.md` and `_meta/SOURCES.md` (e.g. `[CTV-01]`, `[Ứng viên BCN 05]`). The mapping back to real names exists only in Drive itself — follow the `viewUrl` links (requires Drive access).
4. **Final scan**: regex scan (VN phone / email / long digit runs / personal social links) + a model-based person-name review over every committed file; findings fixed before commit. Report: `pii-scan-report.md`.

## Raw data
Raw extractions and crawl listings never entered the repo tree (kept in an ephemeral job scratchpad, auto-cleaned). The knowledge base is a **point-in-time snapshot**: crawled **2026-07-11**.
