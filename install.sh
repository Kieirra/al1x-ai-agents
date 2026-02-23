#!/usr/bin/env bash
set -euo pipefail

REPO="Kieirra/al1x-ai-agents"
BRANCH="main"
API_URL="https://api.github.com/repos/${REPO}/contents/agents?ref=${BRANCH}"
RAW_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
COMMANDS_DIR=".claude/commands"
AGENTS_DIR=".claude/agents"
RESOURCES_DIR=".claude/resources"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

# Vérifier les dépendances
command -v curl >/dev/null 2>&1 || error "curl est requis mais non installé."

info "Installation des agents al1x-ai-agents..."

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

# Télécharger chaque agent dans commands/ et agents/
COUNT=0
for FILE in $AGENT_FILES; do
    NAME="${FILE%.md}"
    info "Téléchargement de $FILE..."

    # Télécharger le fichier une seule fois
    CONTENT=$(curl -fsSL "${RAW_URL}/agents/${FILE}") \
        || { echo -e "${RED}[ERREUR]${NC} Échec du téléchargement de $FILE"; continue; }

    # Installer comme skill dans commands/ (invocable via /nom)
    echo "$CONTENT" > "${COMMANDS_DIR}/${FILE}"

    # Installer comme subagent dans agents/nom/SKILL.md (auto-délégation)
    mkdir -p "${AGENTS_DIR}/${NAME}"
    echo "$CONTENT" > "${AGENTS_DIR}/${NAME}/SKILL.md"

    success "$NAME installé (skill + subagent)"
    COUNT=$((COUNT + 1))
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
success "Installation terminée ! ${COUNT} agent(s) installé(s)"
info "Skills (slash commands) : ${COMMANDS_DIR}/"
info "Subagents (auto-délégation) : ${AGENTS_DIR}/"
info "Ressources : ${RESOURCES_DIR}/"
info "Utilise /update-agents dans Claude Code pour mettre à jour."
