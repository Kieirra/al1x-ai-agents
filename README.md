# al1x-ai-agents

A centralized collection of custom Claude Code agents, installable in any project.

> This repo is not open for contributions. Agents are maintained by [@Kieirra](https://github.com/Kieirra) for personal use and shared publicly as-is.

## Architecture : Super-agents + Sub-agents

Les agents sont organisés en deux niveaux :
- **Super-agents** : orchestrateurs invocables via `/commande`, lancent des sub-agents en parallèle via le Task tool de Claude Code
- **Sub-agents** : spécialistes appelés par les super-agents, pas invocables directement

Les noms sont inspirés des personnages de **Clair Obscur: Expedition 33**.

### Super-agents (slash commands)

| Commande | Pseudo | Description |
|----------|--------|-------------|
| `/architecte` | **Aline** | Product architect — orchestre 3 explorations parallèles (tech, UX, approches), synthétise en QCM + ASCII mockup, rédige l'US |
| `/dev` | **Alicia** | Lead developer — détecte la techno, dispatche aux devs spécialisés, parallélise front+back pour Tauri |
| `/qa` | **Clea** | QA lead — orchestre tests unitaires, stories Storybook, validation des critères d'acceptation |
| `/uxui` | **Renoir** | UX/UI architect — standalone pour audits/brainstorms/wireframes ASCII, ou sub-agent d'Aline |
| `/reviewer` | **Verso** | Code guardian — orchestre 5 reviews parallèles (conventions, bugs, sécurité, story compliance) |

### Sub-agents (appelés par les super-agents)

| Agent | Pseudo | Appelé par | Spécialité |
|-------|--------|-----------|------------|
| `dev-react` | **Maelle** | Alicia (`/dev`) | Implémentation React/TypeScript |
| `dev-tauri` | **Lune** | Alicia (`/dev`) | Implémentation Tauri v2 (Rust + React) |
| `dev-godot` | **Sciel** | Alicia (`/dev`) | Implémentation Godot 4 / GDScript |
| `dev-stories` | **Stella** | Clea (`/qa`) | Stories Storybook |
| `fixer` | **Monoco** | Verso (`/reviewer`) | Corrections ciblées (sur demande uniquement) |

## Workflow

Les agents fonctionnent en pipeline. Le pipeline s'adapte à la technologie du projet :

### React / Tauri (avec frontend)
```
/architecte (Aline) → /dev (Alicia) → /qa (Clea) → /reviewer (Verso)
                                                            ↓
                                                  ✅ reviewed → merge
                                                  ❌ changes-requested → Monoco (sur demande) → /reviewer (boucle)
```

### Godot (pas de stories/tests)
```
/architecte (Aline) → /dev (Alicia) → /reviewer (Verso)
                                              ↓
                                    ✅ reviewed → merge
                                    ❌ changes-requested → Monoco (sur demande) → /reviewer (boucle)
```

### Détail des super-agents

1. **`/architecte`** (Aline) — Demande TOUJOURS à l'utilisateur ce qu'il veut faire (ne devine jamais depuis la branche). Lance 3 explorations parallèles, synthétise en QCM, rédige l'US dans `.claude/us/`
2. **`/dev`** (Alicia) — Détecte la techno et dispatche : Maelle (React), Lune (Tauri back), Sciel (Godot). Parallélise Lune + Maelle pour les projets Tauri
3. **`/qa`** (Clea) — Détecte les conventions de test du projet. Lance en parallèle : tests unitaires, stories Storybook, validation des critères d'acceptation
4. **`/uxui`** (Renoir) — Peut être appelé à tout moment pour un audit UX, brainstorm ou wireframe ASCII. Utilise les frameworks BMAP et B.I.A.S.
5. **`/reviewer`** (Verso) — Lance 5 reviews parallèles : conventions & patterns, bug hunter, sécurité, story compliance. Ne fixe JAMAIS le code — Monoco le fait sur demande

### Statuts de l'US

**React / Tauri :** `ready` → `in-progress` → `done` → `stories-done` → `reviewed` (merge)

**Godot :** `ready` → `in-progress` → `done` → `reviewed` (merge)

**Si changes requested :** `changes-requested` → `fixed` → `reviewed` (boucle)

## Available commands

| Command | Description |
|---------|-------------|
| `/update-agents` | Re-downloads all agents and commands from this repo |
| `/workflow` | Shows the current pipeline status and suggests the next step |
| `/list-us` | Lists all user stories in `.claude/us/` with their status |

## Installation

### Global (recommandé) — disponible dans tous les projets

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh | bash
```

Installe dans `~/.claude/` — les agents, commandes et ressources sont accessibles depuis n'importe quel projet Claude Code.

### Local — uniquement dans le projet courant

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh | bash -s -- --local
```

Installe dans `.claude/` du répertoire courant.

### Ce que le script installe

- **Super-agents** (`user-invocable: true`) → `commands/` (slash commands) + `agents/` (auto-délégation)
- **Sub-agents** (`user-invocable: false`) → `agents/` uniquement (pas de slash command)
- **Commandes utilitaires** (`/workflow`, `/list-us`, `/update-agents`) → `commands/`
- **Ressources** (guidelines, templates) → `resources/`

## Updating

In Claude Code, run:

```
/update-agents
```

Or re-run the curl command above.

## Structure

```
agents/                    # Agent definitions
  architecte.md            # Super-agent (Aline) — product architect
  dev.md                   # Super-agent (Alicia) — lead developer
  qa.md                    # Super-agent (Clea) — QA lead
  uxui.md                  # Super-agent (Renoir) — UX/UI architect
  reviewer.md              # Super-agent (Verso) — code guardian
  dev-react.md             # Sub-agent (Maelle) — React/TypeScript
  dev-tauri.md             # Sub-agent (Lune) — Tauri v2 / Rust
  dev-godot.md             # Sub-agent (Sciel) — Godot 4 / GDScript
  dev-stories.md           # Sub-agent (Stella) — Storybook stories
  fixer.md                 # Sub-agent (Monoco) — targeted fixes
commands/                  # Slash commands (non-agent)
  workflow.md
  list-us.md
  update-agents.md
resources/                 # Reference files (not agents)
  godot-guidelines.md      # Godot 4 architecture & conventions
  ux-guidelines.md         # UX/UI frameworks (BMAP, B.I.A.S.)
  us-template-react.md     # US template for React projects
  us-template-tauri.md     # US template for Tauri projects
  us-template-godot.md     # US template for Godot projects
```
