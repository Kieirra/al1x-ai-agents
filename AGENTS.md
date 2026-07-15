# Instructions pour Codex

## But du dépôt

Ce dépôt centralise et distribue la même équipe d'agents pour Claude Code et Codex. Il ne contient pas de code applicatif.

## Architecture

```text
claude/
  agents/       # Agents Claude : Markdown + frontmatter YAML
  skills/       # Skills Claude : <nom>/SKILL.md
codex/
  agents/       # Agents Codex : TOML
  skills/       # Skills Codex : <nom>/SKILL.md
resources/      # Guidelines et templates communs
CLAUDE.md       # Instructions Claude pour maintenir ce dépôt
AGENTS.md       # Instructions Codex pour maintenir ce dépôt
install.sh      # Installateur Claude/Codex (macOS/Linux)
install.ps1     # Installateur Claude/Codex (Windows PowerShell)
```

## Synchronisation Claude / Codex

Chaque agent et chaque skill existe en deux versions :

- Claude : `claude/agents/` et `claude/skills/`
- Codex : `codex/agents/` et `codex/skills/`

Lors de toute modification :

1. Modifier la version Codex et la version Claude correspondante.
2. Conserver la même logique fonctionnelle dans les deux versions.
3. Adapter uniquement le format, les chemins, les outils et les instructions propres à la plateforme.
4. Vérifier qu'aucun agent ou skill correspondant ne manque.
5. Mettre à jour le README si le comportement public ou le catalogue change.
6. Tester `install.sh` dans les modes `--claude`, `--codex` et `--all`, et répercuter tout changement de comportement dans `install.ps1` (miroir Windows).

Une modification n'est pas terminée tant que les deux versions ne sont pas synchronisées.

## Conventions Codex

- Agents : `codex/agents/<nom>.toml`.
- Chaque agent définit au minimum `name`, `description` et `developer_instructions`.
- Omettre `model` pour hériter du modèle de la session ; utiliser `model_reasoning_effort` seulement quand le rôle le justifie.
- Skills : `codex/skills/<nom>/SKILL.md` avec un frontmatter portable `name` + `description`.
- Employer les capacités Codex de manière sémantique : déléguer à un agent nommé et actualiser le plan disponible, sans figer un nom d'outil interne non documenté.
- Les orchestrateurs Codex documentent un fallback interne lorsqu'ils ne peuvent pas déléguer.
- L'installateur ne modifie pas `~/.codex/config.toml`.
- Les ressources Codex sont résolues dans `.codex/resources/`, puis `~/.codex/resources/`.

## Installation

```bash
./install.sh --claude
./install.sh --codex
./install.sh --all
```

Ajouter `--local` pour installer dans le projet courant. Sans option de plateforme, l'installateur conserve le comportement historique `--claude`.

## Interdictions

- Ne jamais ajouter de code applicatif.
- Ne jamais modifier une seule plateforme sans synchroniser l'autre.
- Ne jamais dupliquer les fichiers de `resources/` dans les dossiers de plateforme.
