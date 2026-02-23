# Template US — Godot

Ce fichier contient les sections techniques et game feel spécifiques aux projets Godot 4 (2D, GDScript, ECS-Hybride). Il est lu par Lira (scrum-master) après détection de la techno.

---

## Spécifications techniques

### Scènes à créer

| Scène (.tscn) | Node racine | Description |
|----------------|-------------|-------------|
| `src/entities/[nom]/[nom].tscn` | CharacterBody2D | Entity principale |
| `src/entities/[nom]/components/[comp].tscn` | Node | Component [description] |

### Scripts à créer

| Script (.gd) | Attaché à | Description |
|---------------|-----------|-------------|
| `src/entities/[nom]/[nom].gd` | Node racine de la scène | Orchestrateur entity |
| `src/components/[comp].gd` | Node racine du component | [Description] |

### Scripts à modifier

| Script | Modification |
|--------|--------------|
| `src/path/to/file.gd:XX` | [Description de la modification] |

### Hiérarchie de scène attendue

```
[Entity] (CharacterBody2D)
├── CollisionShape2D
├── Visual (Node2D)
│   ├── Sprite2D / AnimatedSprite2D
│   └── AnimationPlayer
├── [ComponentA] (Node) — script: component_a.gd
├── [ComponentB] (Node) — script: component_b.gd
└── [Autres nodes]
```

### Components existants à réutiliser

| Component | Chemin | Usage |
|-----------|--------|-------|
| `HealthComponent` | `src/components/health.tscn` | Gestion des PV |

### Classes / Enums / Signaux

```gdscript
# Classes ou enums à créer
enum [NomEnum] { VALEUR_1, VALEUR_2 }

# Signaux à émettre
signal [nom_signal](param: Type)

# Signaux EventBus
# G.emit("[signal_name]", [args])
```

### Données (@export)

```gdscript
@export_group("[Nom du groupe]")
@export var [propriété]: [Type] = [valeur_defaut]  ## [description]
```

---

## Spécifications Game Feel

### Feedback joueur

| Action | Feedback visuel | Feedback sonore | Feedback gameplay |
|--------|----------------|-----------------|-------------------|
| [Action 1] | [Flash, shake, particules ?] | [SFX ?] | [Hitstop, knockback ?] |

### Juice & Polish

- **Screen shake** : [Intensité, durée, déclencheur]
- **Hitstop** : [Durée en frames, quand ?]
- **Particules** : [Type, déclencheur]
- **Tweens** : [Scale punch, color flash, etc.]

### Animations attendues

| Animation | Durée | Déclencheur | Transition |
|-----------|-------|-------------|------------|
| [idle] | loop | Par défaut | → walk si mouvement |
| [attack] | 0.3s | Input attaque | → idle à la fin |

---

## Données de test

```gdscript
# Données de test pour valider les comportements
# Valeurs @export de référence pour les tests manuels :
# - [propriété]: [valeur attendue]
```
