---
name: new-subproject
description: Create a new sub-project with standard directory structure
argument-hint: "<project-name>"
disable-model-invocation: true
---

# New Sub-project

Create a new sub-project under `projects/` with the standard Bookie structure.

## Usage

```
/new-subproject <name>
```

## Steps

1. **Validate**: Check that `$ARGUMENTS` is provided and the directory doesn't already exist at `projects/<name>/`

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

4. **Add .gitkeep** to empty directories (`assets/`, `scripts/`, `output/`) so git tracks them.

5. **Update brief.md**: Add the new sub-project to `.memory-bank/brief.md` under "Active Sub-projects".

6. **Confirm**: Show the created structure with `ls -la projects/<name>/`.
