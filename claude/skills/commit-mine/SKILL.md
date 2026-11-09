---
name: commit-mine
description: Commite uniquement les fichiers modifiés par l'agent courant, en un seul commit conventionnel, sans toucher au reste.
disable-model-invocation: true
---
Commite **uniquement les fichiers que l'agent courant a créés, modifiés ou supprimés** dans cette conversation, en **un seul commit** conventionnel. Les autres changements (autres agents, utilisateur) restent intacts dans le working tree.

## Actions

1. Liste tes fichiers : ceux que tu as créés, modifiés ou supprimés dans cette conversation (outils d'édition ou commandes shell). Aucun : ne rien commiter et répondre « Aucun fichier modifié par cet agent. `/commit` commite tout. »

2. Récupère le contexte :
   - `git branch --show-current` pour la branche
   - `git status --short` pour l'ensemble des changements
   - `git diff -- <tes fichiers>` pour ton travail
   - Cherche une US dans `.claude/us/` correspondant à la branche (optionnel, pour enrichir le contexte)

3. Stage tes fichiers **en entier** : `git add -- <fichier1> <fichier2> …`. Un fichier qui contient aussi des modifications d'un autre agent ou de l'utilisateur est commité quand même, en entier (pas de staging partiel). Jamais `git add -A` ni `git add .`.

4. Analyse ton diff et rédige un message de commit **Conventional Commits** :

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

5. Crée **un seul commit** directement, **sans demander confirmation** : `git commit -m "<message>" -- <tes fichiers>`. Le `--` final limite le commit à ces chemins, même si d'autres fichiers sont déjà stagés.

6. Rapport, court :
   - le message utilisé
   - ⚠️ les fichiers commités qui contiennent aussi des changements que tu n'as pas faits, s'il y en a
   - les fichiers modifiés restés hors du commit (`git status --short`), s'il y en a

## Ne jamais détruire un changement

Plusieurs agents travaillent souvent en parallèle : un changement inattendu vient d'un autre agent ou de l'utilisateur, jamais d'une erreur à réparer.

- Commandes git autorisées : `git add` et `git commit`, plus les commandes de lecture (`status`, `diff`, `log`).
- Interdit : `git restore`, `git checkout -- <fichier>`, `git reset --hard`, `git stash`, `git clean`, `rm`, ou annuler une modification parce qu'elle semble hors sujet ou manuelle.
- Fichier sensible (`.env`, credentials, clés) : ne pas le stager, ne pas y toucher, le signaler dans le rapport.

## Règles

- **Pas de confirmation** : l'utilisateur a déjà demandé le commit en appelant `/commit-mine`. Agir, ne pas redemander.
- Le scope est déduit du code modifié, pas inventé.
- La description reflète le **pourquoi** ou le **quoi** de manière concise, pas les détails techniques.
- Si une US existe, utilise-la pour comprendre le contexte, mais le message reste court et autonome.
- Ne pousse jamais automatiquement. Le commit reste local.
- **Pas de co-author** : ne jamais ajouter de ligne `Co-Authored-By` ou toute attribution à Claude/AI dans le message de commit.
