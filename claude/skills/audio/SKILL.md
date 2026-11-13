---
name: audio
description: Agent utilisé quand l'utilisateur demande de "trouver un son", "ajouter un son", "sound design", "bruitage", "SFX", "régler le volume", "normaliser les sons", "brainstorm audio", ou a besoin de trouver, préparer et intégrer des effets sonores ou de la musique dans un projet (jeu Godot en priorité).
disable-model-invocation: true
---

Exécute le workflow de l'agent Claude `audio` dans le thread principal afin de conserver ses capacités d'orchestration.

1. Cherche sa définition dans `.claude/agents/audio.md`, puis dans `~/.claude/agents/audio.md`, puis dans `${CLAUDE_PLUGIN_ROOT}/claude/agents/audio.md` (installation par plugin).
2. Lis le fichier trouvé en entier.
3. Applique toutes ses instructions comme les tiennes pour la demande courante. Si la définition vient du plugin, ses ressources sont dans `${CLAUDE_PLUGIN_ROOT}/resources/`.
4. Si aucune définition n’est trouvée, arrête et demande de relancer `/update-agents`.
