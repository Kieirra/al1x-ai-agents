# Changelog

## 2026-11-09 · commit unique par défaut, /commit-mine, plugin Claude Code

- `/commit` commite tout en un seul commit, sauf si tu demandes explicitement un découpage.
- Nouveau `/commit-mine` : commite seulement les fichiers modifiés par l'agent en cours (en entier) et signale ceux qui contiennent peut-être les changements d'un autre agent.
- `/commit` et `/commit-mine` ne suppriment ni ne restaurent jamais un fichier : les changements des autres agents restent intacts.
- Installation Claude Code par plugin, sans script : `/plugin marketplace add Kieirra/al1x-ai-agents` puis `/plugin install al@al1x-ai-agents`. Les commandes deviennent `/al:dev`, `/al:commit`, etc.

## 2026-11-02 · dev : rapport court, réutilisation, SRP, mode rapide

- `dev` livre toujours d'un trait : mode étape par étape supprimé, `architecte` ne pose plus la question.
- Rapport de `dev` en checklist d'une demi-page max (Fait, Vérifié), terminé par un « En bref » : ce qui a été fait + happy flow (attesté ou à tester).
- Les sous-agents d'implémentation (React, Tauri, Godot, NestJS) réutilisent un composant existant avant d'en créer un, quitte à l'adapter légèrement s'il colle presque (sans flag argument).
- Règle SRP dans ces mêmes sous-agents et dans `react-guidelines.md` (donc aussi vérifiée par `reviewer` et `refactor` en React) : pas de flag argument, un organisme délègue au lieu d'implémenter le détail.
- Mode rapide (désactivé par défaut) : écrire « rapide » ou « sans tests » pour que `dev` code sans lancer les tests. Un projet aux tests longs peut l'activer en permanence via `dev : mode rapide par défaut` dans son CLAUDE.md/AGENTS.md.
- `/update-agents` affiche les nouveautés de la dernière version.
