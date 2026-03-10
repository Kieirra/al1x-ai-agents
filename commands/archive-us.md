Archive les User Stories terminées en les déplaçant dans `.claude/us/archive/`.

## Actions

1. Vérifie que le dossier `.claude/us/` existe. Si non, indique qu'aucune US n'a été créée.
2. Liste tous les fichiers `.md` dans `.claude/us/` (PAS dans `archive/`)
3. Pour chaque fichier, lis les premières lignes pour extraire :
   - Le titre (ligne `# US-XXX: ...`)
   - Le statut (ligne `- **Status**: ...`)
   - La branche (ligne `- **Branche**: ...`)
4. Identifie les US archivables : celles avec un statut `reviewed`, `merged`, `done`, ou `archived`
5. Affiche les US trouvées en mode interactif :

**Si des US archivables sont trouvées :**

```
**US archivables ({N} trouvées) :**

| # | Fichier | Titre | Status |
|---|---------|-------|--------|
| 1 | ... | ... | reviewed |
| 2 | ... | ... | done |

A) Tout archiver — déplace les {N} US dans archive/
B) Choisir — je sélectionne lesquelles archiver
C) Annuler
```

**Si l'utilisateur choisit B :** présenter chaque US une par une en mode interactif (1/N) avec options Archiver/Garder.

6. Pour chaque US à archiver :
   - Créer le dossier `.claude/us/archive/` s'il n'existe pas
   - Déplacer le fichier de `.claude/us/` vers `.claude/us/archive/`
   - Mettre à jour le statut dans le fichier vers `archived` (si ce n'est pas déjà le cas)

7. Afficher le récap :

```
**Archivage terminé :**
📦 {X} US archivées dans `.claude/us/archive/`
📋 {Y} US actives restantes dans `.claude/us/`
```

**Si aucune US archivable n'est trouvée :**

```
Aucune US à archiver (toutes en statut actif).
💡 Les US sont archivables quand leur statut est : reviewed, merged, done, ou archived.
```
