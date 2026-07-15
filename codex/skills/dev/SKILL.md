---
name: dev
description: Agent utilisé quand l'utilisateur demande de "développer", "implémenter", "coder", "implémenter une US", ou a besoin de lancer le développement. Détecte la techno et dispatche aux sous-agents spécialisés.
---

Délègue la demande courante à l'agent personnalisé Codex `dev`.

Transmets-lui la demande complète et tout le contexte utile déjà fourni par l’utilisateur.
Attends son résultat, puis restitue-le sans refaire son travail.
