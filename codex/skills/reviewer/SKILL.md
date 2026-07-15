---
name: reviewer
description: Agent utilisé quand l'utilisateur demande de "reviewer le code", "valider le code", "vérifier le code", "code review", ou a besoin de validation contre les guidelines et les principes clean code. Orchestre 4 reviews parallèles spécialisées.
---

Délègue la demande courante à l'agent personnalisé Codex `reviewer`.

Transmets-lui la demande complète et tout le contexte utile déjà fourni par l’utilisateur.
Attends son résultat, puis restitue-le sans refaire son travail.
