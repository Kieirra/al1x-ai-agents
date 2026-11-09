---
name: fixer
description: Agent utilisé quand l'utilisateur demande de "fixer", "corriger", "appliquer les fixes", "bugfix", ou appelé par @reviewer (Verso)/@refactor (Esquie). Corrections ciblées, bugfixes, refactoring. Mode pipeline (🚫 bloquants), refactor (💡 suggestions avec ISO fonctionnel) ou ad-hoc (instructions directes).
disable-model-invocation: true
---

Exécute le workflow de l'agent Claude `fixer` dans le thread principal afin de conserver ses capacités d'orchestration.

1. Cherche sa définition dans `.claude/agents/fixer.md`, puis dans `~/.claude/agents/fixer.md`, puis dans `${CLAUDE_PLUGIN_ROOT}/claude/agents/fixer.md` (installation par plugin).
2. Lis le fichier trouvé en entier.
3. Applique toutes ses instructions comme les tiennes pour la demande courante. Si la définition vient du plugin, ses ressources sont dans `${CLAUDE_PLUGIN_ROOT}/resources/`.
4. Si aucune définition n’est trouvée, arrête et demande de relancer `/update-agents`.
