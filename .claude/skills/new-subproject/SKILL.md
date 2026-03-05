---
name: new-subproject
description: >-
  Create a new Bookie sub-project under projects/ with standard directory
  structure (assets, scripts, output, README). Use when the user wants to
  start a new project, scaffold a project folder, or initialize a sub-project.
  Triggers: "new project", "create project", "init project", "scaffold project",
  "new subproject", "tao project moi".
argument-hint: "<project-name>"
---

# New Sub-project

Create a new sub-project under `projects/` with the standard Bookie structure.

## Usage

```
/new-subproject <name>
```

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided. If missing, ask Hai for the project name. Check the directory doesn't already exist at `projects/<name>/`

2. **Create structure**:
   ```
   projects/<name>/
   ├── assets/      ← media resources (images, video, audio)
   ├── scripts/     ← scripts, prompts, automation
   ├── output/      ← final deliverables
   └── README.md    ← project description
   ```

3. **Create README.md** in the new sub-project:
   ```markdown
   # <name>

   ## About
   [Brief description — to be filled in]

   ## Structure
   - `assets/` — Media resources
   - `scripts/` — Scripts and prompts
   - `output/` — Final output

   ## Status
   - Created: <today's date>
   - Status: Planning
   ```

4. **Add .gitkeep** to `assets/` and `scripts/`. For `output/`, create `.gitignore` with `*` and `!.gitignore` (align with "khong commit output" convention).

5. **Update brief.md**: Add the new sub-project to `.memory-bank/brief.md` under "Active Sub-projects" using format:
   ```
   N. **<name>**: [Brief description — ask Hai if not provided]
   ```

6. **Confirm**: Show the created structure with `ls -la projects/<name>/`.
