Affiche le workflow complet des agents et guide l'utilisateur vers la prochaine étape.

## Pipeline des agents

Le workflow standard suit cet ordre :

```
/scrum-master (Lyra) → /dev-react (Iris) ou /dev-tauri (Vesta) ou /dev-godot (Aria) → /dev-stories (Chroma) → /reviewer (Athena)
                                                                                              ↓
                                                                                    ✅ reviewed → merge
                                                                                    ❌ changes-requested → /fixer (Echo) → /reviewer (boucle)
```

## Actions

1. Vérifie le nom de la branche courante via `git branch --show-current`
2. Cherche si une US existe dans `.claude/us/` correspondant à cette branche
3. Si une US existe, lis son champ `Status` pour déterminer l'étape courante :
   - `ready` → Suggère de lancer `/dev-react`, `/dev-tauri` ou `/dev-godot`
   - `in-progress` → L'implémentation est en cours, suggère de continuer avec `/dev-react`, `/dev-tauri` ou `/dev-godot`
   - `done` → Suggère de lancer `/dev-stories` puis `/reviewer`
   - `stories-done` → Suggère de lancer `/reviewer`
   - `reviewed` → La US est terminée, suggère de merger
   - `changes-requested` → Suggère de lancer `/fixer` pour corriger les bloquants
   - `fixed` → Suggère de lancer `/reviewer` pour re-valider
4. Si aucune US n'existe, suggère de lancer `/scrum-master` pour en créer une

Affiche le résultat de manière claire et concise avec l'étape suivante recommandée.
