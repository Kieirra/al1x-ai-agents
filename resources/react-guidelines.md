# React / TypeScript — Guidelines techniques

Ce fichier contient les conventions et patterns à appliquer dans les projets React/TypeScript. Il est lu par Maelle (dev-react) avant chaque implémentation et par Verso (reviewer) pour valider le code.

---

## 1. Syntaxe des fonctions

**Toujours utiliser `const` + arrow function**, jamais le mot-clé `function`.

```tsx
// ❌ Mauvais
function handleClick() { ... }
function UserCard({ name }: UserCardProps) { ... }
export default function App() { ... }

// ✅ Bon
const handleClick = () => { ... };
const UserCard = ({ name }: UserCardProps) => { ... };
const App = () => { ... };
export default App;
```

**Exception** : les fonctions nommées dans les tests (`describe`, `it`, `test`) restent en arrow function passées en callback — pas de déclaration `function` non plus.

---

## 2. Exports

**Toujours utiliser `export const` directement**, jamais un `export {}` en fin de fichier.

```tsx
// ❌ Mauvais
const UserCard = () => { ... };
const formatName = (name: string) => { ... };
export { UserCard, formatName };

// ✅ Bon
export const UserCard = () => { ... };
export const formatName = (name: string) => { ... };
```

**Export default** : acceptable pour le composant principal d'un fichier, mais `export const` nommé est préféré.

---

## 3. TypeScript

### Ordre de préférence pour les définitions de types

`interface` > `enum` > `type`

- **`interface`** par défaut pour les objets et les contrats
- **`enum`** pour les unions de valeurs nommées (statuts, catégories, etc.)
- **`type`** uniquement si ça améliore la lisibilité par rapport à une interface ou un enum (union types, mapped types, types utilitaires)

```ts
// ✅ Bon : interface par défaut pour les objets
interface User {
  name: string;
  role: UserRole;
}

// ✅ Bon : enum pour les valeurs nommées
enum UserRole {
  Admin = 'admin',
  Editor = 'editor',
  Viewer = 'viewer',
}

// ✅ Bon : type uniquement quand ça apporte de la lisibilité
type ApiResponse<T> = SuccessResponse<T> | ErrorResponse;
type EventHandler = (event: MouseEvent) => void;

// ❌ Mauvais : type là où une interface suffit
type User = {
  name: string;
  role: UserRole;
};

// ❌ Mauvais : union de strings là où un enum est plus clair
type UserRole = 'admin' | 'editor' | 'viewer';
```

### Propriétés optionnelles

Préférer `prop?: Type` à `prop: Type | undefined`.

```ts
// ❌ Mauvais
interface User {
  name: string;
  avatar: string | undefined;
}

// ✅ Bon
interface User {
  name: string;
  avatar?: string;
}
```

---

## 4. Structure des composants (SRP)

### Règle : 1 composant = 1 fichier = 1 dossier

```
my-component/
├── my-component.tsx          # Le composant principal
├── my-component.helpers.ts   # Helpers (fonctions pures, formatage, calculs)
├── hooks/                    # Custom hooks du composant
│   └── use-my-logic.ts
├── sub-component/            # Sous-composants extraits
│   └── sub-component.tsx
└── my-component.stories.tsx  # Story Storybook (si applicable)
```

- Ne jamais mettre plusieurs composants dans le même fichier.
- Pas de fichier isolé : un composant React a toujours son propre dossier, même s'il ne contient qu'un fichier au départ.

### Seuil de taille : 200-250 lignes max

Un composant qui dépasse 200-250 lignes DOIT être découpé. Autres signes :
- Plus de 5-6 `useSelector` / accès au store
- Plus de 2-3 custom hooks
- Plusieurs blocs de logique indépendants dans le TSX

### Stratégie de découpage

1. **Extraire des composants fils** : identifier les blocs autonomes du TSX, chaque fils dans son propre dossier, connecté directement au store Redux via ses propres `useSelector`
2. **Extraire des custom hooks** : regrouper la logique liée (state + effets + handlers) dans un hook dédié (`hooks/use-my-logic.ts`)
3. **Extraire des helpers** : les fonctions pures (calculs, transformations, formatage) vont dans `my-component.helpers.ts`
4. **Le composant parent devient un assembleur** : il orchestre la structure, les fils et hooks gèrent leur propre logique

