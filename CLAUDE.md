# AGENTS.md - Instructions pour Claude

## But de ce repo

Ce repo est un **gestionnaire centralisé d'agents Claude Code**. Son unique objectif est de :

1. **Centraliser** les définitions d'agents dans un seul endroit
2. **Distribuer** ces agents dans tous les projets via un script d'installation
3. **Maintenir** une version unique de chaque agent, modifiable une seule fois et déployable partout

## Architecture

Les agents sont organisés en deux niveaux :

- **Orchestrateurs** : agents invocables via `@nom` qui lancent des sub-agents en parallèle via le Agent tool
  - `architecte.md` (Aline), `dev.md` (Alicia), `qa.md` (Clea), `uxui.md` (Renoir), `reviewer.md` (Verso), `refactor.md` (Esquie)
- **Sub-agents** : spécialistes lancés automatiquement par les orchestrateurs
  - `dev-react.md` (Maelle), `dev-tauri.md` (Lune), `dev-godot.md` (Sciel), `dev-stories.md` (Gustave), `fixer.md` (Monoco), `nestjs-backend.md`

Tous les agents sont des fichiers plats dans `agents/` avec frontmatter YAML (`name`, `description`, `model`, `color`, `memory`).

## Structure du repo

```
al1x-ai-agents/
  agents/               # Agents (fichiers plats .md)
    architecte.md       # Aline — product architect
    dev.md              # Alicia — lead developer
    dev-react.md        # Maelle — React/TypeScript
    dev-tauri.md        # Lune — Tauri v2 / Rust
    dev-godot.md        # Sciel — Godot 4 / GDScript
    dev-stories.md      # Gustave — Storybook stories
    nestjs-backend.md   # NestJS backend specialist
    qa.md               # Clea — QA lead
    reviewer.md         # Verso — code guardian
    refactor.md         # Esquie — refactoring analyst
    fixer.md            # Monoco — targeted fixes
    uxui.md             # Renoir — UX/UI architect
  commands/             # Slash commands (utilitaires, pas des agents)
    team.md             # Pipeline complet autonome
    workflow.md         # Guide vers la prochaine étape
    list-us.md          # Liste les user stories
    update-agents.md    # Met à jour les agents
    archive-us.md       # Archive les US terminées
    commit.md           # Commit conventionnel
    create-pr.md        # Création de PR
  skills/               # Skills (dossiers avec SKILL.md, format natif Claude Code)
    check-stories/      # Vérification visuelle Storybook via Playwright CLI
      SKILL.md
  resources/            # Fichiers de référence (lus par les agents)
    react-guidelines.md
    godot-guidelines.md
    ux-guidelines.md
    us-template-react.md
    us-template-tauri.md
    us-template-godot.md
  tools/                # Scripts CLI standalone
    review-pr
  install.sh            # Script d'installation
  README.md             # Documentation publique
  AGENTS.md             # Ce fichier (instructions pour Claude)
```

## Fonctionnement

- Les agents sont des fichiers `.md` dans `agents/` (format plat, pas de sous-dossiers)
- Invocables via `@nom` dans Claude Code (ex: `@dev`, `@reviewer`)
- Les commandes utilitaires restent en `/nom` (ex: `/team`, `/workflow`)
- Les skills sont des dossiers dans `skills/<nom>/` avec `SKILL.md` + `scripts/` optionnel (format natif Claude Code)
- Le script `install.sh` télécharge agents, commandes, skills et ressources depuis GitHub et les installe dans `~/.claude/`
- Le repo est public sur GitHub : `github.com/Kieirra/al1x-ai-agents`

## Quand tu modifies ce repo

- **Ne jamais** ajouter de code applicatif
- **Toujours** garder le format plat `agents/<nom>.md`
- **Respecter** le frontmatter YAML : `name`, `description`, `model`, `color`, `memory`
- **Tester** le script install.sh après modification
- **Mettre à jour** le README.md si un agent est ajouté/modifié
