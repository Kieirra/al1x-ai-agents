#!/usr/bin/env bash
set -euo pipefail

REPO="Kieirra/al1x-ai-agents"
BRANCH="main"
API_URL="https://api.github.com/repos/${REPO}/contents/agents?ref=${BRANCH}"
RAW_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

# Vérifier les dépendances
command -v curl >/dev/null 2>&1 || error "curl est requis mais non installé."

# Mode d'installation : --local pour le projet courant, global par défaut
INSTALL_MODE="global"
for arg in "$@"; do
    case "$arg" in
        --local) INSTALL_MODE="local" ;;
        --help|-h)
            echo "Usage: install.sh [--local]"
            echo "  (défaut)  Installe dans ~/.claude/ (tous les projets)"
            echo "  --local   Installe dans .claude/  (projet courant)"
            exit 0
            ;;
    esac
done

if [ "$INSTALL_MODE" = "local" ]; then
    BASE_DIR=".claude"
    INSTALL_LABEL="locale ($(pwd)/.claude/)"
else
    BASE_DIR="$HOME/.claude"
    INSTALL_LABEL="globale ($HOME/.claude/)"
fi

COMMANDS_DIR="${BASE_DIR}/commands"
AGENTS_DIR="${BASE_DIR}/agents"
RESOURCES_DIR="${BASE_DIR}/resources"

info "Installation ${INSTALL_LABEL}..."

# Créer les dossiers
mkdir -p "$COMMANDS_DIR"
mkdir -p "$AGENTS_DIR"
mkdir -p "$RESOURCES_DIR"

# Récupérer la liste des agents depuis l'API GitHub
info "Récupération de la liste des agents..."
AGENTS_JSON=$(curl -fsSL "$API_URL") || error "Impossible de contacter l'API GitHub."

# Extraire les noms de fichiers .md
AGENT_FILES=$(echo "$AGENTS_JSON" | grep -oP '"name"\s*:\s*"\K[^"]+\.md' || true)

if [ -z "$AGENT_FILES" ]; then
    error "Aucun agent trouvé dans le repo."
fi

# Migration : nettoyer l'ancien format agents/nom/SKILL.md
for FILE in $AGENT_FILES; do
    NAME="${FILE%.md}"
    if [ -f "${AGENTS_DIR}/${NAME}/SKILL.md" ]; then
        rm -rf "${AGENTS_DIR}/${NAME}"
        warn "$NAME : ancien format SKILL.md supprimé (migration → fichier plat)"
    fi
done

# Télécharger chaque agent en fichier plat (agents/nom.md)
AGENT_COUNT=0
for FILE in $AGENT_FILES; do
    NAME="${FILE%.md}"
    info "Téléchargement de $FILE..."

    CONTENT=$(curl -fsSL "${RAW_URL}/agents/${FILE}") \
        || { echo -e "${RED}[ERREUR]${NC} Échec du téléchargement de $FILE"; continue; }

    echo "$CONTENT" > "${AGENTS_DIR}/${FILE}"

    # Créer une commande /nom pour les orchestrateurs (pas les sub-agents)
    IS_SUB=$(echo "$CONTENT" | sed -n '/^---$/,/^---$/p' | grep -c 'Sub-agent' || true)
    if [ "$IS_SUB" = "0" ]; then
        DESCRIPTION=$(echo "$CONTENT" | sed -n '/^description:/{ s/^description: //; p; }')
        cat > "${COMMANDS_DIR}/${FILE}" << EOF
${DESCRIPTION}

Read the file "${AGENTS_DIR}/${FILE}" and follow all its instructions exactly as your own.
EOF
        success "$NAME installé (@${NAME} + /${NAME})"
    else
        # Supprimer l'ancienne commande si elle existe
        if [ -f "${COMMANDS_DIR}/${FILE}" ]; then
            rm -f "${COMMANDS_DIR}/${FILE}"
        fi
        success "$NAME installé (@${NAME})"
    fi

    AGENT_COUNT=$((AGENT_COUNT + 1))
done

# Télécharger les commandes (workflow, list-us, update-agents)
info "Installation des commandes..."
COMMANDS_API_URL="https://api.github.com/repos/${REPO}/contents/commands?ref=${BRANCH}"
COMMANDS_JSON=$(curl -fsSL "$COMMANDS_API_URL") || error "Impossible de récupérer les commandes."
COMMAND_FILES=$(echo "$COMMANDS_JSON" | grep -oP '"name"\s*:\s*"\K[^"]+\.md' || true)

for FILE in $COMMAND_FILES; do
    curl -fsSL "${RAW_URL}/commands/${FILE}" -o "${COMMANDS_DIR}/${FILE}" \
        || { echo -e "${RED}[ERREUR]${NC} Échec du téléchargement de $FILE"; continue; }
    success "Commande /${FILE%.md} installée"
done

# Télécharger les ressources (ux-guidelines, etc.)
info "Installation des ressources..."
RESOURCES_API_URL="https://api.github.com/repos/${REPO}/contents/resources?ref=${BRANCH}"
RESOURCES_JSON=$(curl -fsSL "$RESOURCES_API_URL" 2>/dev/null) || RESOURCES_JSON=""

if [ -n "$RESOURCES_JSON" ]; then
    RESOURCE_FILES=$(echo "$RESOURCES_JSON" | grep -oP '"name"\s*:\s*"\K[^"]+\.md' || true)
    for FILE in $RESOURCE_FILES; do
        curl -fsSL "${RAW_URL}/resources/${FILE}" -o "${RESOURCES_DIR}/${FILE}" \
            || { echo -e "${RED}[ERREUR]${NC} Échec du téléchargement de $FILE"; continue; }
        success "Ressource ${FILE} installée"
    done
fi

echo ""
success "Installation ${INSTALL_LABEL} terminée ! ${AGENT_COUNT} agent(s) installé(s)"
info "Agents (@nom) : ${AGENTS_DIR}/"
info "Commandes (/nom) : ${COMMANDS_DIR}/"
info "Ressources : ${RESOURCES_DIR}/"
if [ "$INSTALL_MODE" = "global" ]; then
    info "Les agents sont disponibles dans tous tes projets Claude Code."
fi
info "Utilise /update-agents dans Claude Code pour mettre à jour."
