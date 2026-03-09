# Claude Code — Bookie

## About

**Book!e Inspires Everyone** — A reading community that inspires reading and learning.

- Website: bookiecommunity.com
- Fanpage: facebook.com/bookie.community

## Project Structure

Resource hub for multiple sub-projects. Not a codebase — primarily holds assets, scripts, and configs.

```
Bookie/
├── projects/           <- sub-projects (each gets a folder)
│   └── <name>/
│       ├── assets/     <- media resources
│       ├── scripts/    <- scripts, prompts
│       └── output/     <- final output
├── shared/             <- shared resources
│   ├── branding/       <- logo, brand assets
│   └── templates/      <- reusable templates
└── .memory-bank/       <- project knowledge
```

### Sub-project Conventions

- Each sub-project lives in `projects/<name>/`
- New sub-projects follow the structure above
- Large media files tracked with Git LFS (video, PSD, audio, etc.)
- Final output goes in `output/`, don't commit output to git unless necessary
- When pipeline logic changes, update WORKFLOW.md and `.memory-bank/` (architecture, context, task) to stay in sync

## Project Values
- **Minimal impact** — Make the smallest changes necessary. Don't over-engineer
- **No dirty state** — Don't leave the environment broken. Verify changes work before completing a task
- **Reversibility** — Ensure significant changes can be undone if needed

### Language
- **All project output in Vietnamese**: scripts, content, copy, descriptions, comments in output files
- Config files stay English (instructions to Claude)

### Boundaries
- This project is a resource hub, not application code
- No backend/frontend infrastructure setup
- Detailed project notes live in Obsidian Idea_Vault, don't duplicate here

## Memory Bank
Auto-loaded at session start. Full files in `.memory-bank/`:

- `brief.md` — Project goals, scope, and constraints
- `context.md` — Current focus and next actions
- `architecture.md` — Pipeline diagrams and key principles
- `tech.md` — Tech stack and runtime gotchas
- `task.md` — Pipeline status per book

After major tasks or architectural changes, update relevant Memory Bank files.

## Security
**CRITICAL**: NEVER commit, push, or expose secrets, API keys, tokens, or credentials to version control.

- NEVER hardcode secrets in code — use environment variables and `.env` files
- NEVER commit files containing secrets — verify with `git diff --cached` before committing
- ALWAYS check `.gitignore` has `.env*`, `credentials.*`, `secrets.*`, `*.key`, `*.pem`
- ASK before committing sensitive-looking files (`config.json`, `.env*`, `credentials.*`)
- If secrets are accidentally committed: STOP, alert user to revoke, remove from history, add to `.gitignore`
