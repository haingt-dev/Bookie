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

## Operational data (outside this repo)

The event-automation system (`shared/event-automation/`) runs a **member registry** — a Google Sheet (`Bookie Registry 2026`, 6 tabs: `Events`, `Subscribers`, `Bookiers`, `Attendance`, `Feedback`, `People`) holding member/subscriber/attendee PII (name, email, phone, registration + attendance status). An auxiliary `Quarantine` tab holds subscribe payloads that hit the rate cap. It lives entirely on Google Drive under the **bookie.community@gmail.com** account.

`People` is a **derived golden record**: latest name/phone/attendance history per email, rebuilt from the other tabs — not a primary source. `Feedback` is **anonymous-by-design** per event; it carries only 2 optional PII fields a respondent may fill in themselves (`ten_tuy_chon`, `email_tuy_chon`).

- **Never committed to this repo.** No individual row, name, email, or phone from the registry is ever written to any file under `knowledge/` or `projects/`.
- **Never on the public website.** The Astro site renders only from `event.json` (event metadata + aggregate numbers, per the "Allowed" section above) committed in-repo — it never fetches from the Sheet. This is a hard architectural boundary, not just a convention: the site build has no code path that reads Sheet data.
- **Who can read it**: the Bookie admin team, via direct Sheet share on the bookie.community@gmail.com Drive — same access model as the rest of `knowledge/`'s Drive source.
- **Retention & deletion-on-request**:
  - Unsubscribe does **not** delete a person's row — it flips `Subscribers` status to `unsubscribed`, which doubles as a suppression entry (must be kept so the system doesn't re-mail that address).
  - A hard deletion request must run in this order: **(1) delete the original response in each Google Form involved first** — Forms are the system of record, and if a form response isn't deleted, the next sync tick recreates the corresponding Sheet row; **(2) then delete the matching rows** from `People`, `Subscribers`, `Bookiers`, `Attendance`, and `Feedback` (where `email_tuy_chon` matches), including the suppression entry — meaning a deleted person could re-enter via a future form response. Procedure documented in `shared/event-automation/REGISTRY.md`'s operator runbook.

See `../../ARCHITECTURE.md` (PII line) and `shared/event-automation/REGISTRY.md` (registry schema + runbook) for the full design.
