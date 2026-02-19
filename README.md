# al1x-ai-agents

A centralized collection of custom Claude Code agents, installable in any project.

> This repo is not open for contributions. Agents are maintained by [@Kieirra](https://github.com/Kieirra) for personal use and shared publicly as-is.

## Available agents

| Agent | Description |
|-------|-------------|
| `dev-react` | React development agent — implements user stories created by the scrum-master |
| `dev-tauri` | Tauri v2 fullstack agent — implements user stories with Rust backend and React frontend for desktop apps |
| `dev-stories` | QA agent — generates Storybook stories for component testing |
| `reviewer` | Code review agent — checks for bugs, security issues, minimalism, project guidelines compliance, and user story requirements |
| `scrum-master` | Creates structured user story markdowns in `.claude/us/`, ready to be picked up by dev agents — asks clarifying questions to refine requirements |

## Workflow

The agents are designed to work together in a pipeline:

```
/scrum-master  →  /dev-react or /dev-tauri  →  /dev-stories  →  /reviewer
```

1. **`/scrum-master`** — Creates a user story in `.claude/us/` and suggests a branch name
2. **`/dev-react`** — Detects the US from the current branch name and implements it (React frontend only)
3. **`/dev-tauri`** — Detects the US from the current branch name and implements it (Tauri v2: Rust backend + React frontend)
4. **`/dev-stories`** — Creates Storybook stories for the components created/modified
5. **`/reviewer`** — Reviews code, stories, and US compliance

Each agent suggests the next step when it's done. The US status is tracked automatically:

`ready` → `in-progress` → `done` → `stories-done` → `reviewed`

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
  dev-stories.md
  reviewer.md
  scrum-master.md
commands/            # Slash commands
  list-us.md
  update-agents.md
  workflow.md
```
