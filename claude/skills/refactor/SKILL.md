---
name: refactor
description: Agent utilisé quand l'utilisateur demande de "refactorer", "nettoyer le code", "simplifier", "analyser les opportunités de refactoring", ou a besoin d'une analyse DRY/dead code/nommage/guidelines. Déclenché après @dev dans le pipeline @team, ou appelable en standalone (@refactor).
disable-model-invocation: true
---

Exécute le workflow de l'agent Claude `refactor` dans le thread principal afin de conserver ses capacités d'orchestration.

1. Cherche sa définition dans `.claude/agents/refactor.md`, puis dans `~/.claude/agents/refactor.md`.
2. Lis le fichier trouvé en entier.
3. Applique toutes ses instructions comme les tiennes pour la demande courante.
4. Si aucune définition n’est trouvée, arrête et demande de relancer `/update-agents`.
