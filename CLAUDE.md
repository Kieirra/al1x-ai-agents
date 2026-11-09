# Instructions pour Claude Code

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
.claude-plugin/ # Plugin et marketplace Claude Code (pointent vers claude/)
CLAUDE.md       # Instructions Claude pour maintenir ce dépôt
AGENTS.md       # Instructions Codex pour maintenir ce dépôt
CHANGELOG.md    # Une entrée par commit (version des agents)
install.sh      # Installateur Claude/Codex (macOS/Linux)
install.ps1     # Installateur Claude/Codex (Windows PowerShell)
```

## Synchronisation Claude / Codex

Chaque agent et chaque skill existe en deux versions :

- Claude : `claude/agents/` et `claude/skills/`
- Codex : `codex/agents/` et `codex/skills/`

Lors de toute modification :

1. Modifier la version Claude et la version Codex correspondante.
2. Conserver la même logique fonctionnelle dans les deux versions.
3. Adapter uniquement le format, les chemins, les outils et les instructions propres à la plateforme.
4. Vérifier qu'aucun agent ou skill correspondant ne manque.
5. Mettre à jour le README si le comportement public ou le catalogue change.
6. Tester `install.sh` dans les modes `--claude`, `--codex` et `--all`, et répercuter tout changement de comportement dans `install.ps1` (miroir Windows).
7. Ajouter l'entrée en tête de `CHANGELOG.md` (`## AAAA-MM-JJ · titre court` + une puce d'une ligne par changement visible pour l'utilisateur des agents ; le fichier est affiché tel quel par `/update-agents`). Si l'entrée du haut n'est pas encore commitée (`git diff CHANGELOG.md`), la compléter au lieu d'en créer une : un commit = une entrée = une version.
8. Agent Claude ajouté, renommé ou supprimé : mettre à jour la liste `agents` de `.claude-plugin/plugin.json`, puis lancer `claude plugin validate .`.

Une modification n'est pas terminée tant que les deux versions ne sont pas synchronisées.

## Conventions Claude

- Agents : `claude/agents/<nom>.md` avec frontmatter YAML.
- Conserver les champs `name`, `description`, `model`, `color` et `memory`.
- Skills : `claude/skills/<nom>/SKILL.md`.
- Les workflows à effet de bord utilisent `disable-model-invocation: true`.
- Employer le nom actuel `Agent tool`. `Task` n'est conservé que dans les textes historiques ou comme alias de compatibilité.
- Les orchestrateurs doivent documenter un fallback interne lorsqu'ils sont eux-mêmes exécutés comme sub-agents et ne peuvent pas déléguer.

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
