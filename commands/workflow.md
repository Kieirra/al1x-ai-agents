Affiche le workflow complet des agents et guide l'utilisateur vers la prochaine étape.

## Pipeline des agents

Le workflow standard suit cet ordre :

```
1. /scrum-master  →  Crée la User Story dans .claude/us/
2. /dev-react     →  Implémente la US (détectée automatiquement via le nom de branche)
3. /dev-stories   →  Crée les stories Storybook pour les composants créés/modifiés
4. /reviewer      →  Valide le code, les stories, et la conformité à la US
```

## Actions

1. Vérifie le nom de la branche courante via `git branch --show-current`
2. Cherche si une US existe dans `.claude/us/` correspondant à cette branche
3. Si une US existe, lis son champ `Status` pour déterminer l'étape courante :
   - `ready` → Suggère de lancer `/dev-react`
   - `in-progress` → L'implémentation est en cours, suggère de continuer avec `/dev-react`
   - `done` → Suggère de lancer `/dev-stories` puis `/reviewer`
   - `stories-done` → Suggère de lancer `/reviewer`
   - `reviewed` → La US est terminée, suggère de merger
4. Si aucune US n'existe, suggère de lancer `/scrum-master` pour en créer une

Affiche le résultat de manière claire et concise avec l'étape suivante recommandée.
