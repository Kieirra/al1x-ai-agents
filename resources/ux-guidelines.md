# UX/UI Guidelines — Référence pour la rédaction de User Stories

Ce fichier contient les frameworks UX/UI à appliquer lors de la spécification d'interfaces. Il est lu par Lyra (scrum-master) pour enrichir les sections UX/UI des User Stories.

---

## Quick Check (à valider pour chaque écran/interaction)

- **Comprends-tu ?** — L'utilisateur comprend-il instantanément ce qu'il peut faire ?
- **Peux-tu agir ?** — L'action est-elle facile, motivante, et déclenchée par un signal clair ?
- **En ressors-tu positif ?** — L'expérience laisse-t-elle un ressenti positif ?

---

## Framework BMAP (Behavior MAP)

Chaque action utilisateur dépend de 3 facteurs. Les 3 doivent être réunis pour déclencher un comportement :

### M — Motivation

L'utilisateur veut-il faire cette action ? Leviers :

| Levier | Description |
|--------|-------------|
| Anticipation | Espoir d'un gain ou peur d'une perte |
| Sensation | Recherche de plaisir ou évitement de la douleur |
| Appartenance | Recherche d'acceptation ou évitement du rejet |

### A — Ability (Capacité)

L'utilisateur peut-il faire cette action facilement ? La capacité est limitée par le levier le plus faible :

| Levier | Question |
|--------|----------|
| Temps | Combien de temps ça prend ? |
| Argent | Combien ça coûte ? |
| Effort physique | C'est physiquement exigeant ? |
| Effort mental | C'est compliqué à comprendre ? |
| Familiarité | C'est un pattern connu ? |

### P — Prompt (Déclencheur)

Y a-t-il un signal clair qui pousse à agir au bon moment ?

- **Explicite** : bouton, notification, email, timer
- **Implicite** : association en mémoire (lieu, situation, émotion)

> Sans prompt, pas d'action. Même avec motivation et capacité élevées.

---

## Framework B.I.A.S.

Chaque interaction traverse 4 étapes cognitives (System 1). Utiliser ce framework pour identifier les failles d'une expérience.

### B — Block : Aider l'utilisateur à voir l'essentiel

