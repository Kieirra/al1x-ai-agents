---
name: commit
description: Commite tous les changements courants en un seul commit conventionnel.
---

Commite **tous** les changements de la branche courante en **un seul commit** conventionnel.

## Actions

1. Récupère le contexte :
   - `git branch --show-current` pour la branche
   - `git status --short`, `git diff --staged` et `git diff` pour les changements
   - `git log main..HEAD --oneline` pour les commits déjà faits sur la branche (si applicable)
   - Cherche une US dans `.claude/us/` correspondant à la branche (optionnel, pour enrichir le contexte)

2. Stage tous les fichiers modifiés, ajoutés et supprimés (`git add -A`), sauf les fichiers sensibles (cf. ci-dessous).

3. Analyse les changements et rédige un message de commit **Conventional Commits** :

   Format : `<type>(<scope>): <description courte>`

   **Types :**
   - `feat` : nouvelle fonctionnalité
   - `fix` : correction de bug
   - `docs` : documentation uniquement
   - `style` : formatage, pas de changement de logique
   - `refactor` : ni feat ni fix, restructuration
   - `test` : ajout ou correction de tests
   - `chore` : maintenance, config, dépendances

   **Scope** (optionnel) : module, composant ou zone impactée. Omis si le changement est transversal.

   **Description** : impérative, minuscule, sans point final, max 72 caractères. En anglais.

   **Plusieurs changements** : garder le type dominant et lister les autres changements dans le corps, une puce d'une ligne chacun.

   Exemples :
   - `feat: add composite field exploration to publication`
   - `feat(rules): add validation for nested conditions`
   - `fix(suggestions): regression when user closes suggestions`
   - `refactor(auth): extract token refresh logic`
   - `docs: update roadmap`
   - `chore: bump dependencies`

4. Crée **un seul commit** directement, **sans demander confirmation**. Affiche le message utilisé après coup.

   Plusieurs commits uniquement si l'utilisateur le demande explicitement (ex : « $commit en 2 commits : … »). Pour ne commiter que le travail de l'agent courant : `$commit-mine`.

## Ne jamais détruire un changement

Plusieurs agents travaillent souvent en parallèle : un changement inattendu vient d'un autre agent ou de l'utilisateur, jamais d'une erreur à réparer.

- Commandes git autorisées : `git add` et `git commit`, plus les commandes de lecture (`status`, `diff`, `log`).
- Interdit : `git restore`, `git checkout -- <fichier>`, `git reset --hard`, `git stash`, `git clean`, `rm`, ou annuler une modification parce qu'elle semble hors sujet ou manuelle.
- Fichier sensible (`.env`, credentials, clés) : ne pas le stager, ne pas y toucher, le signaler dans le rapport.

## Règles

- **Pas de confirmation** : l'utilisateur a déjà demandé le commit en appelant `$commit`. Agir, ne pas redemander.
- Le scope est déduit du code modifié, pas inventé.
- La description reflète le **pourquoi** ou le **quoi** de manière concise, pas les détails techniques.
- Si une US existe, utilise-la pour comprendre le contexte, mais le message reste court et autonome.
- Ne pousse jamais automatiquement. Le commit reste local.
- **Pas de co-author** : ne jamais ajouter de ligne `Co-Authored-By` ou toute attribution à Claude/AI dans le message de commit.
