# al1x-ai-agents

A centralized collection of custom Claude Code agents, installable in any project.

> This repo is not open for contributions. Agents are maintained by [@Kieirra](https://github.com/Kieirra) for personal use and shared publicly as-is.

## Available agents

| Agent | Pseudo | Description |
|-------|--------|-------------|
| `scrum-master` | **Scala** | Product architect — creates structured user story markdowns in `.claude/us/`, loads tech-specific templates, ready to be picked up by dev agents |
| `dev-react` | **Rhea** | Frontend developer — implements user stories created by the scrum-master (React) |
| `dev-tauri` | **Talia** | Fullstack developer — implements user stories with Rust backend and React frontend for desktop apps (Tauri v2) |
| `dev-stories` | **Stella** | Visual QA — generates Storybook stories for component testing |
| `reviewer` | **Reva** | Code guardian — reviews code, writes structured findings in the US |
| `dev-godot` | **Gaia** | Game developer — implements user stories in Godot 4 / GDScript for 2D games with ECS-Hybrid architecture |
| `fixer` | **Fira** | Fixer — applies targeted corrections (review findings or direct user instructions) |

## Workflow

The agents are designed to work together in a pipeline. The pipeline adapts to the project's technology:

### React / Tauri (with frontend)
```
/scrum-master (Scala) → /dev-react (Rhea) ou /dev-tauri (Talia) → /dev-stories (Stella) → /reviewer (Reva)
                                                                                                  ↓
                                                                                        ✅ reviewed → merge
                                                                                        ❌ changes-requested → /fixer (Fira) → /reviewer (boucle)
```

### Godot (no stories)
```
/scrum-master (Scala) → /dev-godot (Gaia) → /reviewer (Reva)
                                                     ↓
                                           ✅ reviewed → merge
                                           ❌ changes-requested → /fixer (Fira) → /reviewer (boucle)
```

### Agents

1. **`/scrum-master`** (Lira) — Creates a user story in `.claude/us/` (adapts template to project tech)
2. **`/dev-react`** (Iris) — Detects the US from the current branch name and implements it (React frontend only)
3. **`/dev-tauri`** (Vesta) — Detects the US from the current branch name and implements it (Tauri v2: Rust backend + React frontend)
4. **`/dev-godot`** (Aria) — Detects the US from the current branch name and implements it (Godot 4: GDScript, 2D, ECS-Hybrid, Scene-First)
5. **`/dev-stories`** (Chroma) — Creates Storybook stories for the components created/modified (React / Tauri only)
6. **`/reviewer`** (Athena) — Reviews code, stories, and US compliance. Adapts checklist to project tech. Writes structured findings in the US
7. **`/fixer`** (Echo) — Reads review findings from the US and applies targeted corrections for blockers

Each agent suggests the next step when it's done. The US status is tracked automatically:

**React / Tauri:** `ready` → `in-progress` → `done` → `stories-done` → `reviewed` (merge)

**Godot:** `ready` → `in-progress` → `done` → `reviewed` (merge)

If changes are requested:

`changes-requested` → `fixed` → `reviewed` (loop back to reviewer)

## Available commands

| Command | Description |
|---------|-------------|
| `/update-agents` | Re-downloads all agents and commands from this repo |
| `/workflow` | Shows the current pipeline status and suggests the next step |
| `/list-us` | Lists all user stories in `.claude/us/` with their status |

## Installation

From the root of a project, run:

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh | bash
```

This will install each agent in two locations:
- **`.claude/commands/`** — as skills, invokable via `/dev-react`, `/scrum-master`, etc.
- **`.claude/agents/`** — as subagents, automatically delegated by Claude when relevant

It also installs utility commands (`/workflow`, `/list-us`, `/update-agents`) in `.claude/commands/`.

## Updating

In Claude Code, run:

```
/update-agents
```

Or re-run the curl command above.

## Structure

```
agents/              # Agent definitions
  dev-react.md
  dev-tauri.md
  dev-godot.md
  dev-stories.md
  fixer.md
  reviewer.md
  scrum-master.md
commands/            # Slash commands
  list-us.md
  update-agents.md
  workflow.md
resources/           # Reference files (not agents)
  godot-guidelines.md    # Godot 4 architecture & conventions — used by Aria, Athena, Echo
  ux-guidelines.md       # UX/UI frameworks (BMAP, B.I.A.S.) — used by Lira
  us-template-react.md   # US template for React projects — loaded by Lira
  us-template-tauri.md   # US template for Tauri projects — loaded by Lira
  us-template-godot.md   # US template for Godot projects — loaded by Lira
```
