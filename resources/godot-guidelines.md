# Godot 4 — Guidelines techniques pour jeux 2D

Ce fichier contient les patterns d'architecture et conventions GDScript à appliquer dans les projets Godot 4 en 2D. Il est lu par Gaia (dev-godot) avant chaque implémentation.

---

## 0. Principe Scene-First

**Règle fondamentale : tout ce qui peut exister dans une scène (.tscn) DOIT y être créé, pas par code.**

L'utilisateur doit pouvoir ouvrir n'importe quelle scène dans l'éditeur Godot et voir/modifier visuellement la hiérarchie, les nodes, les @export, les collision shapes, etc. Le code ne crée des nodes dynamiquement que quand c'est nécessaire au runtime.

### Créer dans la scène (.tscn) — par défaut

| Quoi | Pourquoi |
|------|----------|
| Entities et leur hiérarchie complète | Visibles et éditables dans l'éditeur |
| Components fixes (Health, Movement, etc.) | Configurables via @export dans l'inspecteur |
| CollisionShape2D, Area2D | Shapes éditables visuellement |
| Visual (Node2D) + Sprites | Preview dans l'éditeur |
| NavigationAgent2D | Configurable dans l'inspecteur |
| AnimationPlayer, AnimationTree | Édition des animations dans l'éditeur |
| AudioStreamPlayer2D | Assignation des streams dans l'inspecteur |
| Timer nodes | Configurables dans l'inspecteur (wait_time, one_shot, autostart) |

### Créer par code — uniquement si nécessaire

| Quoi | Pourquoi |
|------|----------|
| Spawning dynamique (ennemis, projectiles, loot) | N'existent pas au chargement |
| VFX et particules temporaires | Créés à la volée, détruits après |
| Components conditionnels selon le contexte runtime | Sous-classes qui ajoutent des components spécifiques |
| Nodes dont le type dépend d'une configuration | Chemin dynamique, type inconnu à l'avance |

### Accès aux nodes de scène

```gdscript
# ✅ Bon : le node existe dans la scène, on y accède via @onready
@onready var _health: Node = $Health
@onready var _movement: Node = $Movement
@onready var _visual: Node2D = $Visual

# ✅ Bon : accès null-safe pour les nodes optionnels
var _nav_agent = get_node_or_null("NavigationAgent2D")

# ❌ Éviter : créer le node par code alors qu'il pourrait être dans la scène
func _ready() -> void:
    var health = HealthComponent.new()
    health.name = "Health"
    add_child(health)
```

### Conséquences sur les @export

Les @export configurent les nodes de la scène dans l'inspecteur. Utiliser des setters de propagation pour transmettre les valeurs aux components enfants :

```gdscript
@export var max_health: int = 100:
    set(v):
        max_health = v
        if _health: _health.max_health = v   # Propagation au component
```

> Les patterns `_ensure_component()` (section 2) restent valides UNIQUEMENT pour les components qui DOIVENT être créés dynamiquement (sous-classes spécialisées, spawning conditionnel).

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

### Méthode préférée : nodes dans la scène (Scene-First)

La plupart des components doivent être des nodes créés dans le fichier `.tscn`. Le script y accède via `@onready` :

```gdscript
@onready var _health: Node = $Health
@onready var _movement: Node = $Movement
```

### Méthode alternative : création dynamique (`_ensure_component()`)

Réservée aux cas où le component **ne peut pas** être dans la scène (sous-classes qui ajoutent des components spécifiques, spawning conditionnel) :

```gdscript
func _ensure_component(node_name: String, klass: Script) -> Node:
    var node = get_node_or_null(node_name)
    if not node:
        node = klass.new()
        node.name = node_name
        add_child(node)
    return node

# Usage dans une sous-classe qui ajoute un component spécifique :
func _ready() -> void:
    super._ready()
    _charge_attack = _ensure_component("ChargeAttack", ChargeAttackComponent)
```

> **Règle : un seul pattern de création dynamique par projet.** `_ensure_component()` est le pattern recommandé. Il gère l'idempotence (ne crée pas de doublon si le node existe déjà dans la scène).

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

`G` est un `class_name` statique (PAS un autoload). Toutes ses fonctions sont `static`, ce qui permet de les appeler sans instance et sans dépendance à l'arbre de scènes. Avantage : fonctionne en tests headless et n'a pas besoin d'être enregistré dans les Project Settings → Autoload.

Il fournit des wrappers null-safe sur tous les autoloads, garantissant que le code ne crash jamais en tests headless :

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

## 9. Convention "Visual" (Node2D) et hiérarchie standard

Toute entity animée doit avoir un node enfant **"Visual"** (`Node2D`) contenant les sprites et animations. Les components visuels y accèdent par nom :

