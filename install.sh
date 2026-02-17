#!/usr/bin/env bash
set -euo pipefail

REPO="Kieirra/al1x-ai-agents"
BRANCH="main"
API_URL="https://api.github.com/repos/${REPO}/contents/agents?ref=${BRANCH}"
RAW_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
AGENTS_DIR=".claude/agents"
COMMANDS_DIR=".claude/commands"

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
mkdir -p "$AGENTS_DIR"
mkdir -p "$COMMANDS_DIR"

# Récupérer la liste des agents depuis l'API GitHub
info "Récupération de la liste des agents..."
AGENTS_JSON=$(curl -fsSL "$API_URL") || error "Impossible de contacter l'API GitHub."

# Extraire les noms de fichiers .md
AGENT_FILES=$(echo "$AGENTS_JSON" | grep -oP '"name"\s*:\s*"\K[^"]+\.md' || true)

if [ -z "$AGENT_FILES" ]; then
    error "Aucun agent trouvé dans le repo."
fi

# Télécharger chaque agent
COUNT=0
for FILE in $AGENT_FILES; do
    info "Téléchargement de $FILE..."
    curl -fsSL "${RAW_URL}/agents/${FILE}" -o "${AGENTS_DIR}/${FILE}" \
        || { echo -e "${RED}[ERREUR]${NC} Échec du téléchargement de $FILE"; continue; }
    success "$FILE installé"
    COUNT=$((COUNT + 1))
done

# Télécharger les commandes
info "Installation des commandes..."
COMMANDS_API_URL="https://api.github.com/repos/${REPO}/contents/commands?ref=${BRANCH}"
COMMANDS_JSON=$(curl -fsSL "$COMMANDS_API_URL") || error "Impossible de récupérer les commandes."
COMMAND_FILES=$(echo "$COMMANDS_JSON" | grep -oP '"name"\s*:\s*"\K[^"]+\.md' || true)

for FILE in $COMMAND_FILES; do
    curl -fsSL "${RAW_URL}/commands/${FILE}" -o "${COMMANDS_DIR}/${FILE}" \
        || { echo -e "${RED}[ERREUR]${NC} Échec du téléchargement de $FILE"; continue; }
    success "Commande /${FILE%.md} installée"
done

echo ""
success "Installation terminée ! ${COUNT} agent(s) installé(s) dans ${AGENTS_DIR}/"
info "Utilise /update-agents dans Claude Code pour mettre à jour les agents."
