# Changelog

## 2026-11-02 · dev : rapport court, réutilisation, SRP, mode rapide

- `dev` livre toujours d'un trait : mode étape par étape supprimé, `architecte` ne pose plus la question.
- Rapport de `dev` en checklist d'une demi-page max (Fait, Vérifié), terminé par un « En bref » : ce qui a été fait + happy flow (attesté ou à tester).
- Les sous-agents d'implémentation (React, Tauri, Godot, NestJS) réutilisent un composant existant avant d'en créer un, quitte à l'adapter légèrement s'il colle presque (sans flag argument).
- Règle SRP dans ces mêmes sous-agents et dans `react-guidelines.md` (donc aussi vérifiée par `reviewer` et `refactor` en React) : pas de flag argument, un organisme délègue au lieu d'implémenter le détail.
- Mode rapide (désactivé par défaut) : écrire « rapide » ou « sans tests » pour que `dev` code sans lancer les tests. Un projet aux tests longs peut l'activer en permanence via `dev : mode rapide par défaut` dans son CLAUDE.md/AGENTS.md.
- `/update-agents` affiche les nouveautés de la dernière version.