Le cerveau bloque automatiquement ce qui est :
- **High-effort** : trop de texte, trop de choix (Hick's Law)
- **Non pertinent** : pas lié à l'objectif (attention sélective)
- **Redondant** : pattern déjà vu trop souvent (banner blindness)

Le cerveau remarque ce qui est :
- **Récent** : information vue juste avant (priming)
- **Confirmant** : aligné avec ses croyances (biais de confirmation)
- **Inattendu** : nouveau, drôle, personnalisé (pattern break)

**Checklist Block :**
- [ ] Pas d'éléments redondants ou non pertinents ?
- [ ] Pas d'apparence d'engagement lourd ?
- [ ] Pas de ressemblance avec une pub ?
- [ ] Y a-t-il un élément d'inattendu ou de personnalisation ?
- [ ] Le timing du prompt est-il aligné avec le comportement utilisateur ?

### I — Interpret : Aider l'utilisateur à comprendre rapidement

Principes clés :
1. **Familiarité** : réutiliser des patterns connus
2. **Charge cognitive** : réduire le bruit (moins de mots, visuels clairs)
3. **Bénéfices > Information** : formuler en termes de gains pour l'utilisateur
4. **Ancrage** : donner des points de comparaison
5. **Aversion à la perte** : montrer ce qui se passe en cas de non-action
6. **Découvrabilité** : les actions clés doivent ressortir visuellement
7. **Labor illusion** : montrer le travail fait en coulisse

**Checklist Interpret :**
- [ ] Charge cognitive minimale (visuels, texte concis) ?
- [ ] Patterns familiers utilisés ?
- [ ] Bénéfices clairement formulés (pas juste de l'info) ?
- [ ] Points d'ancrage/comparaison si éléments à évaluer ?
- [ ] Actions clés bien visibles ?
- [ ] Périodes d'attente transformées en opportunité ?

### A — Act : Aider l'utilisateur à atteindre son objectif

Réduire la friction :
1. **Supprimer les options** : moins de choix = décision plus rapide (Hick's Law)
2. **Defaults valides** : minimiser les saisies utilisateur
3. **Découper en petites étapes** : 3 petites étapes > 1 grosse
4. **Révélation progressive** : montrer les features graduellement

Nudges (utiliser avec parcimonie) :
1. **Social proof** : montrer ce que d'autres ont fait
2. **Curiosity gap** : créer un manque que l'utilisateur veut combler
3. **Rareté** : ressource limitée = désir accru

**Checklist Act :**
- [ ] Nombre de décisions par écran minimisé ?
- [ ] Options superflues supprimées ?
- [ ] Defaults pertinents pré-remplis ?
- [ ] Étapes découpées si trop complexes ?
- [ ] Features révélées progressivement ?

### S — Store : Rendre chaque interaction mémorable

Chaque interaction ajoute ou retire du "Psych" (énergie psychologique). Pour stocker du positif :

1. **Feedback clair** : chaque action doit montrer ce qui vient de se passer
2. **Réassurance** : confirmer que l'utilisateur fait le bon choix
3. **Caring** : montrer qu'on se soucie du résultat pour l'utilisateur
4. **Délice** : aller au-delà des attentes sur les petites interactions

**Checklist Store :**
- [ ] Feedback clair après chaque action ?
- [ ] Réassurance lors des actions importantes ?
- [ ] Signes de caring (intérêt pour le résultat utilisateur) ?
- [ ] Opportunités de délice sur les micro-interactions ?
- [ ] Relation positive (pas de tonalité agressive/manipulatrice) ?

---

## Psych Framework

Le Psych est "la barre de vie" de l'utilisateur. Chaque interaction ajoute ou retire du Psych.

**Psych = Motivation × Ability**

**Net Perceived Value = Motivation - Friction**

Règles :
- Si le Psych tombe trop bas → l'utilisateur abandonne
- La friction n'est pas toujours mauvaise : une friction alignée avec les motivations peut être positive (ex: personnalisation)
- Toujours motiver autant que réduire la friction

---

## Journey Mapping

Chaque parcours contient 5 types de moments :

| Type | Description |
|------|-------------|
| Peak | Point le plus haut de Psych |
| Pit | Point le plus bas de Psych |
| Jump | Le Psych augmente |
| Drop | Le Psych diminue |
| Transition | Début ou fin d'une étape clé |

### Peak-End Rule

Le cerveau évalue une expérience principalement sur :
- Le **Peak** (moment le plus intense)
- La **fin** de l'expérience
- Les **transitions** clés

> Ne pas essayer de combler tous les petits creux. Se concentrer sur élever le Peak, combler le Pit principal, et marquer les Transitions.

### 4 tactiques d'amélioration

1. **Marquer** les transitions (célébrer les étapes clés)
2. **Élever** le Peak (amplifier le meilleur moment)
3. **Combler** le Pit principal (corriger la plus grosse douleur)
4. **Réordonner** les étapes pour finir sur une note positive

---

## Éthique

### Regret Test

- Si l'utilisateur savait tout ce que l'équipe sait, prendrait-il la même décision ?
- Si un utilisateur était dans la salle pendant la discussion produit, dirait-on les mêmes choses ?

### Black Mirror Test

- Que se passerait-il si tout le monde utilisait cette feature "trop" ?
- Qui ou quoi disparaît si cette feature devient très populaire ?

### Principes humains

- [ ] Le produit aide-t-il à **gagner du temps** (pas à en perdre) ?
- [ ] Le produit **respecte-t-il l'attention** (pas de fausses notifications) ?
- [ ] Le produit **reflète-t-il des valeurs humaines** ?

### Vérifications supplémentaires

- [ ] **Rareté authentique** : la rareté affichée est-elle réelle ?
- [ ] **Defaults** : les valeurs par défaut sont-elles dans l'intérêt de l'utilisateur ?
- [ ] **Complétion** : l'utilisateur peut-il terminer et quitter proprement ?
- [ ] **Contrôle** : l'utilisateur contrôle-t-il ce qu'il reçoit et quand ?
