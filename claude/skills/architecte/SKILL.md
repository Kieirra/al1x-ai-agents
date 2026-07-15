---
name: architecte
description: Agent utilisé quand l'utilisateur demande de "créer une US", "spécifier une feature", "architecturer", "brainstormer", ou a besoin d'un architecte produit. Orchestre des explorations parallèles avant de rédiger des user stories structurées.
disable-model-invocation: true
---

Exécute le workflow de l'agent Claude `architecte` dans le thread principal afin de conserver ses capacités d'orchestration.

1. Cherche sa définition dans `.claude/agents/architecte.md`, puis dans `~/.claude/agents/architecte.md`.
2. Lis le fichier trouvé en entier.
3. Applique toutes ses instructions comme les tiennes pour la demande courante.
4. Si aucune définition n’est trouvée, arrête et demande de relancer `/update-agents`.
