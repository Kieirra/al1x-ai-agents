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

### Type Guards : préférer un helper à une condition complexe

Quand une vérification de type nécessite plus qu'un simple `!= null`, **extraire un type guard** plutôt qu'écrire une condition inline complexe.

```ts
// ❌ Mauvais : condition inline complexe et non réutilisable
if (item && 'id' in item && typeof item.id === 'string' && item.type === 'product') {
  handleProduct(item);
}

// ❌ Mauvais : cast avec `as` pour contourner le typage
const product = item as Product;

// ✅ Bon : type guard helper explicite et réutilisable
const isProduct = (item: unknown): item is Product =>
  item != null &&
  typeof item === 'object' &&
  'id' in item &&
  typeof (item as Record<string, unknown>).id === 'string' &&
  (item as Record<string, unknown>).type === 'product';

if (isProduct(item)) {
  handleProduct(item); // item est typé Product ici
}
```

**Règles** :
- **Toujours** extraire un type guard dès que la condition vérifie plus d'une propriété
- Nommer le guard `is{TypeName}` (ex: `isProduct`, `isApiError`, `isLoadedState`)
- Placer les guards dans le fichier `.helpers.ts` du composant, ou dans un fichier `types/guards.ts` partagé si réutilisé ailleurs
- Préférer `unknown` + type guard à `any` + cast — jamais de `as` pour contourner le typage
- Les discriminated unions avec un champ `type` ou `kind` sont la meilleure approche quand on contrôle les types

```ts
// ✅ Excellent : discriminated union (pas besoin de type guard custom)
interface ProductItem {
  kind: 'product';
  id: string;
  price: number;
}

interface ServiceItem {
  kind: 'service';
  id: string;
  duration: number;
}

type Item = ProductItem | ServiceItem;

// Le switch/if sur `kind` suffit, TypeScript narrow automatiquement
const getLabel = (item: Item): string => {
  switch (item.kind) {
    case 'product': return `${item.price}€`;  // item est ProductItem
    case 'service': return `${item.duration}h`; // item est ServiceItem
  }
};
```

### Propriétés et paramètres optionnels

**Toujours utiliser `param?: Type`**, jamais `param: Type | undefined`.

Cette règle s'applique partout : interfaces, types, et paramètres de fonctions.

```ts
// ❌ Mauvais
interface User {
  name: string;
  avatar: string | undefined;
}

const fetchUser = (id: string, options: FetchOptions | undefined) => { ... };

// ✅ Bon
interface User {
  name: string;
  avatar?: string;
}

const fetchUser = (id: string, options?: FetchOptions) => { ... };
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
- **Pas de barrel files** (`index.ts` qui ré-exporte). Importer directement depuis le fichier source (ex: `import { UserCard } from './user-card/user-card'`). Les barrel files cassent le tree-shaking, ralentissent le bundler, créent des dépendances circulaires et masquent l'origine réelle du code.

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

Le code propre se documente lui-même. **Par défaut : pas de commentaire.** Si tu envisages d'en écrire un, applique d'abord le test ci-dessous.

### Challenge obligatoire avant d'écrire un commentaire

Pour chaque commentaire que tu envisages, répondre OUI aux 3 questions :

1. **Le "pourquoi" est-il déductible du code seul ?** Si oui → pas de commentaire (renommer la variable/fonction à la place).
2. **Retirer ce commentaire rendrait-il un reviewer confus ?** Si non → pas de commentaire.
3. **Le commentaire apporte-t-il une info absente du code (contrainte cachée, workaround, bug précis) ?** Si non → pas de commentaire.

Règle d'or : **préférer aucun commentaire à un commentaire qui paraphrase le code.**

### Contraintes de format

- **2-3 lignes maximum** par commentaire. Jamais de pavé, jamais de narration.
- **Pas de JSDoc/TSDoc** sur les fonctions internes — réserver aux API publiques de librairies.
- **Pas de commentaires décoratifs** (`// --- Section ---`, `// Constants`, `// Helpers`).
- **Pas de commentaires qui décrivent l'évidence** (`// increment counter`, `// return user`, `// handle click`).

### Cas où un commentaire est autorisé

- **Regex complexes** : une ligne pour expliquer le pattern.
- **Workarounds / hacks** : pourquoi on contourne, avec lien vers l'issue si applicable.
- **Logique métier non évidente** : quand le "pourquoi" n'est pas déductible du code.
- **`// TODO`** avec contexte : quand un point technique est intentionnellement différé.

Si tu as besoin d'un commentaire pour expliquer un bloc de code, c'est un signe que ce bloc doit être extrait dans une fonction au nom explicite.

---

## 5bis. Tailwind CSS

**Ne JAMAIS extraire des classes Tailwind dans une variable ou constante.**

Les classes Tailwind restent dans le `className` du JSX. Extraire les classes dans une constante (`const buttonClasses = "bg-blue-500 ..."`) casse la lisibilité, empêche la détection par les outils Tailwind (IntelliSense, purge, tri automatique) et éloigne le style du composant.

```tsx
// ❌ Mauvais : classes extraites dans une constante
const cardClasses = 'rounded-lg border border-gray-200 bg-white p-4 shadow-sm';
const Card = ({ children }: Props) => <div className={cardClasses}>{children}</div>;

// ✅ Bon : classes inline dans le JSX
const Card = ({ children }: Props) => (
    <div className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
        {children}
    </div>
);
```

### Seuil de lisibilité : utiliser `clsx` en vertical

Quand la liste de classes devient longue ou qu'elle contient des conditions, **utiliser `clsx`** (ou `classnames`) avec une écriture **verticale, une classe (ou un groupe logique) par ligne**. Cela évite la ligne géante illisible et met en évidence les conditions.

```tsx
// ❌ Mauvais : ligne monstrueuse, impossible à lire, conditions noyées
<button className={`rounded-md px-4 py-2 font-medium transition-colors ${isPrimary ? 'bg-blue-500 text-white hover:bg-blue-600' : 'bg-gray-100 text-gray-900 hover:bg-gray-200'} ${disabled ? 'cursor-not-allowed opacity-50' : ''}`}>

// ✅ Bon : clsx en vertical, chaque groupe logique sur sa propre ligne
<button
    className={clsx(
        'rounded-md px-4 py-2 font-medium transition-colors',
        isPrimary && 'bg-blue-500 text-white hover:bg-blue-600',
        !isPrimary && 'bg-gray-100 text-gray-900 hover:bg-gray-200',
        disabled && 'cursor-not-allowed opacity-50',
    )}
>
```

**Règles** :
- Inline tant que la liste tient lisiblement sur une ligne.
- `clsx` vertical dès qu'il y a une condition OU que la chaîne devient longue (repère pratique : > ~80 caractères ou > 6-8 classes).
- Grouper les classes par responsabilité (layout, couleurs, typographie, états) sur des lignes distinctes.
- Pas de variable intermédiaire : le `clsx(...)` reste directement dans le `className`.

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
