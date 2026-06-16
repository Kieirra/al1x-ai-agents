<!-- GUIDELINES_TOKEN: TEST_2026-05 -->

# Tests — Guidelines techniques

> **Preuve de lecture obligatoire** : tout agent qui charge ce fichier DOIT inclure le token `TEST_2026-05` dans son premier message utilisateur (format : `📚 Lu : test-guidelines.md [TEST_2026-05]`). Sans token = lecture non confirmée.

Ce fichier contient les conventions de test à appliquer. Lu par Clea (qa) et par les sub-agents de test.

---

## Philosophie : minimum de tests pertinents, pas brute-force

**Chaque test = un use case réel.** On ne teste pas des fonctions isolées, on teste des comportements observables. Les use cases se déduisent du **code réellement modifié** (l'US n'est qu'une référence, souvent périmée). Vise le **minimum de tests pertinents** : happy path d'abord, edge cases seulement s'ils sont intéressants ou risqués. Jamais de surengineering.

---

## §1. Format des descriptions : Should/When

**TOUJOURS** utiliser `it('should [résultat] when [condition/action]')` :

```typescript
// ✅ Bon
it('should display error message when API returns 500')
it('should disable submit button when form is invalid')
it('should redirect to dashboard when login succeeds')

// ❌ Mauvais
it('test error handling')
it('renders correctly')
it('handles click')
```

---

## §2. Structure interne : Given / When / Then (sans labels)

**Chaque test suit la structure en 3 temps — contexte, action, résultat — séparés par une ligne vide.** **Aucun commentaire de label** `// Given` / `// When` / `// Then` : ils n'apportent rien, la structure se lit d'elle-même.

```typescript
it('should display error message when API returns 500', () => {
  const server = setupMockServer();
  server.use(http.get('/api/users', () => HttpResponse.json(null, { status: 500 })));

  render(<UserList />);

  expect(screen.getByText('Une erreur est survenue')).toBeInTheDocument();
});
```

---

## §3. Convention `describe` : groupe nominal + majuscule

`describe` = sujet (groupe nominal commençant par majuscule). Combiné avec `it('should...')`, ça forme une phrase complète :

> **LoginForm** should display error message when API returns 500

```typescript
// ✅ Bon
describe('LoginForm', () => { ... });
describe('User authentication', () => { ... });
describe('Cart total calculation', () => { ... });

// ❌ Mauvais
describe('test login form', () => { ... });
describe('handles authentication', () => { ... });
describe('utils', () => { ... });
```

**Describe imbriqués** — sous-describe affine le contexte (groupe nominal) :

```typescript
describe('LoginForm', () => {
  describe('Valid credentials', () => {
    it('should redirect to dashboard when login succeeds');
    it('should store auth token when API returns 200');
  });

  describe('Invalid credentials', () => {
    it('should display error message when API returns 401');
  });

  describe('Network error', () => {
    it('should display retry button when connection is lost');
  });
});
```

---

## §4. Granularité : 1 describe / feature, 1 it / use case

Chaque `it()` correspond à un critère d'acceptation ou un edge case de l'US.

```typescript
describe('LoginForm', () => {
  it('should submit credentials when form is valid');
  it('should display validation error when email is empty');
  it('should display validation error when password is too short');
  it('should disable submit button when request is pending');
  it('should redirect to dashboard when login succeeds');
  it('should display server error when API returns 500');
});
```

---

## §5. Ce qu'on NE fait PAS

- ❌ Tester les détails d'implémentation (state interne, méthodes privées)
- ❌ Un test par méthode/prop (style "100% coverage brute-force")
- ❌ Descriptions vagues (`'renders correctly'`, `'works'`, `'handles edge case'`)
- ❌ Tests redondants vérifiant le même comportement sous un angle différent
- ❌ Tests trop couplés à l'implémentation (mock de chaque dépendance interne)
- ❌ Surengineering : edge cases peu probables, combinaisons sans risque réel, edge case trivial "au cas où"
- ❌ Commentaires de label `// Given` / `// When` / `// Then` (la structure en blocs suffit)

## §6. Ce qu'on fait

- ✅ Happy path d'abord : 1 test par use case principal (déduit du code, pas seulement de l'US)
- ✅ Tester le comportement observable (ce que l'utilisateur voit/fait)
- ✅ Edge case en test dédié seulement s'il est intéressant ou porte un risque réel
- ✅ Tests minimalistes : minimum d'assertions pour prouver le use case
- ✅ Noms qui forment une spec lisible quand lus à la suite

---

## §7. Rust unit tests (Tauri backend)

**Économie d'abord. Pas de coverage pour le coverage.** On teste la logique métier qui peut régresser, jamais le framework. Un test non rattaché à un comportement de l'US ne doit pas exister. Exécuter tous les tests est toujours bon — c'est en **écrire** trop qui est interdit.

### Où et quoi tester

- **Unitaire par défaut** : `#[cfg(test)] mod tests` dans le module concerné, sur fonctions pures, transformations, calculs, parsing, machines à états.
- **1 `#[test]` par scénario de l'US** (CA ou edge case réel), pas un test par fonction.
- **Ne PAS tester** : enregistrement des commandes Tauri, sérialisation serde triviale, getters/setters, code qui ne fait que déléguer au framework.

### Nommage : should/when en snake_case

Le nom de la fonction de test = phrase lisible, miroir de la convention frontend :

```rust
#[test]
fn should_return_error_when_path_is_empty() { ... }

#[test]
fn should_compute_total_when_cart_has_items() { ... }
```

### Structure : Given / When / Then (sans labels)

Trois temps — contexte, action, résultat — séparés par une **ligne vide**. **Jamais** de commentaires `// Given` / `// When` / `// Then` : ils ne servent à rien. Un test ne contient aucun commentaire.

```rust
#[test]
fn should_return_error_when_path_is_empty() {
    let input = "";

    let result = resolve_path(input);

    assert!(result.is_err());
}
```

### Ce qu'on NE fait PAS (Rust)

- ❌ Tester chaque getter / variante de sérialisation
- ❌ Viser 100 % de coverage
- ❌ Un test par valeur d'entrée triviale (un seul cas représentatif, ou `rstest` si vraiment paramétré)
- ❌ Tout commentaire dans un test — y compris les labels `// Given` / `// When` / `// Then` (la structure en blocs suffit)
- ❌ Test d'intégration lourd quand un test unitaire suffit
