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

6. **Référence issue (format exact, obligatoire)** : chaque US couverte par la PR est référencée par **une ligne au format exact `fix: <lien de l'issue>`**. Une US = une ligne. Plusieurs US = une ligne par US, dans l'ordre :
   ```
   fix: https://github.com/<owner>/<repo>/issues/<numéro>
   fix: https://github.com/<owner>/<repo>/issues/<numéro>
   ```
   - Après `fix: `, **le lien de l'issue et rien d'autre**. JAMAIS le titre de l'US, JAMAIS son identifiant `US-XXX`, JAMAIS une reformulation.
   - Préfixe littéral `fix: ` (même pour une US de type `feat`), aucune variation.
   - **Lien inconnu** : le demander à l'utilisateur (`Lien de l'issue pour <US> ?`) et attendre sa réponse. Ne jamais deviner un lien, ne jamais le déduire du numéro d'US, ne jamais se rabattre silencieusement sur le titre.
   - **Dernier recours, uniquement si l'utilisateur a répondu explicitement qu'il n'y a pas d'issue** : `fix: <titre de l'US>`.

7. **Body** — construit à partir des points 4 et 6, rien d'autre :

   **Cas A : Un template existe (point 4)** — priorité absolue
   - Remplir le template avec les infos disponibles (US, commits).
   - Placer le(s) ligne(s) `fix: <lien>` dans la section du template prévue pour les US/issues liées ; à défaut de section dédiée, les ajouter en tête du body. Le bloc `fix:` ne doit jamais disparaître.

   **Cas B : Aucun template (les 4 chemins vérifiés)**
   - Si une ou des US existent : body = le bloc de lignes `fix: <lien>` (point 6), **strictement ces lignes, aucune autre ligne**.
   - Sinon : body vide (`""`).

8. Crée la PR : `gh pr create --title "<titre>" --body-file <fichier>` (utiliser `--body-file` pour préserver les sauts de ligne du template et du bloc multi-US ; `--body` seulement pour un body sur une seule ligne).

9. Affiche l'URL de la PR créée.

## Règles

- **Template = priorité absolue** : si un template existe (point 4), il est rempli et utilisé, sans exception. Sauter la détection ou l'ignorer est une erreur.
- **Nomenclature `fix: <lien>` stricte** : préfixe `fix: ` littéral suivi du seul lien de l'issue, une ligne par US. Ne jamais fusionner plusieurs US sur une ligne, ni omettre le préfixe, ni remplacer le lien par un titre ou un `US-XXX`.
- **Pas de mots-clés GitHub** : JAMAIS de ligne `Fixes`, `Closes`, `Resolves`, `Refs` ou équivalent. Le lien apparaît une seule fois, dans la ligne `fix: `.
- **Body minimaliste (Cas B)** : JAMAIS de description, JAMAIS de résumé des changements, JAMAIS de liste de fichiers modifiés, JAMAIS de bullet points explicatifs, JAMAIS de ligne ajoutée sous le bloc `fix:`. Le body contient uniquement ce qui est décrit au point 7.
- **Pas de co-author** : ne jamais ajouter de ligne `Co-Authored-By` ou toute attribution à Claude/AI.
- **Pas de contenu superflu** : pas de badges, pas de signatures, pas de "Generated with", pas de "Summary", pas de "Test plan" (sauf si le template en contient explicitement).
- **Utiliser `gh pr create`** : toujours utiliser la CLI GitHub.
- **Demander en cas de doute** : si le titre n'est pas clair, demander confirmation avant de créer.
- **Ne pas merger** : la PR est créée, c'est tout.

## Exemple (Cas B, une US liée à l'issue 6803)

Body attendu :

```
fix: https://github.com/Product-Live/product-improvements/issues/6803
```

Bodies interdits :

```
fix: US-6803: Éditer un champ standard depuis le menu colonne   ← titre au lieu du lien

fix: https://github.com/Product-Live/product-improvements/issues/6803
Fixes https://github.com/Product-Live/product-improvements/issues/6803   ← ligne en trop
```