> Préférer un composant parent léger avec des fils autonomes connectés au store, plutôt qu'un composant parent lourd qui passe tout en props.

---

## 5. Commentaires minimalistes

Le code propre se documente lui-même. Ne pas ajouter de commentaires sauf nécessité absolue.

- **Pas de commentaires** pour expliquer ce que fait le code — le nommage et la structure doivent suffire
- **Pas de JSDoc/TSDoc** sur les fonctions internes — réserver aux API publiques de librairies
- **Commentaires autorisés** uniquement pour :
  - Regex complexes : expliquer le pattern
  - Workarounds / hacks : expliquer pourquoi (avec lien vers l'issue si applicable)
  - Logique métier non évidente : quand le "pourquoi" n'est pas déductible du code
  - `// TODO` avec contexte : quand un point technique est intentionnellement différé
- Si tu as besoin d'un commentaire pour expliquer un bloc de code, c'est un signe que ce bloc doit être extrait dans une fonction au nom explicite

---

## 6. Performances React

### Règle d'or : Mesurer avant d'optimiser

Ne jamais ajouter `useMemo`, `useCallback` ou `React.memo` "au cas où".

Ces optimisations ont un coût :
- Allocation mémoire pour le cache
- Comparaison des dépendances à chaque render
- Complexité du code accrue
- Faux sentiment de sécurité

### Quand utiliser useMemo

✅ **Utiliser** :
- Calculs coûteux (> 1ms) avec données volumineuses
- Objets/tableaux passés en dépendance à un composant mémoïsé
- Valeurs utilisées dans useEffect avec comparaison référentielle

❌ **Ne pas utiliser** :
- Calculs simples (filtres, maps sur petits tableaux)
- Valeurs primitives (strings, numbers, booleans)
- "Par précaution" ou "au cas où"

### Quand utiliser useCallback

✅ **Utiliser** :
- Callbacks passés à des composants mémoïsés (`React.memo`)
- Callbacks dans les dépendances d'un useEffect
- Callbacks passés à des listes virtualisées

❌ **Ne pas utiliser** :
- Handlers d'événements sur des éléments DOM natifs
- Callbacks passés à des composants non mémoïsés
- Fonctions appelées uniquement dans le composant

### Quand utiliser React.memo

✅ **Utiliser** :
- Composants lourds avec props stables
- Items de liste avec beaucoup d'éléments
- Composants qui re-render souvent avec les mêmes props

❌ **Ne pas utiliser** :
- Composants légers (quelques divs/spans)
- Composants dont les props changent à chaque render
- Par défaut sur tous les composants

---

## 7. Stratégies anti re-renders

### 1. Éviter les selectors/state à haut niveau

```tsx
// ❌ Mauvais : state global en haut de l'arbre
const App = () => {
  const user = useSelector(state => state.user);
  return <Layout><Content user={user} /></Layout>;
};

// ✅ Bon : Pattern Layout/{children}
const App = () => {
  return (
    <Layout>
      <Content />
    </Layout>
  );
};

const Content = () => {
  const user = useSelector(state => state.user);
  return <div>{user.name}</div>;
};
```

### 2. Initialiser isLoading à true

```tsx
// ❌ Mauvais : false → true = re-render inutile
const [isLoading, setIsLoading] = useState(false);

// ✅ Bon : commence à true, un seul changement
const [isLoading, setIsLoading] = useState(true);
```

### 3. shallowEqual avec useSelector

```tsx
import { shallowEqual, useSelector } from 'react-redux';

// ✅ Bon : re-render seulement si name ou email changent
const { name, email } = useSelector(
  state => ({
    name: state.user.name,
    email: state.user.email
  }),
  shallowEqual
);
```

### 4. Regrouper les selectors de chargement

```tsx
// ✅ Bon : 1 selector virtuel combiné
const isDataLoading = useSelector(
  state =>
    state.users.loading ||
    state.products.loading ||
    state.orders.loading
);
```

### 5. Outils de diagnostic

- **React DevTools Profiler** : identifier les composants lents
- **react-render-tracker** : https://github.com/lahmatiy/react-render-tracker
- **why-did-you-render** : détecter les re-renders évitables
