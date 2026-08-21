---
name: explain
description: Explique pédagogiquement un morceau de code ou un concept, en un paragraphe max (1 à 3 phrases).
---

Explique le sujet fourni en argument (un morceau de code, un fichier, une fonction ou un concept) de manière pédagogique.

## Recherche du contexte

Dans l'ordre, s'arrêter dès que le contexte suffit :

1. **PR en cours** : si la branche courante a une PR (`gh pr view`), chercher le sujet dans le diff de la PR (`gh pr diff`).
2. **Changement en cours** : sinon, chercher dans les modifications locales (`git diff HEAD` + fichiers non suivis).
3. **Général** : sinon, chercher dans la codebase (recherches ciblées).

En complément, si `.claude/us/` existe et qu'une US correspond au sujet ou à la branche courante, la lire pour comprendre l'intention fonctionnelle derrière le code.

## Réponse

- **Un seul paragraphe de 1 à 3 phrases.** Pas de titres, pas de listes, pas de blocs de code.
- Aller à l'essentiel : ce que fait le code et pourquoi, pas comment ligne par ligne.
- Langage simple et lisible, comme si on expliquait à un collègue qui découvre le sujet. Les termes techniques indispensables restent, le jargon superflu dégage.
- Si l'US éclaire le pourquoi, l'intégrer naturellement dans la phrase (sans citer le fichier).
- Si le sujet est introuvable, le dire en une phrase et demander une précision.
