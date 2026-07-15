#!/usr/bin/env bash
set -euo pipefail

REPO="Kieirra/al1x-ai-agents"
BRANCH="main"
ARCHIVE_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

# Commandes livrées par les anciennes versions, désormais migrées en skills.
LEGACY_CLAUDE_COMMANDS="archive-us commit create-pr list-us team update-agents workflow"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERREUR]${NC} $1" >&2; exit 1; }

usage() {
    cat <<'EOF'
Usage: install.sh [--claude|--codex|--all] [--local]

Plateforme :
  --claude  Installe les agents et skills Claude Code (défaut)
  --codex   Installe les agents et skills Codex
  --all     Installe Claude Code et Codex

Portée :
  (défaut)  Installation globale dans les dossiers utilisateur
  --local   Installation dans le projet courant
EOF
}

command -v curl >/dev/null 2>&1 || error "curl est requis mais non installé."
command -v tar >/dev/null 2>&1 || error "tar est requis mais non installé."

INSTALL_CLAUDE=0
INSTALL_CODEX=0
PLATFORM_SELECTED=0
INSTALL_MODE="global"

for arg in "$@"; do
    case "$arg" in
        --claude)
            INSTALL_CLAUDE=1
            PLATFORM_SELECTED=1
            ;;
        --codex)
            INSTALL_CODEX=1
            PLATFORM_SELECTED=1
            ;;
        --all)
            INSTALL_CLAUDE=1
            INSTALL_CODEX=1
            PLATFORM_SELECTED=1
            ;;
        --local)
            INSTALL_MODE="local"
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            error "Option inconnue : ${arg}. Utilise --help pour voir les options."
            ;;
    esac
done

# Rétrocompatibilité : sans option de plateforme, conserver l'installation Claude.
if [ "$PLATFORM_SELECTED" -eq 0 ]; then
    INSTALL_CLAUDE=1
fi

TEMP_DIR=""
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

resolve_source() {
    if [ -n "${AL1X_SOURCE_DIR:-}" ]; then
        [ -d "$AL1X_SOURCE_DIR/claude" ] || error "AL1X_SOURCE_DIR ne contient pas claude/."
        [ -d "$AL1X_SOURCE_DIR/codex" ] || error "AL1X_SOURCE_DIR ne contient pas codex/."
        SOURCE_ROOT="$AL1X_SOURCE_DIR"
        return
    fi

    TEMP_DIR=$(mktemp -d)
    info "Téléchargement de ${REPO}@${BRANCH}..."
    curl -fsSL "$ARCHIVE_URL" -o "$TEMP_DIR/source.tar.gz" \
        || error "Impossible de télécharger l'archive GitHub."
    tar -xzf "$TEMP_DIR/source.tar.gz" -C "$TEMP_DIR"
    SOURCE_ROOT="$TEMP_DIR/${REPO##*/}-${BRANCH}"
    [ -d "$SOURCE_ROOT/claude" ] || error "Archive GitHub invalide : claude/ absent."
    [ -d "$SOURCE_ROOT/codex" ] || error "Archive GitHub invalide : codex/ absent."
}

sync_directory() {
    local source_dir="$1"
    local target_dir="$2"
    local label="$3"
    local manifest="$target_dir/.al1x-ai-agents.manifest"
    local new_manifest
    local item
    local name
    local count=0

    [ -d "$source_dir" ] || error "Source absente : ${source_dir}"
    mkdir -p "$target_dir"
    new_manifest=$(mktemp)

    if [ -f "$manifest" ]; then
        while IFS= read -r name; do
            [ -n "$name" ] || continue
            if [ ! -e "$source_dir/$name" ] && [ -e "$target_dir/$name" ]; then
                rm -rf "$target_dir/$name"
                warn "${label} obsolète supprimé : ${name}"
            fi
        done < "$manifest"
    fi

    for item in "$source_dir"/*; do
        [ -e "$item" ] || continue
        name=$(basename "$item")
        rm -rf "$target_dir/$name"
        cp -R "$item" "$target_dir/$name"
        printf '%s\n' "$name" >> "$new_manifest"
        count=$((count + 1))
    done

    mv "$new_manifest" "$manifest"
    success "${label} : ${count} élément(s) installé(s) dans ${target_dir}"
}

migrate_legacy_claude() {
    local base_dir="$1"
    local commands_dir="$base_dir/commands"
    local removed=0
    local name
    local item

    [ -d "$commands_dir" ] || return 0

    # Commandes utilitaires historiques : suppression par nom connu.
    for name in $LEGACY_CLAUDE_COMMANDS; do
        if [ -f "$commands_dir/$name.md" ]; then
            rm -f "$commands_dir/$name.md"
            removed=$((removed + 1))
        fi
    done

    # Wrappers d'orchestrateurs générés par d'anciennes versions : détectés par
    # leur contenu (référence à un fichier agent al1x), pour ne jamais toucher
    # une commande personnelle sans rapport.
    for item in "$commands_dir"/*.md; do
        [ -f "$item" ] || continue
        if grep -q '\.claude/agents/' "$item" 2>/dev/null; then
            rm -f "$item"
            removed=$((removed + 1))
        fi
    done

    if [ "$removed" -gt 0 ]; then
        warn "Anciennes commandes Claude supprimées : ${removed} (migrées en skills)"
    fi

    if [ -d "$commands_dir" ] && [ -z "$(ls -A "$commands_dir")" ]; then
        rmdir "$commands_dir"
    fi
}

install_claude() {
    local base_dir
    if [ "$INSTALL_MODE" = "local" ]; then
        base_dir=".claude"
    else
        base_dir="${HOME}/.claude"
    fi

    info "Installation Claude Code (${INSTALL_MODE})..."
    migrate_legacy_claude "$base_dir"
    sync_directory "$SOURCE_ROOT/claude/agents" "$base_dir/agents" "Agents Claude"
    sync_directory "$SOURCE_ROOT/claude/skills" "$base_dir/skills" "Skills Claude"
    sync_directory "$SOURCE_ROOT/resources" "$base_dir/resources" "Ressources Claude"
}

install_codex() {
    local codex_dir
    local skills_dir
    if [ "$INSTALL_MODE" = "local" ]; then
        codex_dir=".codex"
        skills_dir=".agents/skills"
    else
        codex_dir="${HOME}/.codex"
        skills_dir="${HOME}/.agents/skills"
    fi

    info "Installation Codex (${INSTALL_MODE})..."
    sync_directory "$SOURCE_ROOT/codex/agents" "$codex_dir/agents" "Agents Codex"
    sync_directory "$SOURCE_ROOT/codex/skills" "$skills_dir" "Skills Codex"
    sync_directory "$SOURCE_ROOT/resources" "$codex_dir/resources" "Ressources Codex"
}

resolve_source

if [ "$INSTALL_CLAUDE" -eq 1 ]; then
    install_claude
fi

if [ "$INSTALL_CODEX" -eq 1 ]; then
    install_codex
fi

echo ""
success "Installation terminée."
if [ "$INSTALL_CLAUDE" -eq 1 ]; then
    info "Claude : utilise /team, /architecte, /dev ou /update-agents."
fi
if [ "$INSTALL_CODEX" -eq 1 ]; then
    info "Codex : utilise \$team, \$architecte, \$dev ou \$update-agents."
    info "Ouvre une nouvelle session Codex pour recharger les agents et la configuration."
fi
