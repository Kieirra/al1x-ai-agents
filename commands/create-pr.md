Crée une Pull Request via `gh pr create` sur la branche courante.

## Actions

1. Récupère le contexte :
   - `git branch --show-current` pour la branche
   - `git log main..HEAD --oneline` pour les commits de la branche
   - Vérifie si la branche est poussée sur le remote (`git ls-remote --heads origin <branche>`)

2. Si la branche n'est pas poussée, la pousse avec `git push -u origin <branche>`

3. Cherche l'US liée à la branche dans `.claude/us/` (les `/` du nom de branche remplacés par `-`)

4. **Titre** : format Conventional Commits — `<type>: <description courte en anglais>`
   - Types : `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
   - Le type est déduit des commits ou du contenu de l'US
   - Exemples : `feat: add login form`, `fix: resolve redirect loop`

5. **Body** — deux cas, rien d'autre :

   **Cas A : Un template de PR existe** (chercher dans `.github/` et `docs/`)
   - Lire le template et le remplir avec les infos disponibles (US, commits)

   **Cas B : Pas de template**
   - Si une US existe : body = `fix: <titre de l'US>`
   - Si un lien d'issue est fourni par l'utilisateur : body = `fix: <lien_issue>`
   - Sinon : body vide (`""`)

6. Crée la PR : `gh pr create --title "<titre>" --body "<body>"`

7. Affiche l'URL de la PR créée.

## Règles

- **Body minimaliste** : JAMAIS de description, JAMAIS de résumé des changements, JAMAIS de liste de fichiers modifiés, JAMAIS de bullet points explicatifs. Le body contient uniquement ce qui est décrit au point 5.
- **Pas de co-author** : ne jamais ajouter de ligne `Co-Authored-By` ou toute attribution à Claude/AI.
- **Pas de contenu superflu** : pas de badges, pas de signatures, pas de "Generated with", pas de "Summary", pas de "Test plan".
- **Utiliser `gh pr create`** : toujours utiliser la CLI GitHub.
- **Demander en cas de doute** : si le titre n'est pas clair, demander confirmation avant de créer.
- **Ne pas merger** : la PR est créée, c'est tout.