```
Entity (CharacterBody2D)
├── CollisionShape2D
├── Visual (Node2D)              ← OBLIGATOIRE
│   ├── Sprite2D / AnimatedSprite2D
│   └── AnimationPlayer          ← Si animations frame-by-frame
├── AnimationTree                (si state machine d'animation complexe — au niveau entity)
├── NavigationAgent2D            (si navigation)
└── [Components...]
```

### Placement AnimationPlayer vs AnimationTree

| Node | Placement | Raison |
|------|-----------|--------|
| **AnimationPlayer** | Sous **Visual** | Il anime les propriétés du sprite (frames, modulate, position). Créé dans la scène .tscn. |
| **AnimationTree** | Au niveau **Entity** | Il orchestre les transitions entre animations. Besoin d'accès au state global de l'entity. |

> Les deux doivent être créés dans la scène (.tscn), jamais par code.

Usages du Visual :
- Flip direction (`Visual.scale.x`)
- Flash de dégâts (modulate)
- Shake d'attaque
- Extraction de sprites pour effets de mort

---

## 10. Machines à états

### Pattern standard : enum State + match

Pour les cas simples (3-6 états, transitions linéaires) :

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

### Quand évoluer vers un système plus avancé ?

| Seuil | Pattern recommandé |
|-------|-------------------|
| 3-6 états, transitions simples | enum + match (ci-dessus) |
| 7+ états, ou transitions conditionnelles complexes | Nodes State séparés (chaque état = un Node enfant avec son propre script) |
| États empilables (pause, menu overlay, stun par-dessus idle) | State stack (push/pop) |
| Animations liées aux états | AnimationTree avec StateMachine — les transitions d'animation pilotent les transitions de gameplay |

> Commencer simple (enum + match). Refactorer vers des nodes State uniquement quand le `match` devient ingérable.

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
| `distance_squared_to()` au lieu de `distance_to()` | Range checks | Évite `sqrt()` — comparer avec `range * range` |
| Pré-calculer `_range_squared = range * range` | Components avec détection de range | Carré calculé une fois dans `_ready()` |
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

## 22. Strategy pattern (Upgrades / Effects) — Optionnel, pour jeux avec système d'upgrades

```gdscript
# Base abstraite — extends Resource
extends Resource
func apply(target: Node, stack_count: int) -> void: pass
func remove(target: Node) -> void: pass
```

Les effects sont des sub-resources embarqués dans des fichiers `.tres`. Les sous-classes extends `Resource` directement pour éviter les problèmes de `class_name` à l'export.

---

## 23. Stat modifiers (stacking) — Optionnel, pour jeux avec système de stats

```gdscript
# Modifiers accumulés par effect_id
_stat_modifiers: {stat_name: {effect_id: {type, value}}}

# Calcul final : additif puis multiplicatif
# (base_value + sum_add_modifiers) * (1.0 + sum_multiply_bonuses)
# Note : les multiply s'accumulent ADDITIVEMENT entre eux (2x +8% = +16%, pas 1.08²)
```

---

## 24. Input handling

### Convention InputMap

Définir les actions dans Project Settings → Input Map. Ne jamais utiliser de scan codes bruts dans le code.

```gdscript
# ✅ Bon : action nommée, remappable
if Input.is_action_just_pressed("attack"):
    _start_attack()

var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

# ❌ Mauvais : scan code brut, non remappable
if Input.is_key_pressed(KEY_SPACE):
    _start_attack()
```

### Conventions de nommage des actions

| Convention | Exemples |
|------------|----------|
| `move_*` | `move_left`, `move_right`, `move_up`, `move_down` |
| `action verb` | `attack`, `dash`, `interact`, `pause` |
| `ui_*` | `ui_accept`, `ui_cancel` (réservé Godot) |

### Où lire les inputs

- **Entity** : lit les inputs dans `_physics_process()` ou `_unhandled_input()`
- **Components** : ne lisent JAMAIS les inputs directement. Ils reçoivent des commandes de l'entity
- **UI** : `_gui_input()` ou `_unhandled_input()` sur les Control nodes

```gdscript
# Entity lit l'input et transmet au component
func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    _movement.set_direction(input_dir)

    if Input.is_action_just_pressed("dash"):
        _movement.start_dash()
```

---

## 25. Animation patterns

### AnimationPlayer (frame-by-frame, tweens pré-définis)

Créé dans la scène `.tscn` sous le node **Visual**. Utilisé pour les animations de sprites et les séquences pré-définies.

```gdscript
# Accès via @onready
@onready var _anim_player: AnimationPlayer = $Visual/AnimationPlayer

# Jouer une animation
_anim_player.play("attack")

# Connecter le signal de fin (dans la scène ou dans _ready)
_anim_player.animation_finished.connect(_on_animation_finished)
```

### AnimationTree (state machine d'animation)

Créé dans la scène `.tscn` au niveau entity. Utilisé quand les transitions entre animations sont complexes (idle → walk → attack → hurt).

