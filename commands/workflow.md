Affiche le workflow complet des agents et guide l'utilisateur vers la prochaine étape.

## Pipeline des agents

Le pipeline s'adapte à la technologie du projet :

### React / Tauri (avec frontend)
```
/scrum-master (Scala) → /dev-react (Rhea) ou /dev-tauri (Talia) → /dev-stories (Stella) → /reviewer (Reva)
                                                                                                  ↓
                                                                                        ✅ reviewed → merge
                                                                                        ❌ changes-requested → /fixer (Fira) → /reviewer (boucle)
```

### Godot (pas de stories)
```
/scrum-master (Scala) → /dev-godot (Gaia) → /reviewer (Reva)
                                                     ↓
                                           ✅ reviewed → merge
                                           ❌ changes-requested → /fixer (Fira) → /reviewer (boucle)
```

## Actions

1. Vérifie le nom de la branche courante via `git branch --show-current`
2. Cherche si une US existe dans `.claude/us/` correspondant à cette branche
3. Détecte la techno du projet :
   - `project.godot` présent → Godot (pas de stories)
   - `src-tauri/` présent → Tauri
   - `package.json` avec React → React
4. Si une US existe, lis son champ `Status` pour déterminer l'étape courante :
   - `ready` → Suggère de lancer `/dev-react`, `/dev-tauri` ou `/dev-godot` (selon la techno)
   - `in-progress` → L'implémentation est en cours, suggère de continuer avec l'agent dev approprié
   - `done` → **React/Tauri** : suggère `/dev-stories` puis `/reviewer`. **Godot** : suggère directement `/reviewer`
   - `stories-done` → Suggère de lancer `/reviewer`
   - `reviewed` → La US est terminée, suggère de merger
   - `changes-requested` → Suggère de lancer `/fixer` pour corriger les bloquants
   - `fixed` → Suggère de lancer `/reviewer` pour re-valider
5. Si aucune US n'existe, suggère de lancer `/scrum-master` pour en créer une

Affiche le résultat de manière claire et concise avec l'étape suivante recommandée.
