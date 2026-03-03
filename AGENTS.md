# AGENTS.md - Instructions pour Claude

## But de ce repo

Ce repo est un **gestionnaire centralisé d'agents Claude Code**. Il n'a PAS pour but de coder une application. Son unique objectif est de :

1. **Centraliser** les définitions d'agents (prompts/skills) dans un seul endroit
2. **Distribuer** ces agents dans tous les projets via un script d'installation
3. **Maintenir** une version unique de chaque agent, modifiable une seule fois et déployable partout

## Problème résolu

L'utilisateur travaille sur 5-6 projets différents. Sans ce repo, modifier un agent (ex: `dev-react`) nécessiterait de copier-coller manuellement la mise à jour dans chaque projet. Ce repo élimine ce problème.

## Architecture : Super-agents + Sub-agents

Les agents sont organisés en deux niveaux :

- **Super-agents** (`user-invocable: true`) : orchestrateurs qui lancent des sub-agents en parallèle via le Task tool
  - `architecte.md` (Aline), `dev.md` (Alicia), `qa.md` (Clea), `uxui.md` (Renoir), `reviewer.md` (Verso)
- **Sub-agents** (`user-invocable: false`) : spécialistes appelés par les super-agents
  - `dev-react.md` (Maelle), `dev-tauri.md` (Lune), `dev-godot.md` (Sciel), `dev-stories.md` (Gustave), `fixer.md` (Monoco)

Le champ `user-invocable` dans le frontmatter YAML de chaque agent détermine comment `install.sh` l'installe :
- `true` → dans `.claude/commands/` (slash command) ET `.claude/agents/` (auto-délégation)
- `false` → dans `.claude/agents/` uniquement (pas de slash command)

## Structure du repo

```
al1x-ai-agents/
  agents/               # Chaque agent est un fichier .md (format plat)
    architecte.md       # Super-agent (Aline) - product architect
    dev.md              # Super-agent (Alicia) - lead developer
    qa.md               # Super-agent (Clea) - QA lead
    uxui.md             # Super-agent (Renoir) - UX/UI architect
    reviewer.md         # Super-agent (Verso) - code guardian
    dev-react.md        # Sub-agent (Maelle) - React/TypeScript
    dev-tauri.md        # Sub-agent (Lune) - Tauri v2 / Rust
    dev-godot.md        # Sub-agent (Sciel) - Godot 4 / GDScript
    dev-stories.md      # Sub-agent (Gustave) - Storybook stories
    fixer.md            # Sub-agent (Monoco) - targeted fixes
  resources/            # Fichiers de référence (pas des agents)
    godot-guidelines.md
    ux-guidelines.md
    us-template-react.md
    us-template-tauri.md
    us-template-godot.md
  commands/             # Slash commands (utilitaires)
    workflow.md
    list-us.md
    update-agents.md
  install.sh            # Script d'installation (curl depuis GitHub)
  README.md             # Documentation publique
  AGENTS.md             # Ce fichier (instructions pour Claude)
```

## Fonctionnement

- Les agents sont des fichiers `.md` dans `agents/` (format plat, pas de sous-dossiers)
- Les ressources (guidelines techniques) sont dans `resources/` et lues par les agents au besoin
- Le script `install.sh` télécharge agents, ressources et commandes depuis GitHub et les installe dans `.claude/` du projet courant
- Il parse le frontmatter YAML pour router super-agents vs sub-agents
- Le repo est public sur GitHub : `github.com/Kieirra/al1x-ai-agents`

## Quand tu modifies ce repo

- **Ne jamais** ajouter de code applicatif
- **Toujours** garder le format plat `agents/<nom>.md`
- **Respecter** le frontmatter YAML : `user-invocable: true` pour les super-agents, `false` pour les sub-agents
- **Tester** le script install.sh après modification
- **Mettre à jour** le README.md si un agent est ajouté/modifié
