# Template US — Tauri

Ce fichier contient les sections techniques spécifiques aux projets Tauri v2 (Rust backend + React frontend). Il est lu par Scala (scrum-master) après détection de la techno.

> Pour la partie frontend React, lire aussi `us-template-react.md` et inclure ses sections dans l'US.

---

## Spécifications backend (Rust)

### Modules à créer

| Fichier | Description |
|---------|-------------|
| `src-tauri/src/{feature}/mod.rs` | Barrel file (exports) |
| `src-tauri/src/{feature}/{feature}.rs` | Logique métier |
| `src-tauri/src/{feature}/types.rs` | Structs et enums |
| `src-tauri/src/commands/{feature}.rs` | Commandes Tauri |

### Modules à modifier

| Fichier | Modification |
|---------|--------------|
| `src-tauri/src/lib.rs` | Enregistrement des nouvelles commandes |

### Structs Rust

```rust
#[derive(Serialize, Deserialize)]
struct [NomStruct] {
    [champ]: [type], // [description]
}
```

### Commandes Tauri (IPC)

```rust
#[tauri::command]
fn [nom_commande](state: State<AppState>) -> Result<[ReturnType], String> {
    // [description du comportement]
}
```

### Correspondance types Frontend ↔ Backend

| TypeScript | Rust | Notes |
|-----------|------|-------|
| `string` | `String` | |
| `number` | `f64` / `i32` | Préciser le type exact |
| `boolean` | `bool` | |
| `null` | `Option<T>` | Sérialise en `null` si `None` |
| `Array<T>` | `Vec<T>` | |

---

## Données de test / Mocks

```typescript
// Frontend — mocks pour les appels invoke()
const mockData = {
  // Structure exacte des données retournées par la commande Rust
};
```

```rust
// Backend — données de test pour les tests Rust
#[cfg(test)]
mod tests {
    // Structure exacte des données de test
}
```
