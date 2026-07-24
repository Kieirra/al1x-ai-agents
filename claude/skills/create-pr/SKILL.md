---
name: create-pr
description: Crée une Pull Request minimaliste pour la branche courante.
disable-model-invocation: true
---
Crée une Pull Request via `gh pr create` sur la branche courante.

## Actions

1. Récupère le contexte :
   - `git branch --show-current` pour la branche
   - `git log main..HEAD --oneline` pour les commits de la branche
   - Vérifie si la branche est poussée sur le remote (`git ls-remote --heads origin <branche>`)

2. Si la branche n'est pas poussée, la pousse avec `git push -u origin <branche>`

3. Cherche la ou les US liée(s) à la branche dans `.claude/us/` (les `/` du nom de branche remplacés par `-`). Il peut y en avoir plusieurs.

4. **Détection du template PR (ÉTAPE OBLIGATOIRE, jamais sautée)** : chercher un template GitHub dans cet ordre, s'arrêter au premier trouvé :
   - `.github/PULL_REQUEST_TEMPLATE.md` puis `.github/pull_request_template.md`
   - `.github/PULL_REQUEST_TEMPLATE/*.md` (dossier multi-templates → choisir le plus pertinent)
   - `PULL_REQUEST_TEMPLATE.md` puis `pull_request_template.md` (racine)
   - `docs/PULL_REQUEST_TEMPLATE.md` puis `docs/pull_request_template.md`

   Un template trouvé est **toujours** utilisé — jamais ignoré, jamais remplacé par un body ad hoc. Ne conclure « pas de template » qu'après avoir vérifié TOUS ces chemins.

5. **Titre** : format Conventional Commits — `<type>: <description courte en anglais>`
   - Types : `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
   - Le type est déduit des commits ou du contenu de l'US
   - Exemples : `feat: add login form`, `fix: resolve redirect loop`

6. **Nomenclature US (format exact, obligatoire)** : chaque US couverte par la PR est référencée par **une ligne au format exact `fix: <titre de l'US>`**. Une US = une ligne. Plusieurs US = une ligne par US, dans l'ordre :
   ```
   fix: <titre US 1>
   fix: <titre US 2>
   ```
   - Toujours le préfixe littéral `fix: ` (même pour une US de type `feat`), jamais de variation ni de reformulation.
   - Un lien d'issue fourni par l'utilisateur suit la même règle : `fix: <lien_issue>`.

7. **Body** — construit à partir des points 4 et 6, rien d'autre :

   **Cas A : Un template existe (point 4)**
   - Remplir le template avec les infos disponibles (US, commits).
   - Placer le(s) ligne(s) `fix: <US>` dans la section du template prévue pour les US/issues liées ; à défaut de section dédiée, les ajouter en tête du body. Le bloc `fix:` ne doit jamais disparaître.

   **Cas B : Aucun template (les 4 chemins vérifiés)**
   - Si une ou des US existent : body = le bloc de lignes `fix: <US>` (point 6).
   - Sinon : body vide (`""`).

8. Crée la PR : `gh pr create --title "<titre>" --body-file <fichier>` (utiliser `--body-file` pour préserver les sauts de ligne du template et du bloc multi-US ; `--body` seulement pour un body sur une seule ligne).

9. Affiche l'URL de la PR créée.

## Règles

- **Template = priorité absolue** : si un template existe (point 4), il est rempli et utilisé, sans exception. Sauter la détection ou l'ignorer est une erreur.
- **Nomenclature `fix: <US>` stricte** : format exact, préfixe `fix: ` littéral, une ligne par US. Ne jamais fusionner plusieurs US sur une ligne ni omettre le préfixe.
- **Body minimaliste (Cas B)** : JAMAIS de description, JAMAIS de résumé des changements, JAMAIS de liste de fichiers modifiés, JAMAIS de bullet points explicatifs. Le body contient uniquement ce qui est décrit au point 7.
- **Pas de co-author** : ne jamais ajouter de ligne `Co-Authored-By` ou toute attribution à Claude/AI.
- **Pas de contenu superflu** : pas de badges, pas de signatures, pas de "Generated with", pas de "Summary", pas de "Test plan" (sauf si le template en contient explicitement).
- **Utiliser `gh pr create`** : toujours utiliser la CLI GitHub.
- **Demander en cas de doute** : si le titre n'est pas clair, demander confirmation avant de créer.
- **Ne pas merger** : la PR est créée, c'est tout.
