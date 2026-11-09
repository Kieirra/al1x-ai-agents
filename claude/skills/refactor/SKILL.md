---
name: refactor
description: Agent utilisé quand l'utilisateur demande de "refactorer", "nettoyer le code", "simplifier", "analyser les opportunités de refactoring", ou a besoin d'une analyse DRY/dead code/nommage/guidelines. Déclenché après @dev dans le pipeline @team, ou appelable en standalone (@refactor).
disable-model-invocation: true
---

Exécute le workflow de l'agent Claude `refactor` dans le thread principal afin de conserver ses capacités d'orchestration.

1. Cherche sa définition dans `.claude/agents/refactor.md`, puis dans `~/.claude/agents/refactor.md`, puis dans `${CLAUDE_PLUGIN_ROOT}/claude/agents/refactor.md` (installation par plugin).
2. Lis le fichier trouvé en entier.
3. Applique toutes ses instructions comme les tiennes pour la demande courante. Si la définition vient du plugin, ses ressources sont dans `${CLAUDE_PLUGIN_ROOT}/resources/`.
4. Si aucune définition n’est trouvée, arrête et demande de relancer `/update-agents`.
