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

4. Montre le message proposé à l'utilisateur et demande confirmation avant de committer.

5. Une fois confirmé, crée le commit.

## Règles

- **Un seul type** par commit. Si les changements couvrent plusieurs types, propose de faire plusieurs commits séparés.
- Le scope est déduit du code modifié, pas inventé.
- La description reflète le **pourquoi** ou le **quoi** de manière concise, pas les détails techniques.
- Si une US existe, utilise-la pour comprendre le contexte, mais le message reste court et autonome.
- Ne pousse jamais automatiquement. Le commit reste local.
- **Pas de co-author** : ne jamais ajouter de ligne `Co-Authored-By` ou toute attribution à Claude/AI dans le message de commit.
