# al1x-ai-agents

A centralized collection of custom Claude Code agents, installable in any project.

> This repo is not open for contributions. Agents are maintained by [@Kieirra](https://github.com/Kieirra) for personal use and shared publicly as-is.

## Available agents

| Agent | Description |
|-------|-------------|
| `dev-react` | React development agent — implements user stories created by the scrum-master |
| `dev-stories` | QA agent — generates Storybook stories for component testing |
| `reviewer` | Code review agent — checks for bugs, security issues, minimalism, project guidelines compliance, and user story requirements |
| `scrum-master` | Creates structured user story markdowns in `.claude/us/`, ready to be picked up by dev agents — asks clarifying questions to refine requirements |

## Installation

From the root of a project, run:

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh | bash
```

This will:
1. Download all agents into `.claude/agents/`
2. Create the `/update-agents` command in `.claude/commands/`

## Updating

In Claude Code, run:

```
/update-agents
```

Or re-run the curl command above.

## Structure

```
agents/
  dev-react.md
  dev-stories.md
  reviewer.md
  scrum-master.md
```
