<!-- GUIDELINES_TOKEN: TEST_2026-05 -->

# Tests — Guidelines techniques

> **Preuve de lecture obligatoire** : tout agent qui charge ce fichier DOIT inclure le token `TEST_2026-05` dans son premier message utilisateur (format : `📚 Lu : test-guidelines.md [TEST_2026-05]`). Sans token = lecture non confirmée.

Ce fichier contient les conventions de test à appliquer. Lu par Clea (qa) et par les sub-agents de test.

---

## Philosophie : Spec-driven, pas brute-force

**Chaque test = un cas d'utilisation de l'US.** On ne teste pas des fonctions isolées, on teste des comportements utilisateur. Les tests doivent se lire comme une liste de scénarios tirés de la user story.

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

## §2. Structure interne : Given/When/Then

**Chaque test DOIT être structuré en 3 blocs séparés par commentaires :**

```typescript
it('should display error message when API returns 500', () => {
  // Given - contexte initial
  const server = setupMockServer();
  server.use(http.get('/api/users', () => HttpResponse.json(null, { status: 500 })));

  // When - action déclenchante
  render(<UserList />);

  // Then - résultat observable
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

## §6. Ce qu'on fait

- ✅ Un test par scénario utilisateur identifié dans l'US
- ✅ Tester le comportement observable (ce que l'utilisateur voit/fait)
- ✅ Edge cases documentés dans l'US = `it()` dédiés
- ✅ Tests minimalistes : minimum d'assertions pour prouver le use case
- ✅ Noms qui forment une spec lisible quand lus à la suite
