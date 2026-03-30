---
name: check-stories
description: Vérifie visuellement les stories Storybook via Playwright CLI. Démarre Storybook si nécessaire, navigue sur chaque story, capture des screenshots. Utilisé automatiquement par @qa (Clea) quand Storybook est présent.
allowed-tools: Read, Grep, Glob, Bash
context: fork
agent: general-purpose
---

# Check Stories — Vérification visuelle Storybook via Playwright CLI

## Contexte dynamique

- Branche : !`git branch --show-current`
- Storybook installé : !`grep -q storybook package.json 2>/dev/null && echo "oui" || echo "non"`
- Playwright installé : !`npx playwright --version 2>/dev/null || echo "non installé"`

## Arguments

`$ARGUMENTS` peut être :
- Un chemin de fichier story : `/check-stories src/features/login/login-form.stories.tsx`
- Rien : détecte automatiquement les stories modifiées via `git diff`

## Prérequis

Vérifier avant de lancer :

1. **Storybook installé** dans `package.json`
   - Si absent : arrêter avec message "Storybook n'est pas installé dans ce projet."

2. **Playwright installé** : tester `npx playwright --version`
   - Si absent, proposer :
   ```
   Playwright n'est pas installé. Voulez-vous l'ajouter ?
   A) Oui, installer @playwright/test — recommandé
   B) Non, skip la vérification visuelle
   ```
   - Si A : `npm install -D @playwright/test && npx playwright install chromium`

## Workflow

### Étape 1 : Identifier les stories cibles

1. **Si `$ARGUMENTS` contient un chemin** : utiliser ce fichier directement
2. **Si invoqué par Clea (@qa)** : utiliser la liste des stories transmise dans le prompt
3. **Sinon** : détecter les stories modifiées via `git diff --name-only | grep '.stories.'`
4. **Parser les fichiers stories** pour extraire :
   - Le `title` du meta object
   - Les noms des exports (sauf `default`) — chaque export = une story
5. **Construire les IDs** : `title` avec `/` → `-`, lowercase + `--` + export lowercase
   - Exemple : `title: 'features/login/login-form'` + `export Error` → `features-login-login-form--error`

### Étape 2 : Démarrer Storybook

1. **Vérifier si Storybook tourne** : `curl -s -o /dev/null -w "%{http_code}" http://localhost:6006`
2. **Si non** : démarrer en background :
   ```bash
   npx storybook dev -p 6006 --no-open &
   ```
3. **Attendre que le serveur soit prêt** : polling `curl` sur `http://localhost:6006` (max 60s, intervalle 2s)
4. **Si timeout** : signaler l'erreur et arrêter

### Étape 3 : Capture des screenshots via Playwright CLI

**Utiliser uniquement le CLI Playwright, jamais en mode librairie.**

Pour chaque story, exécuter :

```bash
mkdir -p tmp/screenshots
npx playwright screenshot \
  --browser chromium \
  --full-page \
  --wait-for-timeout 2000 \
  "http://localhost:6006/iframe.html?id={story-id}&viewMode=story" \
  "tmp/screenshots/{story-id}.png"
```

**Options utiles du CLI :**
- `--full-page` : capture toute la page, pas juste le viewport
- `--wait-for-timeout 2000` : attend 2s que le rendu se stabilise
- `--viewport-size 1280,720` : taille du viewport (défaut)

### Étape 4 : Vérification visuelle

Après capture, **lire chaque screenshot** avec le Read tool (Claude est multimodal) et vérifier :
- Le composant se rend correctement (pas de page blanche, pas d'erreur React)
- Les états visuels correspondent à ce qui est attendu (loading spinner, message d'erreur, état vide, etc.)
- Pas de texte tronqué, de layout cassé ou d'élément manquant

### Étape 5 : Rapport

```markdown
## Vérification visuelle Storybook

| Story | Status | Observation | Screenshot |
|-------|--------|-------------|------------|
| Default | OK | Rendu correct | `tmp/screenshots/{id}.png` |
| Error | OK | Message d'erreur affiché | `tmp/screenshots/{id}.png` |
| Loading | PROBLEME | Spinner absent | `tmp/screenshots/{id}.png` |

### Résumé
- **{X}/{Y} stories OK**
- **{Z} problèmes détectés** (si applicable)
```

**Si invoqué par Clea** : retourner le rapport pour inclusion dans le rapport QA global.

### Étape 6 : Nettoyage

1. **Ne PAS arrêter Storybook** (l'utilisateur peut vouloir vérifier manuellement)
2. Informer : `Storybook tourne sur http://localhost:6006 — screenshots dans tmp/screenshots/`
3. **Proposer le nettoyage** :
   ```
   Les screenshots sont dans tmp/screenshots/. Tu peux les consulter.
   Veux-tu que je supprime le dossier tmp/screenshots/ ?
   A) Oui, supprimer
   B) Non, je veux les garder pour l'instant
   ```

## Contraintes

- **Playwright CLI uniquement** : jamais de script TypeScript, jamais en mode librairie
- **Jamais de modification de code** : ce skill vérifie, il ne corrige pas
- **Screenshots dans `tmp/screenshots/`** : dans le repo pour que l'utilisateur puisse les consulter
- **Timeout** : max 60s pour le démarrage de Storybook
- **Pas d'installation silencieuse** : toujours demander avant d'installer Playwright
