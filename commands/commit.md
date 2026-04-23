Crée un commit conventionnel basé sur les changements de la branche courante.

## Actions

1. Récupère le contexte :
   - `git branch --show-current` pour la branche
   - `git diff --staged --stat` et `git diff --staged` pour les changements stagés
   - `git diff --stat` et `git diff` pour les changements non stagés
   - `git log main..HEAD --oneline` pour les commits déjà faits sur la branche (si applicable)
   - Cherche une US dans `.claude/us/` correspondant à la branche (optionnel, pour enrichir le contexte)

2. Si rien n'est stagé, stage tous les fichiers modifiés/ajoutés pertinents (pas les .env, credentials, etc.)

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

   Exemples :
   - `feat: add composite field exploration to publication`
   - `feat(rules): add validation for nested conditions`
   - `fix(suggestions): regression when user closes suggestions`
   - `refactor(auth): extract token refresh logic`
   - `docs: update roadmap`
   - `chore: bump dependencies`

4. Crée le commit directement, **sans demander confirmation**. Affiche le message utilisé après coup.

   Si les changements couvrent plusieurs types (`feat` + `fix`, `refactor` + `docs`, etc.) OU plusieurs zones fonctionnelles distinctes : **découper en plusieurs commits** par défaut. Dans le doute, préférer plusieurs commits à un seul commit fourre-tout — mais sans tomber dans le micro-commit (un fichier = un commit est de l'over-engineering).

   Heuristique rapide :
   - 1 seul type + 1 zone cohérente → 1 commit.
   - Types différents OU zones indépendantes → plusieurs commits, groupés par intention.
   - Découper par `git add <fichiers par groupe>` puis `git commit` séquentiel.

## Règles

- **Pas de confirmation** : l'utilisateur a déjà demandé le commit en appelant `/commit`. Agir, ne pas redemander.
- **Un seul type** par commit. Plusieurs types → plusieurs commits, automatiquement.
- **Plusieurs commits en cas de doute** : si tu hésites entre 1 commit groupé et N commits séparés, choisir N. Ne pas sur-découper non plus (1 commit par fichier = non).
- Le scope est déduit du code modifié, pas inventé.
- La description reflète le **pourquoi** ou le **quoi** de manière concise, pas les détails techniques.
- Si une US existe, utilise-la pour comprendre le contexte, mais le message reste court et autonome.
- Ne pousse jamais automatiquement. Le commit reste local.
- **Pas de co-author** : ne jamais ajouter de ligne `Co-Authored-By` ou toute attribution à Claude/AI dans le message de commit.
