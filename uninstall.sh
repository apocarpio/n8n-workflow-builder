#!/bin/bash
# ============================================================
# n8n Workflow Builder — Uninstall
# ============================================================
# Author: Simone Mureddu
# Repo:   https://github.com/apocarpio/n8n-workflow-builder
# ============================================================
# Removes containers, volumes and local configuration
# ============================================================

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BOLD}n8n Workflow Builder — Uninstall${NC}"
echo ""
echo -e "${YELLOW}This script will remove:${NC}"
echo "  - containers (librechat, mongodb, meilisearch, n8n if installed)"
echo "  - Docker volumes (chats, data, cache)"
echo "  - .env and librechat.yaml files"
echo ""
read -p "Continue? [y/N]: " CONFIRM
CONFIRM=${CONFIRM:-N}
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

KEEP_N8N_DATA=false
if docker volume ls --format "{{.Name}}" | grep -q "n8n-workflow-builder_n8n_data"; then
    echo ""
    read -p "Keep n8n data (workflows, credentials)? [Y/n]: " KEEP
    KEEP=${KEEP:-Y}
    if [[ "$KEEP" =~ ^[Yy]$ ]]; then
        KEEP_N8N_DATA=true
    fi
fi

echo ""
echo -e "${BOLD}Stopping and removing containers...${NC}"
docker compose --profile with-n8n down 2>/dev/null || docker compose down 2>/dev/null || true

echo -e "${BOLD}Removing volumes...${NC}"
docker volume rm n8n-workflow-builder_mongodb_data 2>/dev/null || true
docker volume rm n8n-workflow-builder_meilisearch_data 2>/dev/null || true
docker volume rm n8n-workflow-builder_librechat_images 2>/dev/null || true
docker volume rm n8n-workflow-builder_librechat_logs 2>/dev/null || true

if [ "$KEEP_N8N_DATA" = false ]; then
    docker volume rm n8n-workflow-builder_n8n_data 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Volumes removed (n8n included)"
else
    echo -e "${GREEN}✓${NC} Volumes removed (n8n data preserved)"
fi

echo -e "${BOLD}Removing local config...${NC}"
rm -f .env librechat.yaml *.bak

echo ""
echo -e "${GREEN}✓ Uninstall complete${NC}"
echo ""
echo "Docker images were NOT removed (for safety). If you want to:"
echo "  docker rmi ghcr.io/danny-avila/librechat:latest"
echo "  docker rmi mongo:7 getmeili/meilisearch:v1.7 docker.n8n.io/n8nio/n8n:latest"
echo ""
