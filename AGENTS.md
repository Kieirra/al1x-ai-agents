# AGENTS.md - Instructions pour Claude

## But de ce repo

Ce repo est un **gestionnaire centralisé d'agents Claude Code**. Il n'a PAS pour but de coder une application. Son unique objectif est de :

1. **Centraliser** les définitions d'agents (prompts/skills) dans un seul endroit
2. **Distribuer** ces agents dans tous les projets via un script d'installation
3. **Maintenir** une version unique de chaque agent, modifiable une seule fois et déployable partout

## Problème résolu

L'utilisateur travaille sur 5-6 projets différents. Sans ce repo, modifier un agent (ex: `dev-frontend`) nécessiterait de copier-coller manuellement la mise à jour dans chaque projet. Ce repo élimine ce problème.

## Structure du repo

```
al1x-ai-agents/
  agents/           # Chaque agent est un fichier .md directement dans ce dossier
    dev-frontend.md
    reviewer.md
    scrum-master.md
    team.md
  install.sh        # Script d'installation (curl depuis GitHub)
  README.md         # Documentation publique
  AGENTS.md         # Ce fichier (instructions pour Claude)
```

## Fonctionnement

- Les agents sont des fichiers `.md` dans `agents/` (format plat, pas de sous-dossiers)
- Le script `install.sh` télécharge les agents depuis GitHub et les place dans `.claude/agents/` du projet courant
- Il crée aussi `.claude/commands/update-agents.md` pour permettre la mise à jour via `/update-agents`
- Le repo est public sur GitHub : `github.com/Kieirra/al1x-ai-agents`

## Quand tu modifies ce repo

- **Ne jamais** ajouter de code applicatif
- **Toujours** garder le format plat `agents/<nom>.md`
- **Tester** le script install.sh après modification
- **Mettre à jour** le README.md si un nouvel agent est ajouté
