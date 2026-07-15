# al1x-ai-agents

Une équipe d'agents spécialisés compatible avec **Claude Code** et **Codex** : architecture, développement, QA, review, refactoring et UX/UI.

Les noms sont inspirés des personnages de **Clair Obscur: Expedition 33**.

> Ce repo n'est pas ouvert aux contributions. Maintenu par [@Kieirra](https://github.com/Kieirra) pour usage personnel, partagé publiquement tel quel.

## Installation

### macOS / Linux (bash)

```bash
# Claude Code et Codex
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh \
  | bash -s -- --all

# Claude Code uniquement — comportement par défaut
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh \
  | bash -s -- --claude

# Codex uniquement
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh \
  | bash -s -- --codex
```

Ajouter `--local` pour installer dans le projet courant :

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh \
  | bash -s -- --all --local
```

### Windows (PowerShell)

```powershell
# Claude Code et Codex
irm https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.ps1 | iex

# Ou avec des options (télécharger puis exécuter)
$s = irm https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.ps1
& ([scriptblock]::Create($s)) -All          # Claude Code et Codex
& ([scriptblock]::Create($s)) -Claude        # Claude Code uniquement (défaut)
& ([scriptblock]::Create($s)) -Codex         # Codex uniquement
& ([scriptblock]::Create($s)) -All -Local    # dans le projet courant
```

`install.ps1` reproduit à l'identique le comportement de `install.sh` (mêmes plateformes, mêmes dossiers cibles, même fusion de `config.toml`).

| Plateforme | Global | Local |
|---|---|---|
| Claude agents | `~/.claude/agents/` | `.claude/agents/` |
| Claude skills | `~/.claude/skills/` | `.claude/skills/` |
| Codex agents | `~/.codex/agents/` | `.codex/agents/` |
| Codex skills | `~/.agents/skills/` | `.agents/skills/` |

L'installation Codex garantit `agents.max_depth >= 2` et `agents.max_threads >= 8` sans réduire des valeurs plus élevées ni remplacer le reste de `config.toml`.

Mise à jour : `/update-agents` dans Claude, `$update-agents` dans Codex, ou relancer l'installation `--all`.

## Les agents

### Orchestrateurs

| Agent | Pseudo | Rôle |
|---|---|---|
| `architecte` | **Aline** | Product architect — explorations tech/UX/approches, QCM, wireframe ASCII, rédaction d'US |
| `dev` | **Alicia** | Lead developer — détecte la techno, dispatche aux spécialistes, parallélise front et back |
| `qa` | **Clea** | QA lead — tests spec-driven, stories Storybook, vérification visuelle, checklist manuelle |
| `reviewer` | **Verso** | Code guardian — conventions, bugs, sécurité et conformité |
| `refactor` | **Esquie** | Refactoring analyst — DRY, dead code, simplification, nommage et guidelines |
| `uxui` | **Renoir** | UX/UI architect — audits, brainstorms, wireframes et frameworks UX/UI |

Invocation directe :

| Claude Code | Codex |
|---|---|
| `/architecte`, `/dev`, `/qa`, `/reviewer`, `/refactor`, `/uxui` | `$architecte`, `$dev`, `$qa`, `$reviewer`, `$refactor`, `$uxui` |

Les agents peuvent aussi être lancés comme sub-agents par leur nom. Dans Claude, les orchestrateurs disposent d'un fallback interne lorsqu'ils sont eux-mêmes sub-agents. Dans Codex, la profondeur `2` permet la délégation imbriquée.

### Spécialistes

| Agent | Pseudo | Appelé par | Spécialité |
|---|---|---|---|
| `dev-react` | **Maelle** | `dev` | React / TypeScript |
| `dev-tauri` | **Lune** | `dev` | Tauri v2 / Rust / React |
| `dev-godot` | **Sciel** | `dev` | Godot 4 / GDScript |
| `dev-stories` | **Gustave** | `qa` | Storybook stories |
| `nestjs-backend` | **Golgra** | `dev` | NestJS backend |
| `fixer` | **Monoco** | `reviewer`, `refactor` | Corrections ciblées et refactoring iso-fonctionnel |

## Pipeline

```text
React / Tauri : architecte → dev → refactor → qa → reviewer
Godot :         architecte → dev → refactor → reviewer
```

Si le reviewer demande des changements : `fixer` → `qa` si nécessaire → `reviewer`, avec trois boucles maximum.

Le skill `/team` dans Claude ou `$team` dans Codex lance le pipeline complet.

### Statuts de l'US

| Stack | Progression |
|---|---|
| React / Tauri | `ready` → `in-progress` → `done` → `refactored` → `stories-done` → `reviewed` |
| Godot | `ready` → `in-progress` → `done` → `refactored` → `reviewed` |

## Skills

| Claude | Codex | Description |
|---|---|---|
| `/team` | `$team` | Pipeline autonome complet |
| `/workflow` | `$workflow` | État du pipeline et prochaine étape |
| `/list-us` | `$list-us` | Liste les User Stories |
| `/archive-us` | `$archive-us` | Archive les User Stories terminées |
| `/commit` | `$commit` | Crée des commits conventionnels |
| `/create-pr` | `$create-pr` | Crée une Pull Request minimaliste |
| `/check-stories` | `$check-stories` | Vérifie visuellement les stories Storybook |
| `/update-agents` | `$update-agents` | Met à jour les installations Claude et Codex |

## review-pr

Script standalone pour reviewer des PRs dans un worktree isolé.

```bash
sudo cp tools/review-pr /usr/local/bin/

review-pr                       # Review la branche courante
review-pr 42                    # Review PR #42
review-pr feat/login            # Review une branche
review-pr --list                # Liste les sessions actives
review-pr --cleanup             # Supprime les worktrees de review
```

## Structure

```text
claude/
  agents/                       # Agents Claude : Markdown + YAML
  skills/                       # Skills Claude
codex/
  agents/                       # Agents Codex : TOML
  skills/                       # Skills Codex
resources/                      # Guidelines et templates communs
tools/                          # Scripts CLI standalone
CLAUDE.md                       # Instructions de maintenance Claude
AGENTS.md                       # Instructions de maintenance Codex
install.sh                      # Installateur macOS/Linux (bash)
install.ps1                     # Installateur Windows (PowerShell)
```
