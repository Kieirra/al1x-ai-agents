---
name: team
description: Lance le pipeline autonome al1x de l'architecture à la code review.
---

Lance un workflow complet et autonome avec les 6 super-agents, de l'architecture au code reviewé.

## Introduction

Au démarrage, affiche :

```
> Aline : J'ai étudié le sujet. Je vais structurer ça en US claire et actionnable.
> Alicia : Dès que l'US est prête, je dispatche aux devs. On code.
> Esquie : Avant les tests, je simplifie. Dead code, nommage, duplications — rien ne m'échappe.
> Clea : Je surveille la qualité. Rien ne passe sans mes tests.
> Verso : Et moi je relis tout. Si c'est pas propre, ça repart en boucle.
> 🚀 L'équipe est prête. On attaque.
```

## Prérequis

**Si aucune instruction n'accompagne la commande `$team`** (pas de description de feature, pas de lien d'issue, pas de contexte), **demander à l'utilisateur ce qu'il veut développer avant de commencer**. Ne jamais lancer le pipeline à vide.

## Philosophie de décision

Le `$team` prend **toutes les décisions seul**, sans demander confirmation à l'utilisateur. Principes :

- **Minimaliste** : toujours choisir l'approche la plus simple
- **Conservateur** : reproduire les patterns et conventions déjà présents dans le code existant
- **Pas de risque** : ne jamais introduire de nouvelle dépendance, pattern ou architecture sans précédent dans le projet
- **Pragmatique** : si un choix est ambigu, prendre celui qui impacte le moins de fichiers

## Exécution technique

### Comment exécuter une étape

Les orchestrateurs `architecte`, `dev`, `refactor`, `qa` et `reviewer` ne sont **pas** lancés comme sous-agents : lancés ainsi, ils risquent de perdre leur propre délégation (`dev-react`, analyses et reviews parallèles, Monoco). Exécute leur workflow dans le thread principal :

1. Cherche la définition dans `.codex/agents/<nom>.toml`, puis `~/.codex/agents/<nom>.toml`.
2. Lis-la en entier au début de l'étape et applique son champ `developer_instructions` comme tes propres instructions, avec le contexte du pipeline (US, branche).
3. Ses délégations partent en sous-agents via les outils de sous-agents Codex, comme prévu dans sa définition.
4. Si aucune définition n'est trouvée, arrête et demande de relancer `$update-agents`.

Les règles de `$team` priment sur celles de l'agent : là où sa définition pose une question à l'utilisateur, décide toi-même selon la philosophie ci-dessus (seule exception : la Phase 2 d'Esquie).

Seul `fixer` (Monoco) est lancé directement comme sous-agent via les outils de sous-agents Codex, avec les findings à corriger.

### Comment tracker la progression

Utilise le mécanisme de plan Codex disponible dans la session. Crée dès le début les cinq étapes suivantes :

1. Architecture (Aline)
2. Développement (Alicia)
3. Refactoring (Esquie)
4. QA (Clea)
5. Review (Verso)

Une seule étape peut être `in_progress`. Marque une étape `completed` avant de passer à la suivante et actualise le plan à la fin de chaque étape.

## Pipeline

### 1. Architecture — $architecte

Exécuter le workflow `architecte` avec le contexte fourni par l'utilisateur. Aline produit une US structurée.

**Décisions autonomes** : valider l'US telle que produite par Aline sans demander de feedback utilisateur.

### 2. Développement — $dev

Exécuter le workflow `dev` pour implémenter l'US. Alicia détecte la techno et dispatche au sous-agent approprié (`dev-react`, `dev-tauri`, `dev-godot`, `nestjs-backend`).

### 3. Refactoring — $refactor

Exécuter le workflow `refactor` en mode pipeline. Esquie analyse le code produit et applique le mode hybride :
- **Phase 1 (auto-fix)** : dead code, imports inutilisés, `useMemo`/`useCallback` inutiles (React), simplifications triviales — appliqués automatiquement via Monoco
- **Phase 2 (interactive)** : DRY, nommage, extractions SRP, restructurations — présentés à l'utilisateur pour validation

**Exception à l'autonomie** : la Phase 2 requiert la validation de l'utilisateur pour les transformations de design. Si aucun finding interactif, cette phase est skippée automatiquement.

### 4. Quality Assurance — $qa

Exécuter le workflow `qa` pour les tests et stories Storybook (React/Tauri uniquement, skip pour Godot).

### 5. Code Review — $reviewer

Exécuter le workflow `reviewer` pour la revue de code. Pas de présentation par lots ni de question : retenir les choix recommandés (⭐) et passer les findings retenus à la boucle de correction ci-dessous, qui remplace le lancement de Monoco par Verso.

### 6. Boucle de correction (si nécessaire)

Si le reviewer détecte des problèmes :

1. Lancer le sous-agent `fixer` avec les findings du reviewer
2. Réexécuter le workflow `qa` si des fichiers ont été modifiés
3. Réexécuter le workflow `reviewer` pour re-valider
4. **Répéter** jusqu'à ce que le reviewer valide (max 3 boucles — si après 3 boucles ce n'est pas résolu, s'arrêter et rapporter le status à l'utilisateur)

### 7. Fin

Une fois le reviewer satisfait, afficher un résumé :

```
> ✅ Pipeline terminé.
> US : {nom de l'US}
> Fichiers créés/modifiés : {liste}
> Status : reviewed — prêt à merger
```

## Règles

- **Jamais de question à l'utilisateur** pendant le pipeline (sauf le prérequis initial si pas de contexte, et la Phase 2 d'Esquie pour les refactorings de design)
- **Pas de commit automatique** : le code est prêt mais l'utilisateur décide quand commit/merge
- **Adaptatif** : si le projet est Godot, skip $qa (pas de tests/stories). Si React/Tauri, pipeline complet
- **Transparence** : actualiser le plan Codex à chaque étape
- **Max 3 boucles de correction** : éviter les boucles infinies
