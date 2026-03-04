# Workspace Rules

> Full project context: see AGENTS.md
> Soul & identity: see ~/.gemini/GEMINI.md

## Commit Protocol
`<type>(<scope>): <description>`

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, white-space |
| `refactor` | Code change (no fix/feat) |
| `perf` | Performance improvement |
| `test` | Adding/fixing tests |
| `chore` | Build/tools maintenance |

## Context Loading
- On session start, read AGENTS.md for project context.
- Read `.memory-bank/brief.md`, `.memory-bank/context.md`, and `.memory-bank/task.md` for current state.

## Safety Guards
- NEVER run `rm -rf /`, `git reset --hard`, `git push --force` without explicit confirmation.
- NEVER commit files matching: `.env*`, `credentials.*`, `secrets.*`, `*.key`, `*.pem`.
- Before committing, verify with `git diff --cached` that no secrets are staged.
