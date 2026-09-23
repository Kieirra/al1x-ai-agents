---
name: plan-to-review
description: Propose un ordre de lecture des fichiers modifiés pour une review humaine rapide, des points d'entrée vers les détails, avec points d'attention.
---
Propose un plan de review des changements `$ARGUMENTS` (par défaut : la PR de la branche courante, sinon les modifications locales).

## Périmètre

Dans l'ordre, s'arrêter dès qu'un périmètre est trouvé :

1. **Argument explicite** : numéro de PR, branche ou plage de commits.
2. **PR en cours** : `gh pr view` puis `gh pr diff` (fichiers et contenu).
3. **Changement en cours** : `git diff HEAD` + fichiers non suivis.

Si `.claude/us/` contient une US liée à la branche ou au sujet, la lire pour connaître l'intention fonctionnelle.

## Ordonnancement

Lire les fichiers modifiés pour reconstituer qui importe ou appelle qui. Ordre de lecture :

1. **Points d'entrée** : là où le nouveau code se branche à l'existant (route, page, composant monté, commande Tauri `#[command]`, controller, signal/EventBus, point d'extension). Un fichier existant modifié d'une ligne pour brancher la feature est souvent le premier à lire.
2. **Orchestrateurs** : composants parents, hooks principaux, services, systèmes.
3. **Détails** : sous-composants, helpers, types, utils. Toujours en dernier, jamais en premier.
4. **Tests et stories** en fin de liste, sauf si un test résume mieux le comportement que le code.

Un fichier lu tôt ne doit pas exiger la compréhension d'un fichier lu plus tard. Grouper par flux (entrée puis détails de ce flux) plutôt que par type de fichier.

## Réponse

Courte et précise, lisible en 1 minute :

- **Une phrase de contexte** : ce que fait le changement (l'US si elle existe).
- **Liste numérotée des fichiers**, chacun au format `chemin/depuis/la/racine/du/repo.ext:ligne` (ligne où commencer la lecture, cliquable dans l'IDE), suivi d'une phrase max : rôle du fichier et ce qu'on y cherche.
- **⚠️ Points d'attention** : 0 à 5, uniquement ce qui mérite un regard humain (branchement à l'existant, comportement modifié, cas limite, choix d'architecture discutable). Chaque point renvoie à un `fichier:ligne`. Pas de review complète : c'est le rôle de `/reviewer`.
- **À survoler** : une seule ligne finale regroupant les fichiers mécaniques (renommages, snapshots, lockfiles, générés).

Pas de paraphrase du diff, pas de rappel des guidelines, pas de titre superflu.
