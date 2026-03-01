# Bookie — Project Context

> Soul & identity: see global ~/.claude/CLAUDE.md

## About

**Book!e Inspires Everyone** — Cộng đồng người đọc sách, truyền cảm hứng đọc sách và học hỏi.

- Website: bookiecommunity.com
- Fanpage: facebook.com/bookie.community

## Project Structure

Resource hub cho multiple sub-projects. Không phải codebase — chủ yếu chứa assets, scripts, và configs.

```
Bookie/
├── projects/           ← sub-projects (mỗi dự án con 1 folder)
│   └── <name>/
│       ├── assets/     ← media resources
│       ├── scripts/    ← scripts, prompts
│       └── output/     ← final output
├── shared/             ← resources dùng chung
│   ├── branding/       ← logo, brand assets
│   └── templates/      ← templates tái sử dụng
└── .memory-bank/       ← project knowledge
```

### Sub-project Conventions

- Mỗi sub-project nằm trong `projects/<name>/`
- Dùng `/new-subproject <name>` để tạo sub-project mới với structure chuẩn
- Large media files tracked bằng Git LFS (video, PSD, audio, etc.)
- Output cuối cùng đặt trong `output/`, không commit output vào git trừ khi cần thiết

## Project Values
- **Minimal impact** — Make the smallest changes necessary. Don't over-engineer
- **No dirty state** — Don't leave the environment broken. Verify changes work before completing a task
- **Reversibility** — Ensure significant changes can be undone if needed

### Boundaries
- Project này là resource hub, không phải application code
- Không setup backend/frontend infrastructure
- Notes chi tiết về dự án nằm ở Obsidian Idea_Vault, không duplicate ở đây

## Memory Bank
Auto-loaded at session start (brief, context, tech). Full files in `.memory-bank/`:
- `brief.md` — Project goals and scope
- `product.md` — Product context and constraints
- `context.md` — Current focus and recent changes
- `architecture.md` — System architecture
- `tech.md` — Tech stack and tooling

After major tasks or architectural changes, update relevant Memory Bank files (use `/update-mb`).

## Security
**CRITICAL**: NEVER commit, push, or expose secrets, API keys, tokens, or credentials to version control.

- NEVER hardcode secrets in code — use environment variables and `.env` files
- NEVER commit files containing secrets — verify with `git diff --cached` before committing
- ALWAYS check `.gitignore` has `.env*`, `credentials.*`, `secrets.*`, `*.key`, `*.pem`
- ASK before committing sensitive-looking files (`config.json`, `.env*`, `credentials.*`)
- If secrets are accidentally committed: STOP, alert user to revoke, remove from history, add to `.gitignore`
