Liste toutes les User Stories présentes dans `.claude/us/`.

## Actions

1. Vérifie que le dossier `.claude/us/` existe. Si non, indique qu'aucune US n'a été créée et suggère de lancer `/architecte`.
2. Liste tous les fichiers `.md` dans `.claude/us/` (hors sous-dossiers)
3. Pour chaque fichier, lis les premières lignes pour extraire :
   - Le titre (ligne `# US-XXX: ...`)
   - Le statut (ligne `- **Status**: ...`)
   - La branche (ligne `- **Branche**: ...`)
4. Affiche un tableau récapitulatif des US actives :

```
📋 **US actives ({N})**

| Fichier | Titre | Branche | Status |
|---------|-------|---------|--------|
| ... | ... | ... | ... |
```

5. Indique la branche courante (`git branch --show-current`) et si une US correspond à cette branche.

6. Si le dossier `.claude/us/archive/` existe et contient des fichiers `.md`, afficher aussi :

```
📦 **US archivées ({M})**

| Fichier | Titre | Branche |
|---------|-------|---------|
| ... | ... | ... |
```

7. Si des US actives ont un statut `reviewed`, `merged`, ou `done`, suggérer : `💡 {X} US pourraient être archivées. Lance /archive-us pour nettoyer.`
