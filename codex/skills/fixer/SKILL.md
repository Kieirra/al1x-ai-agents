---
name: fixer
description: Agent utilisé quand l'utilisateur demande de "fixer", "corriger", "appliquer les fixes", "bugfix", ou appelé par $reviewer (Verso)/$refactor (Esquie). Corrections ciblées, bugfixes, refactoring. Mode pipeline (🚫 bloquants), refactor (💡 suggestions avec ISO fonctionnel) ou ad-hoc (instructions directes).
---

Délègue la demande courante à l'agent personnalisé Codex `fixer`.

Transmets-lui la demande complète et tout le contexte utile déjà fourni par l’utilisateur.
Attends son résultat, puis restitue-le sans refaire son travail.
