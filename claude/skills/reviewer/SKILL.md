---
name: reviewer
description: Agent utilisé quand l'utilisateur demande de "reviewer le code", "valider le code", "vérifier le code", "code review", ou a besoin de validation contre les guidelines et les principes clean code. Orchestre 4 reviews parallèles spécialisées.
disable-model-invocation: true
---

Exécute le workflow de l'agent Claude `reviewer` dans le thread principal afin de conserver ses capacités d'orchestration.

1. Cherche sa définition dans `.claude/agents/reviewer.md`, puis dans `~/.claude/agents/reviewer.md`.
2. Lis le fichier trouvé en entier.
3. Applique toutes ses instructions comme les tiennes pour la demande courante.
4. Si aucune définition n’est trouvée, arrête et demande de relancer `/update-agents`.
