---
name: check-stories
description: Vérifie visuellement les stories Storybook via Playwright. Réutilise l'instance Storybook déjà lancée et capture toutes les stories dans une seule session Chromium. Utilisé automatiquement par $qa (Clea) quand Storybook est présent.
---

# Check Stories — Vérification visuelle Storybook

**Objectif : vitesse.** Un Storybook réutilisé, une seule session Chromium pour tout le lot, un minimum de captures lues.

## Contexte à récupérer

Exécute au démarrage :

- `git branch --show-current`
- `grep -q storybook package.json 2>/dev/null`
- `curl -s -o /dev/null -w "%{http_code}" http://localhost:6006`
- `npx playwright --version 2>/dev/null`

## Arguments

La demande peut contenir :
- Un chemin de fichier story : `$check-stories src/features/login/login-form.stories.tsx`
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

1. **Si la demande contient un chemin** : utiliser ce fichier directement
2. **Si invoqué par Clea ($qa)** : utiliser la liste des stories transmise dans le prompt
3. **Sinon** : détecter les stories modifiées via `git diff --name-only | grep '.stories.'`
4. **Parser les fichiers stories** pour extraire :
   - Le `title` du meta object
   - Les noms des exports (sauf `default`) — chaque export = une story
5. **Construire les IDs** : `title` avec `/` → `-`, lowercase + `--` + export lowercase
   - Exemple : `title: 'features/login/login-form'` + `export Error` → `features-login-login-form--error`
6. **Cibler serré** : uniquement les stories créées/modifiées. Au-delà de 5, ne garder que les plus décisives (états error/empty/loading + 1 nominal) et lister celles écartées dans le rapport.

### Étape 2 : Réutiliser Storybook

1. **Si le `curl` initial renvoie `200`** : une instance tourne déjà (probablement celle de l'utilisateur) — la réutiliser telle quelle, passer à l'étape 3.
2. **Sinon**, démarrer en background :
   ```bash
   npx storybook dev -p 6006 --no-open &
   ```
   puis polling `curl` sur `http://localhost:6006` (max 60s, intervalle 2s). Timeout → signaler l'erreur et arrêter.
3. **Ne jamais arrêter Storybook** — ni celui de l'utilisateur, ni celui démarré ici : le laisser tourner évite un démarrage à froid à la vérification suivante.
4. Vite sert les stories à chaud : après une modification de fichier, recharger la page suffit, aucun redémarrage n'est nécessaire.

### Étape 3 : Capturer tout le lot dans UNE session Chromium

**Jamais un `npx playwright screenshot` par story** : chaque appel relance Chromium à froid. Un seul script Node inline pour tout le lot :

```bash
mkdir -p tmp/screenshots
node -e '
let pw; try { pw = require("playwright") } catch { pw = require("@playwright/test") }
const ids = process.argv.slice(1)
;(async () => {
  const browser = await pw.chromium.launch()
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } })
  page.on("console", m => { if (m.type() === "error") console.log(`[console-error] ${m.text()}`) })
  for (const id of ids) {
    console.log(`--- ${id}`)
    await page.goto(`http://localhost:6006/iframe.html?id=${id}&viewMode=story`, { waitUntil: "networkidle" })
    await page.waitForTimeout(500)
    await page.screenshot({ path: `tmp/screenshots/${id}.png` })
  }
  await browser.close()
})()
' story-id-1 story-id-2 story-id-3
```

Viewport 1280×720, pas de full-page : inutile pour des composants. Un `[console-error]` dans la sortie = problème à rapporter pour la story courante, même si le screenshot semble correct.

### Étape 4 : Vérification visuelle

Inspecter les captures avec l'outil d'inspection d'images disponible : **uniquement celles des stories ciblées, une seule fois chacune, groupées dans le même lot**. Vérifier :
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

### Étape 6 : Fin de tâche

1. **Laisser Storybook tourner** et informer : `Storybook tourne sur http://localhost:6006 — screenshots dans tmp/screenshots/`
2. Ne rien nettoyer ni proposer de nettoyage interactif : `tmp/screenshots/` se supprime quand la QA est définitivement terminée, pas avant.

## Contraintes

- **Une seule session Chromium par lot** : script Node inline, jamais un appel Playwright par story, jamais de fichier script écrit dans le repo
- **Ne jamais arrêter Storybook**, qu'il ait été démarré ici ou par l'utilisateur
- **Jamais de modification de code** : ce skill vérifie, il ne corrige pas
- **Screenshots dans `tmp/screenshots/`** : dans le repo pour que l'utilisateur puisse les consulter
- **Timeout** : max 60s pour le démarrage de Storybook
- **Pas d'installation silencieuse** : toujours demander avant d'installer Playwright
