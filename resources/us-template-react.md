<!-- GUIDELINES_TOKEN: TPL_REACT_v1 -->

# Template US — React

> **Preuve de lecture obligatoire** : tout agent qui charge ce fichier DOIT inclure le token `TPL_REACT_v1` dans son premier message utilisateur (format : `📚 Lu : us-template-react.md [TPL_REACT_v1]`). Sans token = lecture non confirmée.

Ce fichier contient les sections techniques et UX spécifiques aux projets React. Il est lu par Aline (architecte) après détection de la techno.

---

## Spécifications techniques

### Fichiers à créer

Respecter strictement l'arborescence de `react-guidelines.md` §4 : 1 composant = 1 dossier, helpers dans `{composant}.helpers.ts`, hooks dans `hooks/`, sous-composants dans leur propre sous-dossier.

```
components/my-feature/
├── my-feature.tsx
├── my-feature.helpers.ts
├── hooks/
│   └── use-my-feature.ts
└── my-sub-component/
    ├── my-sub-component.tsx
    └── my-sub-component.helpers.ts
```

| Fichier | Description |
|---------|-------------|
| `src/components/[nom]/[nom].tsx` | Composant principal |
| `src/components/[nom]/[nom].helpers.ts` | Fonctions pures, records, constantes |
| `src/components/[nom]/hooks/use-[nom].ts` | Hook du composant (si logique à extraire) |
| `src/components/[nom]/[sous-composant]/[sous-composant].tsx` | Sous-composant (dans son propre sous-dossier) |
| `src/components/[nom]/[nom].test.tsx` | Tests unitaires |

> **Règle stricte** : jamais deux `.tsx` de composants dans le même dossier. Les helpers d'un composant (fonctions pures, records statiques, constantes) vont TOUJOURS dans `{composant}.helpers.ts`, jamais dans le `.tsx`. Pas de `index.ts` / `index.tsx` qui ré-exporte (pas de barrel file).

### Fichiers à modifier

| Fichier | Modification |
|---------|--------------|
| `src/path/to/file.tsx:XX` | [Description de la modification] |

### Composants existants à réutiliser

| Composant | Chemin | Usage |
|-----------|--------|-------|
| `Button` | `src/components/ui/Button` | CTA principal |

### Types TypeScript

```typescript
interface [NomInterface] {
  [propriété]: [type]; // [description]
}
```

### State management

```typescript
// Si Redux : structure du slice ou selector à créer/modifier
// Chemin: src/store/slices/[nom].ts
```

### API / Services

```typescript
// Endpoint, méthode, payload, response
// Service existant: src/services/[nom].ts
```

### Props du composant principal

```typescript
interface [Composant]Props {
  [prop]: [type]; // [description] - [requis/optionnel]
}
```

---

## Spécifications UX/UI

### Layout

```
┌─────────────────────────────────┐
│  [Header si applicable]          │
├─────────────────────────────────┤
│                                  │
│  [Description du layout]         │
│  [Position des éléments]         │
│                                  │
├─────────────────────────────────┤
│  [Actions/Boutons]               │
└─────────────────────────────────┘
```

### Composants UI à utiliser

| Élément | Composant | Variante/Props |
|---------|-----------|----------------|
| Bouton principal | `Button` | `variant="primary"` |
| Champ texte | `TextField` | `size="medium"` |

### Textes et labels (i18n)

| Clé i18n | Texte FR | Texte EN |
|----------|----------|----------|
| `feature.title` | "Titre" | "Title" |
| `feature.button.submit` | "Valider" | "Submit" |

### Comportements UX

- **Feedback visuel** : [Description — cf. B.I.A.S. Store : feedback clair après chaque action]
- **Réassurance** : [Comment confirmer que l'utilisateur fait le bon choix]
- **Animations** : [Si applicable]
- **Accessibilité** : [Aria labels, focus management]

### Analyse UX (frameworks appliqués)

#### Quick Check
- [ ] **Comprends-tu ?** — L'utilisateur comprend-il instantanément ce qu'il peut faire ?
- [ ] **Peux-tu agir ?** — L'action est-elle facile et déclenchée par un signal clair ?
- [ ] **En ressors-tu positif ?** — L'expérience laisse-t-elle un ressenti positif ?

#### BMAP
- **Motivation** : [Quel levier ? Anticipation/Sensation/Appartenance]
- **Ability** : [Quel est le levier le plus faible ? Temps/Effort mental/Familiarité]
- **Prompt** : [Quel déclencheur ? Explicite (bouton, notification) ou implicite]

#### B.I.A.S.
- **Block** : [Éléments superflus, redondants ou high-effort à éliminer ?]
- **Interpret** : [Bénéfices clairs ? Patterns familiers ? Charge cognitive réduite ?]
- **Act** : [Nombre de décisions minimisé ? Defaults valides ? Étapes découpées ?]
- **Store** : [Feedback, réassurance, caring, délice ?]

---

## Données de test / Mocks

```typescript
// Exemple de données pour les tests et le développement
const mockData = {
  // Structure exacte des données attendues
};

// Cas nominal
const successResponse = { ... };

// Cas d'erreur
const errorResponse = { ... };
```
