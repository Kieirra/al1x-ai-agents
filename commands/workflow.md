Affiche le workflow complet des agents et guide l'utilisateur vers la prochaine étape.

## Pipeline des agents

Le pipeline s'adapte à la technologie du projet :

### React / Tauri (avec frontend)
```
/architecte (Aline) → /dev (Alicia) → /refactor (Esquie) → /qa (Clea) → /reviewer (Verso)
                                                                                ↓
                                                                      ✅ reviewed → merge
                                                                      ❌ changes-requested → Monoco (sur demande) → /reviewer (boucle)
```

### Godot (pas de stories/tests)
```
/architecte (Aline) → /dev (Alicia) → /refactor (Esquie) → /reviewer (Verso)
                                                                    ↓
                                                          ✅ reviewed → merge
                                                          ❌ changes-requested → Monoco (sur demande) → /reviewer (boucle)
```

### Agents standalone
- `/uxui` (Renoir) : peut être appelé à tout moment pour un audit UX, brainstorm ou wireframe ASCII
- `/refactor` (Esquie) : peut être appelé à tout moment pour analyser le code et identifier des opportunités de refactoring

## Actions

1. Vérifie le nom de la branche courante via `git branch --show-current`
2. Cherche si une US existe dans `.claude/us/` correspondant à cette branche
3. Détecte la techno du projet :
   - `project.godot` présent → Godot
   - `src-tauri/` présent → Tauri
   - `package.json` avec React → React
4. Si une US existe, lis son champ `Status` pour déterminer l'étape courante :
   - `ready` → Suggère de lancer `/dev` (Alicia détectera la techno et dispatchera)
   - `in-progress` → L'implémentation est en cours, suggère de continuer avec `/dev`
   - `done` → Suggère de lancer `/refactor` (Esquie) pour simplifier le code avant la suite
   - `refactored` → **React/Tauri** : suggère `/qa` (Clea). **Godot** : suggère directement `/reviewer`
   - `stories-done` → Suggère de lancer `/reviewer` (Verso)
   - `reviewed` → La US est terminée, suggère de merger
   - `changes-requested` → Informe que l'utilisateur peut demander à Verso d'appeler Monoco pour fixer, puis relancer `/reviewer`
   - `fixed` → Suggère de lancer `/reviewer` pour re-valider
5. Si aucune US n'existe, suggère de lancer `/architecte` (Aline) pour en créer une

Affiche le résultat de manière claire et concise avec l'étape suivante recommandée.
