---
name: dev
description: Agent utilisé quand l'utilisateur demande de "développer", "implémenter", "coder", "implémenter une US", ou a besoin de lancer le développement. Détecte la techno et dispatche aux sous-agents spécialisés.
disable-model-invocation: true
---

Exécute le workflow de l'agent Claude `dev` dans le thread principal afin de conserver ses capacités d'orchestration.

1. Cherche sa définition dans `.claude/agents/dev.md`, puis dans `~/.claude/agents/dev.md`.
2. Lis le fichier trouvé en entier.
3. Applique toutes ses instructions comme les tiennes pour la demande courante.
4. Si aucune définition n’est trouvée, arrête et demande de relancer `/update-agents`.
