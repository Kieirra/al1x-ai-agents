# AGENTS.md - Instructions pour Claude

## But de ce repo

Ce repo est un **gestionnaire centralisé d'agents Claude Code**. Il n'a PAS pour but de coder une application. Son unique objectif est de :

1. **Centraliser** les définitions d'agents (prompts/skills) dans un seul endroit
2. **Distribuer** ces agents dans tous les projets via un script d'installation
3. **Maintenir** une version unique de chaque agent, modifiable une seule fois et déployable partout

## Problème résolu

L'utilisateur travaille sur 5-6 projets différents. Sans ce repo, modifier un agent (ex: `dev-react`) nécessiterait de copier-coller manuellement la mise à jour dans chaque projet. Ce repo élimine ce problème.

## Structure du repo

```
al1x-ai-agents/
  agents/           # Chaque agent est un fichier .md directement dans ce dossier
    dev-react.md
    dev-tauri.md
    dev-godot.md
    dev-stories.md
    reviewer.md
    fixer.md
    scrum-master.md
  resources/        # Fichiers de référence (pas des agents)
    godot-guidelines.md
    ux-guidelines.md
    us-template-react.md
    us-template-tauri.md
    us-template-godot.md
  commands/         # Slash commands
    workflow.md
    list-us.md
    update-agents.md
  install.sh        # Script d'installation (curl depuis GitHub)
  README.md         # Documentation publique
  AGENTS.md         # Ce fichier (instructions pour Claude)
```

## Fonctionnement

- Les agents sont des fichiers `.md` dans `agents/` (format plat, pas de sous-dossiers)
- Les ressources (guidelines techniques) sont dans `resources/` et lues par les agents au besoin
- Le script `install.sh` télécharge agents, ressources et commandes depuis GitHub et les installe dans `.claude/` du projet courant
- Il crée aussi `.claude/commands/update-agents.md` pour permettre la mise à jour via `/update-agents`
- Le repo est public sur GitHub : `github.com/Kieirra/al1x-ai-agents`

## Quand tu modifies ce repo

- **Ne jamais** ajouter de code applicatif
- **Toujours** garder le format plat `agents/<nom>.md`
- **Tester** le script install.sh après modification
- **Mettre à jour** le README.md si un nouvel agent est ajouté
