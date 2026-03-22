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

**Si aucune instruction n'accompagne la commande `/team`** (pas de description de feature, pas de lien d'issue, pas de contexte), **demander à l'utilisateur ce qu'il veut développer avant de commencer**. Ne jamais lancer le pipeline à vide.

## Philosophie de décision

Le `/team` prend **toutes les décisions seul**, sans demander confirmation à l'utilisateur. Principes :

- **Minimaliste** : toujours choisir l'approche la plus simple
- **Conservateur** : reproduire les patterns et conventions déjà présents dans le code existant
- **Pas de risque** : ne jamais introduire de nouvelle dépendance, pattern ou architecture sans précédent dans le projet
- **Pragmatique** : si un choix est ambigu, prendre celui qui impacte le moins de fichiers

## Exécution technique

### Comment lancer un agent

Utilise le **Agent tool** avec le paramètre `subagent_type` pour lancer chaque agent :

```
Agent(subagent_type="architecte", prompt="...")
Agent(subagent_type="dev", prompt="...")
```

### Comment tracker la progression

Utilise **TaskCreate** au début du pipeline pour créer toutes les étapes, puis **TaskUpdate** pour marquer chaque étape `in_progress` puis `completed` au fur et à mesure :

```
TaskCreate(subject="1. Architecture (Aline)", description="...")
TaskCreate(subject="2. Développement (Alicia)", description="...")
TaskCreate(subject="3. Refactoring (Esquie)", description="...")
TaskCreate(subject="4. QA (Clea)", description="...")
TaskCreate(subject="5. Review (Verso)", description="...")
```

Marque chaque task `in_progress` avant de lancer l'agent correspondant, puis `completed` quand il termine.

## Pipeline

### 1. Architecture — @architecte

Lancer via `Agent(subagent_type="architecte")` avec le contexte fourni par l'utilisateur. Aline produit une US structurée.

**Décisions autonomes** : valider l'US telle que produite par Aline sans demander de feedback utilisateur.

### 2. Développement — @dev

Lancer via `Agent(subagent_type="dev")` pour implémenter l'US. Alicia détecte la techno et dispatche au sub-agent approprié.

### 3. Refactoring — @refactor

Lancer via `Agent(subagent_type="refactor")` en mode pipeline. Esquie analyse le code produit et applique le mode hybride :
- **Phase 1 (auto-fix)** : dead code, imports inutilisés, `useMemo`/`useCallback` inutiles (React), simplifications triviales — appliqués automatiquement via Monoco
- **Phase 2 (interactive)** : DRY, nommage, extractions SRP, restructurations — présentés à l'utilisateur pour validation

**Exception à l'autonomie** : la Phase 2 requiert la validation de l'utilisateur pour les transformations de design. Si aucun finding interactif, cette phase est skippée automatiquement.

### 4. Quality Assurance — @qa

Lancer via `Agent(subagent_type="qa")` pour les tests et stories Storybook (React/Tauri uniquement, skip pour Godot).

### 5. Code Review — @reviewer

Lancer via `Agent(subagent_type="reviewer")` pour la revue de code.

### 6. Boucle de correction (si nécessaire)

Si le reviewer détecte des problèmes :

1. Lancer `Agent(subagent_type="fixer")` avec les findings du reviewer
2. Relancer `Agent(subagent_type="qa")` si des fichiers ont été modifiés
3. Relancer `Agent(subagent_type="reviewer")` pour re-valider
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
- **Adaptatif** : si le projet est Godot, skip @qa (pas de tests/stories). Si React/Tauri, pipeline complet
- **Transparence** : utiliser les Tasks pour afficher la progression à chaque étape
- **Max 3 boucles de correction** : éviter les boucles infinies
