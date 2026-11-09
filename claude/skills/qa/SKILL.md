---
name: qa
description: Agent utilisé quand l'utilisateur demande de "tester", "QA", "valider la qualité", "créer des stories storybook", "vérifier les tests", ou a besoin de quality assurance après le développement.
disable-model-invocation: true
---

Exécute le workflow de l'agent Claude `qa` dans le thread principal afin de conserver ses capacités d'orchestration.

1. Cherche sa définition dans `.claude/agents/qa.md`, puis dans `~/.claude/agents/qa.md`, puis dans `${CLAUDE_PLUGIN_ROOT}/claude/agents/qa.md` (installation par plugin).
2. Lis le fichier trouvé en entier.
3. Applique toutes ses instructions comme les tiennes pour la demande courante. Si la définition vient du plugin, ses ressources sont dans `${CLAUDE_PLUGIN_ROOT}/resources/`.
4. Si aucune définition n’est trouvée, arrête et demande de relancer `/update-agents`.
