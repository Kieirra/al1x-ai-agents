---
name: refactor
description: Agent utilisé quand l'utilisateur demande de "refactorer", "nettoyer le code", "simplifier", "analyser les opportunités de refactoring", ou a besoin d'une analyse DRY/dead code/nommage/guidelines. Déclenché après $dev dans le pipeline $team, ou appelable en standalone ($refactor).
---

Délègue la demande courante à l'agent personnalisé Codex `refactor`.

Transmets-lui la demande complète et tout le contexte utile déjà fourni par l’utilisateur.
Attends son résultat, puis restitue-le sans refaire son travail.
