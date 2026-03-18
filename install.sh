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

# Télécharger chaque agent — routage super-agent vs sub-agent via frontmatter
SUPER_COUNT=0
SUB_COUNT=0
for FILE in $AGENT_FILES; do
    NAME="${FILE%.md}"
    info "Téléchargement de $FILE..."

    # Télécharger le fichier une seule fois
    CONTENT=$(curl -fsSL "${RAW_URL}/agents/${FILE}") \
        || { echo -e "${RED}[ERREUR]${NC} Échec du téléchargement de $FILE"; continue; }

    # Parser le champ user-invocable du frontmatter YAML
    # Format attendu : "user-invocable: true" ou "user-invocable: false" entre les délimiteurs ---
    USER_INVOCABLE=$(echo "$CONTENT" | sed -n '/^---$/,/^---$/p' | grep 'user-invocable' | grep -oP '(true|false)' || echo "true")

    if [ "$USER_INVOCABLE" = "true" ]; then
        # Super-agent : SKILL.md = source unique de vérité, commande = redirection légère
        mkdir -p "${AGENTS_DIR}/${NAME}"
        echo "$CONTENT" > "${AGENTS_DIR}/${NAME}/SKILL.md"

        # Extraire la description du frontmatter pour la commande
        DESCRIPTION=$(echo "$CONTENT" | sed -n '/^description:/{ s/^description: //; p; }')
        cat > "${COMMANDS_DIR}/${FILE}" << EOF
${DESCRIPTION}

Read the file "${AGENTS_DIR}/${NAME}/SKILL.md" and follow all its instructions exactly as your own.
EOF
        success "$NAME installé (super-agent : skill → SKILL.md)"
        SUPER_COUNT=$((SUPER_COUNT + 1))
    else
        # Sub-agent : installer uniquement comme subagent (pas de slash command)
        # Nettoyer l'ancienne commande si elle existe (migration depuis l'ancien système)
        if [ -f "${COMMANDS_DIR}/${FILE}" ]; then
            rm -f "${COMMANDS_DIR}/${FILE}"
            warn "$NAME : ancienne commande /${NAME} supprimée (migration sub-agent)"
        fi
        mkdir -p "${AGENTS_DIR}/${NAME}"
        echo "$CONTENT" > "${AGENTS_DIR}/${NAME}/SKILL.md"
        success "$NAME installé (sub-agent uniquement)"
        SUB_COUNT=$((SUB_COUNT + 1))
    fi
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
TOTAL=$((SUPER_COUNT + SUB_COUNT))
success "Installation ${INSTALL_LABEL} terminée ! ${TOTAL} agent(s) installé(s) (${SUPER_COUNT} super-agents, ${SUB_COUNT} sub-agents)"
info "Super-agents (slash commands) : ${COMMANDS_DIR}/"
info "Sub-agents (auto-délégation) : ${AGENTS_DIR}/"
info "Ressources : ${RESOURCES_DIR}/"
if [ "$INSTALL_MODE" = "global" ]; then
    info "Les agents sont disponibles dans tous tes projets Claude Code."
fi
info "Utilise /update-agents dans Claude Code pour mettre à jour."
