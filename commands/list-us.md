Liste toutes les User Stories présentes dans `.claude/us/`.

## Actions

1. Vérifie que le dossier `.claude/us/` existe. Si non, indique qu'aucune US n'a été créée et suggère de lancer `/scrum-master`.
2. Liste tous les fichiers `.md` dans `.claude/us/`
3. Pour chaque fichier, lis les premières lignes pour extraire :
   - Le titre (ligne `# US-XXX: ...`)
   - Le statut (ligne `- **Status**: ...`)
   - La branche (ligne `- **Branche**: ...`)
4. Affiche un tableau récapitulatif :

```
| Fichier | Titre | Branche | Status |
|---------|-------|---------|--------|
| ... | ... | ... | ... |
```

5. Indique la branche courante (`git branch --show-current`) et si une US correspond à cette branche.
