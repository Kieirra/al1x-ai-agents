Lance un workflow complet et autonome avec les 4 super-agents, de l'architecture au code reviewé.

## Introduction

Au démarrage, affiche :

```
> Aline : J'ai étudié le sujet. Je vais structurer ça en US claire et actionnable.
> Alicia : Dès que l'US est prête, je dispatche aux devs. On code.
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

## Pipeline

### 1. Architecture — `/architecte`

Lancer `/architecte` avec le contexte fourni par l'utilisateur. Aline produit une US structurée.

**Décisions autonomes** : valider l'US telle que produite par Aline sans demander de feedback utilisateur.

### 2. Développement — `/dev`

Lancer `/dev` pour implémenter l'US. Alicia détecte la techno et dispatche au sub-agent approprié.

### 3. Quality Assurance — `/qa`

Lancer `/qa` pour les tests et stories Storybook (React/Tauri uniquement, skip pour Godot).

### 4. Code Review — `/reviewer`

Lancer `/reviewer` pour la revue de code.

### 5. Boucle de correction (si nécessaire)

Si le reviewer détecte des problèmes :

1. Lancer `/fixer` avec les findings du reviewer
2. Relancer `/qa` si des fichiers ont été modifiés
3. Relancer `/reviewer` pour re-valider
4. **Répéter** jusqu'à ce que le reviewer valide (max 3 boucles — si après 3 boucles ce n'est pas résolu, s'arrêter et rapporter le status à l'utilisateur)

### 6. Fin

Une fois le reviewer satisfait, afficher un résumé :

```
> ✅ Pipeline terminé.
> US : {nom de l'US}
> Fichiers créés/modifiés : {liste}
> Status : reviewed — prêt à merger
```

## Règles

- **Jamais de question à l'utilisateur** pendant le pipeline (sauf le prérequis initial si pas de contexte)
- **Pas de commit automatique** : le code est prêt mais l'utilisateur décide quand commit/merge
- **Adaptatif** : si le projet est Godot, skip `/qa` (pas de tests/stories). Si React/Tauri, pipeline complet
- **Transparence** : afficher une ligne de status à chaque transition d'étape (`> 🔄 Étape 2/5 : Développement...`)
- **Max 3 boucles de correction** : éviter les boucles infinies
