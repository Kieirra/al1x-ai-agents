# al1x-ai-agents

Une équipe d'agents pour **Claude Code** et **Codex** qui couvre tout le cycle d'une feature : spécification, développement (React, Tauri, Godot, NestJS), refactoring, QA et review. Chaque agent a un rôle précis et passe la main au suivant.

Les noms sont inspirés de **Clair Obscur: Expedition 33**.

> Repo personnel de [@Kieirra](https://github.com/Kieirra), partagé tel quel, non ouvert aux contributions.

## Installation

Copier la ligne qui correspond à ton cas.

### Claude Code en plugin (tous OS)

À taper dans Claude Code :

```
/plugin install al --marketplace Kieirra/al1x-ai-agents
```

Les commandes sont alors préfixées : `/al:dev`, `/al:commit`... Ne pas combiner avec les scripts ci-dessous (agents en double).

### macOS / Linux

Claude Code :

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh | bash -s -- --claude
```

Codex :

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh | bash -s -- --codex
```

Claude Code + Codex :

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh | bash -s -- --all
```

Claude Code + Codex, dans le projet courant uniquement :

```bash
curl -fsSL https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.sh | bash -s -- --all --local
```

### Windows (PowerShell)

Claude Code :

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.ps1))) -Claude
```

Codex :

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.ps1))) -Codex
```

Claude Code + Codex :

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.ps1))) -All
```

Claude Code + Codex, dans le projet courant uniquement :

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Kieirra/al1x-ai-agents/main/install.ps1))) -All -Local
```

### Mise à jour

`/update-agents` dans Claude Code (`/al:update-agents` en plugin), `$update-agents` dans Codex. Les nouveautés s'affichent à la fin.

## Utilisation

Dans Codex, remplacer `/` par `$`. En plugin Claude Code, préfixer par `al:`.

### Le cycle d'une feature

```text
/architecte → /dev → /refactor → /qa → /reviewer
```

`/team` enchaîne tout le cycle en autonomie. Pour Godot, `/qa` est sauté.

| Commande | Agent | Rôle |
|---|---|---|
| `/architecte` | Aline | Spécifie la feature et rédige l'US |
| `/dev` | Alicia | Implémente l'US via le spécialiste de la techno |
| `/refactor` | Esquie | Simplifie : DRY, dead code, nommage |
| `/qa` | Clea | Tests et stories Storybook |
| `/reviewer` | Verso | Review : conventions, bugs, sécurité |
| `/uxui` | Renoir | Audits et wireframes UX/UI |

Les spécialistes (React, Tauri, Godot, NestJS, Storybook, corrections) sont appelés automatiquement par ces agents.

Écrire « rapide » ou « sans tests » dans la demande à `/dev` pour qu'il code sans lancer les tests.

### Autres commandes

| Commande | Rôle |
|---|---|
| `/commit` | Commite tous les changements en un seul commit |
| `/commit-mine` | Commite seulement les fichiers modifiés par l'agent courant |
| `/create-pr` | Crée une Pull Request |
| `/plan-to-review` | Ordre de lecture des fichiers pour reviewer vite |
| `/explain` | Explique un morceau de code en 1 à 3 phrases |
| `/workflow` | État du cycle et prochaine étape |
| `/list-us`, `/archive-us` | Liste ou archive les User Stories |
| `/check-stories` | Vérifie visuellement les stories Storybook |

### Bonus : review-pr

Script pour reviewer une PR dans un worktree isolé : `sudo cp tools/review-pr /usr/local/bin/`, puis `review-pr --help`.