```gdscript
@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _state_machine: AnimationNodeStateMachinePlayback = _anim_tree["parameters/playback"]

# Transitionner vers un état
_state_machine.travel("walk")

# Set blend position (pour blend trees directionnels)
_anim_tree["parameters/walk/blend_position"] = direction
```

### Tweens (animations procédurales)

Pour les effets visuels ponctuels (flash, scale punch, shake). Créés par code car temporaires :

```gdscript
# Flash de dégâts (blanc pendant 0.1s)
func flash_damage() -> void:
    var tween := create_tween()
    tween.tween_property($Visual, "modulate", Color.WHITE, 0.0)
    tween.tween_property($Visual, "modulate", Color(1, 1, 1, 1), 0.1)

# Scale punch (impact feel)
func scale_punch() -> void:
    var tween := create_tween()
    tween.tween_property($Visual, "scale", Vector2(1.2, 0.8), 0.05)
    tween.tween_property($Visual, "scale", Vector2(1.0, 1.0), 0.1)
```

> Les Tweens sont l'exception au Scene-First : ils sont toujours créés par code car ils sont temporaires et procéduraux.

---

## 26. UI / HUD patterns

### Principes

- Les nodes UI (Control, Label, TextureRect, etc.) sont créés dans des scènes `.tscn` dédiées
- Le HUD écoute les changements via **EventBus** (jamais de référence directe au joueur)
- Les éléments UI ne connaissent pas les entities — communication unidirectionnelle via signaux

### Pattern de mise à jour du HUD

```gdscript
# HUD : écoute l'EventBus
func _ready() -> void:
    G.connect_signal("player_health_changed", _on_health_changed)

func _exit_tree() -> void:
    G.disconnect_signal("player_health_changed", _on_health_changed)

func _on_health_changed(current: int, max_hp: int) -> void:
    _health_bar.value = current
    _health_bar.max_value = max_hp
```

### Structure de scène UI

```
HUD (CanvasLayer)
├── HealthBar (TextureProgressBar)
├── AmmoDisplay (HBoxContainer)
│   ├── AmmoIcon (TextureRect)
│   └── AmmoLabel (Label)
└── WaveCounter (Label)
```

> Tous les nodes UI sont créés dans la scène .tscn, éditables visuellement. Le script gère uniquement les mises à jour de valeurs.

---

## 27. Conventions de fichiers .tscn

### Nommage

| Élément | Convention | Exemple |
|---------|------------|---------|
| Fichier scène | snake_case | `basic_enemy.tscn`, `health_component.tscn` |
| Noms de nodes | PascalCase | `Visual`, `Health`, `CollisionShape2D` |
| Noms de nodes components | PascalCase descriptif | `PlayerMovement`, `RangedAttack` |

### Structure de dossiers pour les scènes

```
src/
├── entities/
│   ├── player/
│   │   ├── player.tscn            # Scène entity principale
│   │   ├── player.gd              # Script entity
│   │   └── components/
│   │       ├── player_movement.tscn
│   │       ├── player_movement.gd
│   │       ├── player_shooting.tscn
│   │       └── player_shooting.gd
│   └── enemies/
│       ├── basic_enemy.tscn
│       ├── basic_enemy.gd
│       └── components/
│           └── ...
├── components/                     # Components partagés
│   ├── health.tscn
│   ├── health.gd
│   ├── knockback.tscn
│   └── knockback.gd
├── ui/
│   ├── hud.tscn
│   └── hud.gd
└── levels/
    ├── level_01.tscn
    └── ...
```

### Component en tant que scène réutilisable

Un component partagé a sa propre scène `.tscn` qui peut être instanciée dans n'importe quelle entity :

```
health.tscn
└── Health (Node)                    ← root node, script: health.gd
```

Dans la scène de l'entity, le component est ajouté en tant qu'instance de scène (clic droit → "Instance Child Scene" dans l'éditeur), ce qui permet :
- De modifier les @export par instance dans l'inspecteur
- De voir le component dans l'arbre de scènes
- De bénéficier des mises à jour si la scène component est modifiée

---

## 28. Camera patterns

### Camera follow (joueur)

La caméra est un enfant du joueur dans la scène `.tscn` :

```
Player (CharacterBody2D)
├── Camera2D                         ← enfant direct
│   # position_smoothing_enabled = true
│   # position_smoothing_speed = 5.0
├── Visual (Node2D)
└── ...
```

### Screen shake

```gdscript
# Via le singleton G ou un component dédié
static func screen_shake(intensity: float, duration: float) -> void:
    var camera := _find_camera()
    if not camera: return
    var tween := camera.create_tween()
    for i in int(duration / 0.05):
        var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity
        tween.tween_property(camera, "offset", offset, 0.05)
    tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
```

### Limites de caméra

Configurées dans la scène `.tscn` via les propriétés `limit_left`, `limit_right`, `limit_top`, `limit_bottom` de Camera2D, ou dynamiquement par le level manager quand le joueur change de salle.
