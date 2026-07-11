---
name: new-subproject
model: haiku
description: "Create new Bookie sub-project with standard or event-type structure"
disable-model-invocation: false
argument-hint: "<project-name> [--event]"
---

# New Sub-project

Create a new sub-project under `projects/` with the standard Bookie structure, or the event-type structure when `--event` is passed.

## Usage

```
/new-subproject <name>           # standard (pipeline/production project)
/new-subproject <name> --event   # event-type (community event/program: BD, BT, Gala, Meetup…)
```

## Steps

1. **Validate**: Check that `$ARGUMENTS` contains a project name. If missing, ask Hai for the project name. Check the directory doesn't already exist at `projects/<name>/`

2. **Create structure** — pick by variant:

   Standard (default):
   ```
   projects/<name>/
   ├── assets/      ← media resources (images, video, audio)
   ├── scripts/     ← scripts, prompts, automation
   ├── output/      ← final deliverables
   └── README.md    ← project description
   ```

   Event-type (`--event`):
   ```
   projects/<name>/
   ├── plan/        ← Operation: timeline checklist, roles, proposal, feedback spec
   ├── content/     ← Host/MC: agenda/rundown, discussion questions, evaluation
   ├── comms/       ← MarCom: email + social post templates
   ├── assets/      ← media resources (poster, photos)
   ├── output/      ← final deliverables
   └── README.md    ← project description
   ```

3. **Create README.md** in the new sub-project (adjust the Structure list to the chosen variant):
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
   - Status: Incubating
   ```
   Status vocabulary: `Incubating | Active | Paused | Archived`.

4. **Add .gitkeep** to every empty content dir (`assets/`, `scripts/` or `plan/`, `content/`, `comms/`). For `output/`, create `.gitignore` with `*` and `!.gitignore` (output is not committed).

5. **Event-type reminder** (`--event` only): this skill only scaffolds empty folders. Kit content must be authored from the matching playbook in `knowledge/03-playbook/<program>.md` — see `projects/bd-2026/` for the reference implementation. Print this reminder; do not attempt to synthesize kit content here.

6. **Confirm**: Show the created structure with `ls -la projects/<name>/`.
