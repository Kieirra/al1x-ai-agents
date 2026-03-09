Crée une Pull Request via `gh pr create` sur la branche courante.

## Actions

1. Récupère le contexte :
   - `git branch --show-current` pour la branche
   - `git log main..HEAD --oneline` pour les commits de la branche
   - `git diff main...HEAD --stat` pour le résumé des changements
   - Vérifie si la branche est poussée sur le remote (`git ls-remote --heads origin <branche>`)

2. Si la branche n'est pas poussée, la pousse avec `git push -u origin <branche>`

3. Détecte si un template de PR existe dans le repo :
   - Utilise `find .github docs -iname "pull_request_template*" 2>/dev/null` pour trouver le template quelle que soit la casse
   - Si un template existe, le lit et le remplit en se basant sur les commits et les changements de la branche

4. Si aucun template n'existe :
   - Demande à l'utilisateur s'il y a un lien d'issue associé
   - Si oui et que l'issue est accessible (via `gh issue view`) : titre = `<type>: <titre synthétique de l'issue>`, body = `fix: {lien_issue}`
   - Si oui mais l'issue n'est pas accessible : titre déduit des commits, body = `fix: {lien_issue}`
   - Si non : propose un titre basé sur les commits et demande confirmation. **Body vide** (`""`) sauf si l'utilisateur demande explicitement une description.

   **Format du titre** : Conventional Commits — `<type>: <description courte en anglais>`
   - Types : `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
   - Le type est déduit du contenu de l'issue ou des commits
   - Exemples : `feat: add error message for number edition`, `fix: resolve login redirect loop`

5. Crée la PR avec `gh pr create` :
   ```
   gh pr create --title "<titre>" --body ""
   ```

6. Affiche l'URL de la PR créée.

## Règles

- **Utiliser `gh pr create`** : toujours utiliser la CLI GitHub, jamais d'API manuelle.
- **Pas de co-author** : ne jamais ajouter de ligne `Co-Authored-By` ou toute attribution à Claude/AI.
- **Pas de contenu superflu** : pas de badges, pas de génération automatique mentions, pas de signatures.
- **Demander en cas de doute** : si le titre ou le body n'est pas clair, demander confirmation à l'utilisateur avant de créer la PR.
- **Ne pas merger** : la PR est créée, c'est tout. Le merge est une décision de l'utilisateur.
