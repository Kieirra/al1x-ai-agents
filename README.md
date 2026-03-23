# al1x-ai-agents

Une collection d'agents Claude Code spécialisés qui forment une **team de dev complète** : architecture, dev, QA, review, refactoring, UX/UI.

Les noms sont inspirés des personnages de **Clair Obscur: Expedition 33**.

> Ce repo n'est pas ouvert aux contributions. Maintenu par [@Kieirra](https://github.com/Kieirra) pour usage personnel, partagé publiquement tel quel.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh | bash
```

Pour installer uniquement dans le projet courant :

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh | bash -s -- --local
```

Mise à jour : `/update-agents` dans Claude Code ou relancer la commande ci-dessus.

## Les agents

### Orchestrateurs

Invocables avec `@nom` ou `/nom` dans Claude Code. Chaque orchestrateur lance des sous-agents en parallèle.

| Agent | Pseudo | Role |
|-------|--------|------|
| `@architecte` | **Aline** | Product architect — 3 explorations parallèles (tech, UX, approches), QCM, wireframe ASCII, rédaction d'US |
| `@dev` | **Alicia** | Lead developer — détecte la techno, dispatche aux devs spécialisés, parallélise front+back |
| `@qa` | **Clea** | QA lead — tests unitaires, stories Storybook, validation des critères d'acceptation |
| `@reviewer` | **Verso** | Code guardian — 4 reviews parallèles (conventions, bugs, sécurité, story compliance) |
| `@refactor` | **Esquie** | Refactoring analyst — DRY, dead code, simplification, nommage, guidelines |
| `@uxui` | **Renoir** | UX/UI architect — audits, brainstorms, wireframes ASCII, frameworks BMAP & B.I.A.S. |

### Sous-agents

Appelés automatiquement par les orchestrateurs. Pas besoin de les invoquer directement.

| Agent | Pseudo | Appelé par | Techno |
|-------|--------|-----------|--------|
| `dev-react` | **Maelle** | @dev | React / TypeScript |
| `dev-tauri` | **Lune** | @dev | Tauri v2 (Rust + React) |
| `dev-godot` | **Sciel** | @dev | Godot 4 / GDScript |
| `dev-stories` | **Gustave** | @qa | Stories Storybook |
| `nestjs-backend` | **Golgra** | @dev | NestJS backend (modules, controllers, services, DTOs) |
| `fixer` | **Monoco** | @reviewer, @refactor | Corrections ciblées, refactoring ISO fonctionnel |

## Pipeline

Les agents fonctionnent en chaîne. Le pipeline s'adapte au projet :

```
React / Tauri :   @architecte → @dev → @refactor → @qa → @reviewer
Godot :           @architecte → @dev → @refactor → @reviewer
```

Si le reviewer demande des changements : `@fixer` (sur demande) → `@reviewer` (boucle).

La commande `/team` lance le pipeline complet en autonome.

### Statuts de l'US

| Stack | Progression |
|-------|------------|
| React / Tauri | `ready` → `in-progress` → `done` → `refactored` → `stories-done` → `reviewed` (merge) |
| Godot | `ready` → `in-progress` → `done` → `refactored` → `reviewed` (merge) |

## Commandes utilitaires

| Commande | Description |
|----------|-------------|
| `/team` | Pipeline complet autonome |
| `/workflow` | Affiche l'état du pipeline et la prochaine étape |
| `/list-us` | Liste les user stories dans `.claude/us/` |
| `/update-agents` | Met à jour agents et commandes depuis ce repo |

## review-pr

Script standalone pour reviewer des PRs dans un worktree isolé.

```bash
# Installation
sudo cp tools/review-pr /usr/local/bin/

# Usage
review-pr                       # Review la branche courante
review-pr 42                    # Review PR #42
review-pr feat/login            # Review une branche
review-pr --list                # Liste les sessions actives
review-pr --cleanup             # Supprime les worktrees de review
```

## Structure

```
agents/                    # Agents (fichiers plats .md)
  architecte.md            # Aline — product architect
  dev.md                   # Alicia — lead developer
  dev-react.md             # Maelle — React/TypeScript
  dev-tauri.md             # Lune — Tauri v2 / Rust
  dev-godot.md             # Sciel — Godot 4 / GDScript
  dev-stories.md           # Gustave — Storybook stories
  qa.md                    # Clea — QA lead
  reviewer.md              # Verso — code guardian
  refactor.md              # Esquie — refactoring analyst
  fixer.md                 # Monoco — targeted fixes
  nestjs-backend.md        # Golgra — NestJS backend specialist
  uxui.md                  # Renoir — UX/UI architect
commands/                  # Commandes slash (non-agent)
  team.md
  workflow.md
  list-us.md
  update-agents.md
  archive-us.md
  commit.md
  create-pr.md
tools/                     # Scripts CLI standalone
  review-pr
resources/                 # Ressources de référence
  react-guidelines.md
  godot-guidelines.md
  ux-guidelines.md
  us-template-react.md
  us-template-tauri.md
  us-template-godot.md
```
