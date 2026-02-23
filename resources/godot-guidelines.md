# Godot 4 — Guidelines techniques pour jeux 2D

Ce fichier contient les patterns d'architecture et conventions GDScript à appliquer dans les projets Godot 4 en 2D. Il est lu par Aria (dev-godot) avant chaque implémentation.

---

## 1. Architecture ECS-Hybride

### Principe fondamental

**Les entities orchestrent, les components calculent. Seule l'entity appelle `move_and_slide()`.**

- Les components extends `Node` (jamais `CharacterBody2D`). Ils exposent une API publique (`update(delta)`, `get_velocity()`, etc.) mais ne déplacent jamais l'entity.
- L'entity (orchestrateur) appelle chaque component dans `_physics_process()`, assemble la vélocité finale, puis appelle `move_and_slide()` une seule fois.

```gdscript
# Pattern entity standard
func _physics_process(delta: float) -> void:
    _health.process(delta)
    _movement.update(delta)
    _custom_physics_step(delta)        # Hook virtuel pour sous-classes
    velocity = _get_final_velocity()   # Assemblage vélocité
    move_and_slide()                   # UNE SEULE FOIS
    _post_move_and_slide(delta)        # Hook post-physique
```

### Exceptions documentées

Un component peut écrire directement dans `_entity.velocity` **uniquement** si le mouvement EST la vélocité (ex: le mouvement du joueur est directement la vélocité). Toute exception doit être documentée dans le script.

