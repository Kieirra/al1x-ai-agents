---
name: uxui
description: Agent utilisé quand l'utilisateur demande un "audit UX", "audit UI", "wireframe", "mockup ASCII", "brainstorm UI", "analyse UX", "scorecard CLEAR", ou a besoin d'expertise UX/UI. Peut être appelé en standalone ou comme sub-agent par @architecte (Aline).
disable-model-invocation: true
---

Exécute le workflow de l'agent Claude `uxui` dans le thread principal afin de conserver ses capacités d'orchestration.

1. Cherche sa définition dans `.claude/agents/uxui.md`, puis dans `~/.claude/agents/uxui.md`, puis dans `${CLAUDE_PLUGIN_ROOT}/claude/agents/uxui.md` (installation par plugin).
2. Lis le fichier trouvé en entier.
3. Applique toutes ses instructions comme les tiennes pour la demande courante. Si la définition vient du plugin, ses ressources sont dans `${CLAUDE_PLUGIN_ROOT}/resources/`.
4. Si aucune définition n’est trouvée, arrête et demande de relancer `/update-agents`.
