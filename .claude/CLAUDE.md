# Claude Code — Bookie

@~/.claude/brains/indie-ecosystem.md

## About

**Book!e Inspires Everyone** — A reading community that inspires reading and learning.

- Website: bookiecommunity.com
- Fanpage: facebook.com/bookie.community

## Project Structure

The organization's knowledge home + workspace for sub-projects. Not a codebase — holds knowledge, assets, scripts, and configs.

```
Bookie/
├── ARCHITECTURE.md     <- spine of the event operating system: data/automation/content/view layers, decision log, risk register
├── knowledge/          <- org knowledge base (from Drive; Vietnamese; PII-scrubbed — repo is PUBLIC)
│   ├── 00-inventory/   <- Drive tree snapshot + inventory.json (links back to sources)
│   ├── 01..08-*/       <- history, org structure, playbooks, plans, minutes, brand, partners
│   └── _meta/          <- PII policy, sources map, scan report (English)
├── projects/           <- sub-projects (each gets a folder; 2 structure variants, see below)
│   ├── ai-book-video/  <- AI book-video pipeline (Paused)
│   ├── bd-2026/        <- event-type sub-project (BD event kit, Incubating)
│   └── bt-2026/        <- event-type sub-project (BT revival w/ guest host group, Incubating)
├── site/               <- public website (Astro; spec in site/SPEC.md, code builds at slice S6)
└── shared/             <- shared resources
    ├── branding/       <- logo, brand assets
    ├── design-system/  <- event graphics: brand tokens + HTML/CSS templates + render.mjs (see its README)
    ├── event-automation/ <- registration form + QR automation: Apps Script endpoint + create-form.mjs (see its README)
    └── templates/      <- reusable templates
```

**Knowledge base rule**: anything committed under `knowledge/` must stay PII-clean (no member names/contacts/individual payments — see `knowledge/_meta/PII-POLICY.md`). It is a dated snapshot (crawled 2026-07-11); refresh = re-crawl Drive and diff against `00-inventory/inventory.json`. Docs recorded outside the Drive snapshot are allowed only with an explicit provenance note (e.g. `06-thuong-hieu-media/website.md`).

### Sub-project Conventions

Two structure variants, chosen by project type:

- **Standard** (default, `/new-subproject <name>`) — production/pipeline projects:
  `assets/` · `scripts/` · `output/`
- **Event-type** (`/new-subproject <name> --event`) — community event/program projects (BD, BT, Gala, Meetup…):
  - `plan/` <- Operation: timeline checklist, roles, proposal, feedback spec
  - `content/` <- Host/MC: agenda/rundown, discussion questions, evaluation
  - `comms/` <- MarCom: email + social post templates
  - `assets/` · `output/` <- same meaning as standard

Event-kit content is distilled from the matching `knowledge/03-playbook/<program>.md`; `projects/bd-2026/` is the reference implementation. Promote a generic template into `shared/templates/` only once a second event-type project needs one — not before.

- Event graphics (poster/cover) come from `shared/design-system/` via `/event-graphics` — per-event data only, never hand-design per event
- Registration form + QR come from `shared/event-automation/` via `/event-form` — clones the canonical template form on the bookie account (Apps Script), never hand-clone forms per event. Per-event form content is written only from event.json
- Each sub-project has its own README.md with a Status field: `Incubating | Active | Paused | Archived`
- Large media files tracked with Git LFS (video, PSD, audio, etc.)
- Final output goes in `output/`, don't commit output to git unless necessary
- When pipeline logic changes, update WORKFLOW.md (or equivalent) to stay in sync

## Language
- **All project output in Vietnamese**: scripts, content, copy, descriptions, comments in output files
- Config files stay English (instructions to Claude)

## Boundaries
- Resource hub only — no app code, no backend/frontend infra setup here
- Org notes live in this repo (opened as an Obsidian vault; `.obsidian/` is gitignored). Repo is PUBLIC → notes must be born PII-clean. Notes about PEOPLE (interviews, personal assessments) belong in the private Idea_Vault second brain
- `event.json` is public data by definition — keep personal data out of it (no phone numbers, no private contacts). Operational personal data (registry) lives only in Google Drive — see `ARCHITECTURE.md`