Certains components peuvent extends `Area2D` quand ils nécessitent de la détection physique (ex: zone de séparation entre entities, aura d'effet).

### Quand extraire un component ?

| Déclencheur | Exemple |
|-------------|---------|
| Duplication entre sous-classes | Component de mouvement, d'attaque |
| God class trop volumineuse | Séparer tir, rechargement, VFX |
| Violation single-responsibility | Un script qui gère trop de choses |
| Réutilisabilité nécessaire | Composant partagé entre plusieurs entities |

### Components partagés vs spécifiques

- **Partagés** (dans `src/components/`) : components utilisés par plusieurs entities (santé, mouvement, navigation, effets visuels, attaques génériques)
- **Spécifiques** (dans `src/entities/<entity>/components/`) : components propres à une entity (mouvement joueur, tir joueur, capacités uniques)

---

## 2. Patterns de création de components

### Pattern `_ensure_component()`

Création dynamique de components avec vérification d'existence :

```gdscript
func _ensure_component(node_name: String, klass: Script) -> Node:
    var node = get_node_or_null(node_name)
    if not node:
        node = klass.new()
        node.name = node_name
        add_child(node)
    return node

# Usage :
_health = _ensure_component("Health", HealthComponent)
_movement = _ensure_component("Movement", MovementComponent)
```

### Pattern `_get_or_create_component()` (avec scripts preloadés)

```gdscript
func _get_or_create_component(node_name: String, script: Script):
    var component = get_node_or_null(node_name)
    if not component:
        component = Node.new()
        component.set_script(script)
        component.name = node_name
        add_child(component)
    return component

# Scripts preloadés en constantes :
const MovementScript = preload("res://src/entities/player/components/player_movement.gd")
```

> Adopter un pattern unique par type d'entity et le garder cohérent dans tout le projet.

---

## 3. Héritage — Template Method Pattern

L'entity de base fournit des hooks virtuels que les sous-classes surchargent :

```gdscript
# Hooks virtuels — entity de base
func _custom_physics_step(_delta: float) -> void: pass     # Update components spécifiques
func _get_final_velocity() -> Vector2: return Vector2.ZERO  # Assemblage vélocité
func _post_move_and_slide(_delta: float) -> void: pass      # Post-physique
func _get_contact_damage() -> int: return contact_damage     # Override dégâts
func _on_contact_damage_dealt(_target) -> void: pass         # Effets au contact
func is_knockback_immune() -> bool: return false             # Immunité physique
```

Les sous-classes appellent toujours `super._ready()` en premier, puis ajoutent leurs propres components.

### Patterns de vélocité des sous-classes

```gdscript
# Entity avec override de mouvement (ex: charge)
func _get_final_velocity() -> Vector2:
    if _charge_attack.is_overriding_movement():
        return _charge_attack.get_velocity()           # Override total
    return _movement.get_velocity() * _charge_attack.get_speed_multiplier()

# Entity avec pause pendant une action (ex: tir)
func _get_final_velocity() -> Vector2:
    if _ranged_attack.should_pause_movement():
        return Vector2.ZERO                             # Pause complète
    return _movement.get_velocity()
```

---

## 4. Système de signaux — Double couche

### EventBus global

Pour la communication inter-systèmes découplée. Utiliser un singleton global (ex: `G`) :

```gdscript
# Émission
G.emit("enemy_died", [enemy_type, global_position, xp_reward])
G.emit("player_health_changed", [current_health, max_health])

# Écoute — toujours dans _ready()
func _ready() -> void:
    G.connect_signal("player_health_changed", _on_health_changed)

# Déconnexion — TOUJOURS dans _exit_tree()
func _exit_tree() -> void:
    G.disconnect_signal("player_health_changed", _on_health_changed)
```

### Signaux locaux

Pour la communication parent-enfant au sein d'un même sous-arbre :

```gdscript
# Component émet
signal dash_started(direction: Vector2)
signal died()

# Entity connecte ses enfants entre eux
_movement.dash_started.connect(_vfx.on_dash_started)
```

### Règle de décision : Local vs EventBus

| Critère | Signal local | EventBus |
|---------|-------------|----------|
| Relation émetteur-récepteur | Parent-enfant, siblings connus | Systèmes différents |
| Couplage | Intentionnel | Découplé |
| Nombre de listeners | 1-3 connus | Inconnu, potentiellement N |
| Référence du component détenue | Oui | Non |

### Pattern Dual Emit

Émettre à la fois un signal local ET un signal EventBus quand un changement d'état intéresse à la fois le sous-arbre local et des systèmes distants :

```gdscript
G.emit("player_health_changed", [current_health, max_health])  # → HUD, effets globaux
health_changed.emit(current_health, max_health)                  # → sous-arbre local
```

### Pattern `_requested` (découplage)

Quand un système doit déclencher une action sur un autre sans le référencer :

```gdscript
# AVANT (couplé) : loot_manager → player.heal(amount)
# APRÈS (découplé) :
G.emit("player_heal_requested", [amount])                                    # Émetteur
G.connect_signal("player_heal_requested", _on_player_heal_requested)         # Récepteur
```

### Auto-câblage des components

Les components d'effet peuvent se connecter eux-mêmes dans leur `_ready()` — l'entity n'a pas besoin de les connaître :

```gdscript
func _ready() -> void:
    _entity = get_parent() as CharacterBody2D
    if _entity and _entity.has_signal("died"):
        _entity.died.connect(_on_entity_died)
```

---

## 5. Singleton G (globals)

`G` est un `class_name` statique (PAS un autoload). Il fournit des wrappers null-safe sur tous les autoloads, garantissant que le code ne crash jamais en tests headless :

```gdscript
class_name G

# Tout est static func
static func emit(event_name, args) -> void: ...
static func connect_signal(signal_name, callable) -> void: ...     # Idempotent (check is_connected)
static func disconnect_signal(signal_name, callable) -> void: ...
static func sfx(sfx_name, pitch_scale, volume_db) -> void: ...
static func sfx_random(sfx_names_array) -> void: ...
static func music(music_name, fade_time) -> void: ...
static func log_debug/info/warn/error(system, message) -> void: ...
static func find_player() -> Node2D: ...
static func get_living_enemies() -> Array[Node2D]: ...             # Cache dirty-flag
static func invalidate_enemies_cache() -> void: ...
```

### Cache avec dirty flag

```gdscript
static var _enemies_cache: Array[Node2D] = []
static var _enemies_cache_dirty: bool = true

# Invalidé quand un ennemi spawn ou meurt
# Rafraîchi lazily au premier get_living_enemies() après invalidation
# Retourne une COPIE (safe pour itération)
```

---

## 6. Conventions de nommage

| Élément | Convention | Exemples |
|---------|------------|----------|
| Fichiers `.gd` | snake_case | `enemy_health.gd`, `player_shooting.gd` |
| Classes | PascalCase | `BasicEnemy`, `PlayerMovement`, `ChargeAttack` |
| Signaux | snake_case | `player_died`, `room_cleared`, `dash_started` |
| Variables privées | `_underscore_prefix` | `_is_dashing`, `_current_health` |
| Variables publiques | snake_case sans prefix | `current_health`, `move_speed` |
| Constantes | UPPER_SNAKE_CASE | `MOVEMENT_THRESHOLD`, `SPAWN_DELAY` |
| Fonctions privées | `_underscore_prefix` | `_start_dash()`, `_process_idle()` |
| Handlers de signaux | `_on_<source>_<signal>` | `_on_health_changed`, `_on_player_died` |

### Conventions de nommage des signaux EventBus

| Convention | Usage | Exemples |
|------------|-------|----------|
| Past tense | Événement terminé | `enemy_died`, `room_cleared` |
| Present | État en cours | `wave_starting`, `countdown_started` |
| `_changed` | Update d'état | `player_health_changed`, `ammo_changed` |
| `_requested` | Commande découplée | `player_heal_requested`, `popup_requested` |

---

## 7. Structure d'un script GDScript — Ordre de déclaration

```gdscript
extends Node                              # 1. extends
class_name ComponentName                  # 2. class_name

## Docstring module (double ##)           # 3. Documentation
## Rôle du component

const SOME_CONSTANT = preload(...)        # 4. const (preloads d'abord)
const MAX_VALUE: float = 100.0

enum State { IDLE, ACTIVE, COOLDOWN }     # 5. enum

@export_group("Config")                   # 6. @export (groupés)
@export var some_config: float = 1.0

signal some_event(arg: Type)              # 7. signals locaux

var _entity: CharacterBody2D              # 8. var privées (_prefix)
var _internal_state: bool = false
var public_readable: int = 0              # 9. var publiques

@onready var _node_ref: Node = $Child     # 10. @onready

func _ready() -> void: ...               # 11. Lifecycle
func _exit_tree() -> void: ...
func _physics_process(delta) -> void: ... # 12. Process loops
func _process(delta) -> void: ...

func _private_helper() -> void: ...       # 13. Fonctions privées

## Public API                             # 14. Séparateur section
func initialize(config) -> void: ...      # 15. API publique
func get_value() -> int: ...
```

---

## 8. @export avec setter de propagation

Les `@export` sur l'entity qui configurent des components utilisent des setters pour propager les changements même depuis l'éditeur :

```gdscript
@export var max_health: int = 100:
    set(v):
        max_health = v
        if _health: _health.max_health = v   # Guard si _ready() pas encore appelé

@export var move_speed: float = 80.0:
    set(v):
        move_speed = v
        if _movement: _movement.move_speed = v
```

### `initialize(config: Dictionary)` pour les components complexes

```gdscript
_charge_attack.initialize({
    "charge_range": charge_range,
    "telegraph_duration": telegraph_duration,
    "charge_speed": charge_speed,
})
```

---

## 9. Convention "Visual" (Node2D)

Toute entity animée doit avoir un node enfant **"Visual"** (`Node2D`) contenant les sprites. Les components visuels y accèdent par nom :

```
Entity (CharacterBody2D)
├── CollisionShape2D
├── Visual (Node2D)          ← OBLIGATOIRE
│   └── Sprite2D / AnimatedSprite2D
├── NavigationAgent2D        (si navigation)
└── [Components...]
```

Usages du Visual :
- Flip direction (`Visual.scale.x`)
- Flash de dégâts (modulate)
- Shake d'attaque
- Extraction de sprites pour effets de mort

---

## 10. Machines à états

### Pattern standard : enum State + match

```gdscript
enum State { IDLE, TELEGRAPH, ACTIVE, COOLDOWN }
var _state: State = State.IDLE

func update(delta: float, target: Node2D, can_act: bool) -> void:
    match _state:
        State.IDLE:       _process_idle(target)
        State.TELEGRAPH:  _process_telegraph(delta)
        State.ACTIVE:     _process_active(delta)
        State.COOLDOWN:   _process_cooldown(delta)
```

### Transitions via méthodes dédiées avec guard de validité

```gdscript
func _start_telegraph(target: Node2D) -> void:
    if _state != State.IDLE: return
    _state = State.TELEGRAPH
    # ...
```

---

## 11. Patterns de timers

| Pattern | Usage | Exemple |
|---------|-------|---------|
| `float` delta countdown | Timers gameplay (cooldown, invulnérabilité) | `if _timer > 0: _timer -= delta` |
| `create_timer().timeout.connect()` | One-shot fire-and-forget | Spawn invulnérabilité, delay |
| `await create_timer(dur).timeout` | Séquençage async (respecte pause) | Flow de vagues, séquences |
| `Tween` | Animation visuelle | Scale punch, color flash |
| `Time.get_ticks_msec()` | Durée wall-clock (ignore time_scale) | Hitstop |

---

## 12. Gestion null et erreurs

```gdscript
# Validation parent dans _ready()
_entity = get_parent() as CharacterBody2D
if not _entity:
    G.log_error("ComponentName", "Parent must be CharacterBody2D")

# Toujours get_node_or_null, jamais get_node
var nav_agent = get_node_or_null("NavigationAgent2D")

# is_instance_valid pour les références cross-node
if is_instance_valid(target) and target.has_method("take_damage"):
    target.take_damage(amount)

# Guard null sur component optionnel
func get_health() -> int:
    return _health.get_health() if _health else max_health

# Validation d'input (aux frontières du système)
if amount <= 0: G.log_warn("Health", "Rejected invalid damage"); return
if not is_finite(amount): return
```

---

## 13. Typage statique

```gdscript
# Paramètres et retours toujours typés
func take_damage(amount: int) -> void:
func get_chase_direction(target: Node2D) -> Vector2:

# Variables locales avec := (inférence) ou type explicite
var input_direction := _get_input_direction()
var result: Array[String] = []

# Arrays typés
var _spawn_points: Array[Node2D] = []

# Non typé uniquement quand circular dependency
var _upgrade_pool = null  # Évite circular class_name

# Cast as avec null-safety
_entity = get_parent() as CharacterBody2D
```

---

## 14. preload() vs load()

| Situation | Utiliser | Raison |
|-----------|----------|--------|
| Script de component | `const Script = preload(...)` | Chargé au parse-time, rapide |
| Scène fréquemment instantiée | `const Scene = preload(...)` | Même raison |
| Ressources `.tres` fixes | `preload(...)` | OBLIGATOIRE pour les exports `.pck` |
| Chemin dynamique (@export) | `load(path)` | Chemin inconnu au parse-time |
| Éviter circular dependency | `load(...)` | Briser la dépendance circulaire |

> **Règle export critique** : `DirAccess.open()` ne fonctionne PAS dans les builds exportés. Tout `.tres` doit être dans un array `preload()` statique.

---

## 15. Optimisations performance

| Pattern | Où | Pourquoi |
|---------|-----|---------|
| `distance_squared_to()` au lieu de `distance_to()` | Range checks | Évite `sqrt()` |
| Pré-calculer `_range_squared` | Components avec détection de range | Carré calculé une fois |
| Cache `has_method()` dans `_ready()` | Appels répétés | Évite string lookup par frame |
| Dirty-flag cache | Listes d'entities | Évite `get_nodes_in_group()` chaque frame |
| Cached player ref + refresh sur signal | Components ennemis | Lookup une fois, signal pour refresh |
| Throttled pathfinding (ex: 0.15s / 40px) | Navigation | NavigationAgent coûteux |
| Templates + `.duplicate()` | Objets fréquemment créés | Évite allocation par instance |
| Lazy init | Pools, templates | Créé au premier usage |

---

## 16. Lazy initialization

```gdscript
# Lazy find d'un sibling ajouté après _ready()
func update(delta: float) -> void:
    if not _nav_chase and _entity:
        _find_navigation_chase()

# Lazy init de templates
func _ensure_templates() -> void:
    if not _template:
        _template = SomeResource.new()
        # ...

# Deferred navigation check (baking prend du temps)
get_tree().create_timer(0.1).timeout.connect(_check_navigation_available)
```

---

## 17. Collision layers (convention)

Définir les layers dans les project settings et documenter dans `AGENTS.md` :

| Layer | Nom | Usage |
|-------|-----|-------|
| 1 | World | Murs, sol, terrain |
| 2 | Player | Le joueur |
| 3 | Enemy | Ennemis |
| 4 | Projectile | Projectiles |
| 5 | Item | Items ramassables |
| 6 | Trigger | Zones trigger |
| 7 | Obstacles | Portes, obstacles LOS |

> Les masks de collision doivent être documentés dans le `AGENTS.md` du projet.

---

## 18. Logging

```gdscript
G.log_error("ClassName", "Message critique")      # push_error + rouge
G.log_warn("ClassName", "Dégradation gracieuse")   # push_warning + jaune
G.log_info("ClassName", "Transition d'état")       # print standard
G.log_debug("ClassName", "Détails internes")       # debug builds only
```

Le paramètre `system` est toujours le `class_name` PascalCase du script.

---

## 19. Audio

```gdscript
# Chemin hiérarchique : "catégorie/sous-catégorie/fichier"
G.sfx("weapons/reload_finish")
G.sfx("abilities/freeze", 1.0, -8.0)        # pitch, volume_db
G.sfx_random(HURT_SOUNDS)                    # Pool de variantes
```

---

## 20. Render layers

```
Level
├── GroundLayer       ← sol, statique
├── EntityLayer       ← y_sort_enabled=true, entities, loot
└── OverlayLayer      ← VFX, éléments UI world-space
```

Accès via `G.get_entity_layer()` — tout spawn dynamique (loot, projectiles, VFX) doit être placé dans le bon layer.

---

## 21. Groupes standards

| Groupe | Qui rejoint | Usage |
|--------|------------|-------|
| `"player"` | Player | `G.find_player()` |
| `"enemies"` | Entities ennemies | `G.get_living_enemies()`, room clearing |
| `"doors"` | Portes | Ouverture/fermeture par le level manager |
| `"rooms"` | Salles | Navigation de niveau |
| `"obstacles"` | Obstacles | Détection impact projectile |
| `"loot"` | Items | Collection |

> Adapter les groupes au projet. Cette liste est une base de départ.

---

## 22. Strategy pattern (Upgrades / Effects)

```gdscript
# Base abstraite — extends Resource
extends Resource
func apply(target: Node, stack_count: int) -> void: pass
func remove(target: Node) -> void: pass
```

Les effects sont des sub-resources embarqués dans des fichiers `.tres`. Les sous-classes extends `Resource` directement pour éviter les problèmes de `class_name` à l'export.

---

## 23. Stat modifiers (stacking)

```gdscript
# Modifiers accumulés par effect_id
_stat_modifiers: {stat_name: {effect_id: {type, value}}}

# Calcul final : additif puis multiplicatif
# (base_value + sum_add_modifiers) * (1.0 + sum_multiply_bonuses)
# Note : les multiply s'accumulent ADDITIVEMENT entre eux (2x +8% = +16%, pas 1.08²)
```
