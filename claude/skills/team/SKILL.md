---
name: team
description: Lance le pipeline autonome al1x de l'architecture à la code review.
disable-model-invocation: true
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

**Si aucune instruction n'accompagne la commande `/team`** (pas de description de feature, pas de lien d'issue, pas de contexte) **et que la session ne contient ni discussion préalable (Aline, Renoir) ni US pour la branche courante**, **demander à l'utilisateur ce qu'il veut développer avant de commencer**. Ne jamais lancer le pipeline à vide.

## Philosophie de décision

Le `/team` prend **toutes les décisions seul**, sans demander confirmation à l'utilisateur. Principes :

- **Minimaliste** : toujours choisir l'approche la plus simple
- **Conservateur** : reproduire les patterns et conventions déjà présents dans le code existant
- **Pas de risque** : ne jamais introduire de nouvelle dépendance, pattern ou architecture sans précédent dans le projet
- **Pragmatique** : si un choix est ambigu, prendre celui qui impacte le moins de fichiers

## Exécution technique

### Comment exécuter une étape

Les orchestrateurs `architecte`, `dev`, `refactor`, `qa` et `reviewer` ne sont **pas** lancés comme sous-agents : un sous-agent n'a pas l'Agent tool et perdrait sa propre délégation (`dev-react`, analyses et reviews parallèles, Monoco). Exécute leur workflow dans le thread principal, comme le font leurs skills :

1. Cherche la définition dans `.claude/agents/<nom>.md`, puis `~/.claude/agents/<nom>.md`, puis `${CLAUDE_PLUGIN_ROOT}/claude/agents/<nom>.md` (ressources plugin dans `${CLAUDE_PLUGIN_ROOT}/resources/`).
2. Lis-la en entier au début de l'étape et applique ses instructions comme les tiennes, avec le contexte du pipeline (US, branche).
3. Ses délégations partent en sous-agents via l'Agent tool, comme prévu dans sa définition.
4. Si aucune définition n'est trouvée, arrête et demande de relancer `/update-agents`.

Les règles de `/team` priment sur celles de l'agent : là où sa définition pose une question à l'utilisateur, décide toi-même selon la philosophie ci-dessus. Aucune exception.

Seul `fixer` (Monoco) est lancé directement comme sous-agent via l'Agent tool, avec les findings à corriger.

### Comment tracker la progression

Utilise **TaskCreate** au début du pipeline pour créer toutes les étapes, puis **TaskUpdate** pour marquer chaque étape `in_progress` puis `completed` au fur et à mesure :

```
TaskCreate(subject="1. Architecture (Aline)", description="...")
TaskCreate(subject="2. Développement (Alicia)", description="...")
TaskCreate(subject="3. Refactoring (Esquie)", description="...")
TaskCreate(subject="4. QA (Clea)", description="...")
TaskCreate(subject="5. Review (Verso)", description="...")
```

Marque chaque task `in_progress` au début de l'étape correspondante, puis `completed` quand elle se termine.

## Pipeline

### 1. Architecture — @architecte

Prendre le premier cas qui s'applique :

1. **US déjà prête** : Aline a rédigé l'US plus tôt dans cette session, ou `.claude/us/<branche-avec-tirets>.md` existe avec le Status `ready`. Ne pas relancer Aline : utiliser cette US telle quelle (plus les précisions passées avec `/team`) et marquer l'étape `completed`.
2. **Décisions déjà prises dans la session** (discussion avec Aline ou Renoir sans US finale) : exécuter le workflow `architecte` en reprenant ces décisions comme réponses. Ne reposer et ne remettre en cause aucun point déjà tranché, décider seul uniquement les trous restants.
3. **Sinon** : exécuter le workflow `architecte` avec le contexte fourni par l'utilisateur.

**Décisions autonomes** : valider l'US produite sans demander de feedback utilisateur. Rester sur la branche courante (option C de l'étape 7 d'Aline) : jamais de `git checkout` en autonomie.

### 2. Développement — @dev

Exécuter le workflow `dev` pour implémenter l'US. Alicia détecte la techno et dispatche au sous-agent approprié (`dev-react`, `dev-tauri`, `dev-godot`, `nestjs-backend`).

### 3. Refactoring — @refactor

Exécuter le workflow `refactor` en mode pipeline. Esquie analyse le code produit et l'améliore en deux phases, sans question :
- **Phase 1 (auto-fix)** : dead code, imports inutilisés, `useMemo`/`useCallback` inutiles (React), simplifications triviales — appliqués automatiquement via Monoco
- **Phase 2 (autonome)** : DRY, nommage, extractions SRP, restructurations. Esquie applique sa grille ⭐ sans présentation ni question : Monoco applique les `A) Améliorer ⭐`, les autres sont skippés.

### 4. Quality Assurance — @qa

Exécuter le workflow `qa` pour les tests et stories Storybook (React/Tauri uniquement, skip pour Godot).

### 5. Code Review — @reviewer

Exécuter le workflow `reviewer` pour la revue de code. Pas de présentation par lots ni de question : retenir les choix recommandés (⭐) et passer les findings retenus à la boucle de correction ci-dessous, qui remplace le lancement de Monoco par Verso.

### 6. Boucle de correction (si nécessaire)

Si le reviewer détecte des problèmes :

1. Lancer le sous-agent `fixer` avec les findings du reviewer
2. Réexécuter le workflow `qa` si des fichiers ont été modifiés
3. Réexécuter le workflow `reviewer` pour re-valider
4. **Répéter** jusqu'à ce que le reviewer valide (max 3 boucles : si après 3 boucles ce n'est pas résolu, s'arrêter et passer au rapport final avec les bloquants restants)

### 7. Fin

Toujours terminer par ce rapport, même si la boucle de correction s'arrête sur un échec. C'est le seul message que l'utilisateur lit pour savoir ce qui a été fait et comment tester : il reprend le format du rapport d'Alicia (étape 4 de `dev`), consolidé sur tout le pipeline.

```
## Pipeline terminé : {titre de l'US}

### Fait
- ✅ {changement livré}
- ⚠️ {écart par rapport à l'US que l'utilisateur verra en testant}

### À tester
1. {action ou commande à copier} → {résultat attendu}
2. {action} → {résultat attendu}

Contrôles : {tests N ✅ · N ❌ · lint · compilation} · refactor {N appliqués} · review {✅ validée | ❌ N bloquants restants}

### En bref
{1-2 phrases : ce qui a été fait, et prêt à commit ou ce qui bloque}
```

- **Fait** et **À tester** : mêmes règles que le rapport d'Alicia, mis à jour avec ce que le refactor et les corrections ont changé (un comportement modifié change les étapes de test).
- Aucune étape ni « prochaine commande » à suggérer : le pipeline est terminé.

## Règles

- **Jamais de question à l'utilisateur** pendant le pipeline (seule exception : le prérequis initial si aucun contexte)
- **Pas de commit automatique** : le code est prêt mais l'utilisateur décide quand commit/merge
- **Adaptatif** : si le projet est Godot, skip @qa (pas de tests/stories). Si React/Tauri, pipeline complet
- **Transparence** : utiliser les Tasks pour afficher la progression à chaque étape
- **Max 3 boucles de correction** : éviter les boucles infinies
