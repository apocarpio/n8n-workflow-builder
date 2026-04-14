#!/bin/bash
# ============================================================
# n8n Workflow Builder — Setup Script v2
# ============================================================
# Author:  Simone Mureddu
# Repo:    https://github.com/apocarpio/n8n-workflow-builder
# License: MIT
# ============================================================
# Usage: ./setup.sh
# Detects whether n8n is already installed, otherwise adds it to the stack.
# ============================================================

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BOLD}╔════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   n8n Workflow Builder — Setup              ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════╝${NC}"
echo ""

# 1. Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found${NC}"
    echo "  Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
    exit 1
fi

if ! docker info &> /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running${NC}"
    echo "  Start Docker Desktop and try again."
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker is running"

# 2. Detect existing n8n
USE_EXISTING_N8N=false
N8N_COMPOSE_PROFILE=""

if curl -s -o /dev/null -w "%{http_code}" http://localhost:5678 2>/dev/null | grep -qE "200|301|302|401"; then
    echo -e "${GREEN}✓${NC} n8n already running on localhost:5678"
    USE_EXISTING_N8N=true
else
    echo -e "${YELLOW}⚠${NC} No n8n detected on localhost:5678"
    echo ""
    read -p "Install n8n in the same stack? [Y/n]: " INSTALL_N8N
    INSTALL_N8N=${INSTALL_N8N:-Y}
    if [[ "$INSTALL_N8N" =~ ^[Yy]$ ]]; then
        N8N_COMPOSE_PROFILE="--profile with-n8n"
        echo -e "${GREEN}✓${NC} n8n will be included in the stack"
    else
        echo -e "${YELLOW}⚠${NC} Install n8n separately before using the builder"
        echo "  Guide: https://docs.n8n.io/hosting/installation/docker/"
        exit 1
    fi
fi

echo ""

# 3. Load or create .env
if [ -f .env ]; then
    echo -e "${GREEN}✓${NC} .env file already present"
    source .env
else
    echo -e "${BOLD}Initial configuration${NC}"
    cp .env.example .env

    echo ""
    echo -e "${BOLD}[1/2] Gemini API Key${NC}"
    echo "Get one from: https://aistudio.google.com/apikey"
    read -p "Paste your Gemini API Key: " GEMINI_KEY
    if [ -z "$GEMINI_KEY" ]; then
        echo -e "${RED}✗ API Key required${NC}"
        exit 1
    fi
    if [[ ! "$GEMINI_KEY" =~ ^AIza ]]; then
        echo -e "${YELLOW}⚠ Key doesn't start with 'AIza' — continuing anyway${NC}"
    fi
    sed -i.bak "s|your-gemini-api-key-here|${GEMINI_KEY}|g" .env
    rm -f .env.bak

    echo ""
    if [ "$USE_EXISTING_N8N" = true ]; then
        echo -e "${BOLD}[2/2] n8n API Key${NC}"
        echo "Create the key in n8n: Settings > API > Create API Key"
        read -p "Paste your n8n API Key: " N8N_KEY
        if [ -z "$N8N_KEY" ]; then
            echo -e "${YELLOW}⚠ No key provided — the builder will not be able to talk to n8n${NC}"
        else
            sed -i.bak "s|your-n8n-api-key-here|${N8N_KEY}|g" .env
            rm -f .env.bak
        fi
    else
        echo -e "${BOLD}[2/2] n8n API Key${NC}"
        echo "n8n will start now. You'll need to create the account and the API key afterwards."
        echo "We'll configure it later — re-run ./setup.sh with the key."
    fi

    JWT_SEC=$(openssl rand -hex 32 2>/dev/null || echo "fallback-jwt-$(date +%s)-$RANDOM")
    JWT_REF=$(openssl rand -hex 32 2>/dev/null || echo "fallback-refresh-$(date +%s)-$RANDOM")
    CREDS_K=$(openssl rand -hex 32 2>/dev/null || echo "0123456789abcdef0123456789abcdef")
    CREDS_I=$(openssl rand -hex 8 2>/dev/null || echo "0123456789abcdef")

    sed -i.bak "s|changeme-jwt-secret|${JWT_SEC}|g" .env
    sed -i.bak "s|changeme-jwt-refresh-secret|${JWT_REF}|g" .env
    sed -i.bak "s|changeme-creds-key-32chars-hex|${CREDS_K}|g" .env
    sed -i.bak "s|changeme-creds-iv-16chars-hex|${CREDS_I}|g" .env
    rm -f .env.bak

    echo ""
    echo -e "${GREEN}✓${NC} .env file created"
fi

# 4. Generate librechat.yaml
echo ""
echo -e "${BOLD}Generating librechat.yaml...${NC}"

source .env
N8N_URL="${N8N_HOST_URL:-http://host.docker.internal:5678}"
N8N_KEY="${N8N_API_KEY:-}"

cp librechat.yaml.template librechat.yaml
sed -i.bak "s|__N8N_HOST_URL__|${N8N_URL}|g" librechat.yaml
sed -i.bak "s|__N8N_API_KEY__|${N8N_KEY}|g" librechat.yaml
rm -f librechat.yaml.bak

echo -e "${GREEN}✓${NC} librechat.yaml ready"

# 5. Start containers
echo ""
echo -e "${BOLD}Starting containers...${NC}"
echo "  (first run: image pull takes ~2-5 min)"

docker compose down 2>/dev/null || true
docker compose ${N8N_COMPOSE_PROFILE} pull
docker compose ${N8N_COMPOSE_PROFILE} up -d

# 6. Wait for services
echo ""
echo -e "${BOLD}Waiting for LibreChat...${NC}"
for i in {1..60}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:${LIBRECHAT_PORT:-3080} 2>/dev/null | grep -qE "200|301|302"; then
        echo -e "${GREEN}✓${NC} LibreChat is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        echo -e "${YELLOW}⚠${NC} LibreChat not responding after 60s"
        echo "  Check logs: docker compose logs -f librechat"
    fi
    sleep 2
done

if [ "$USE_EXISTING_N8N" = false ] && [ -n "$N8N_COMPOSE_PROFILE" ]; then
    echo -e "${BOLD}Waiting for n8n...${NC}"
    for i in {1..60}; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:5678 2>/dev/null | grep -qE "200|301|302"; then
            echo -e "${GREEN}✓${NC} n8n is ready"
            break
        fi
        [ $i -eq 60 ] && echo -e "${YELLOW}⚠${NC} n8n not responding"
        sleep 2
    done
fi

# 7. Final message
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Setup complete                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}${BLUE}Web UI:${NC}           http://localhost:${LIBRECHAT_PORT:-3080}"
echo -e "  ${BOLD}${BLUE}n8n:${NC}              http://localhost:5678"
echo ""

if [ "$USE_EXISTING_N8N" = false ] && [ -n "$N8N_COMPOSE_PROFILE" ] && [ -z "$N8N_KEY" ]; then
    echo -e "${YELLOW}─── NEXT STEPS ───${NC}"
    echo ""
    echo "  1. Open http://localhost:5678 and create the n8n account"
    echo "  2. Go to Settings > API > Create API Key"
    echo "  3. Add the key to .env (N8N_API_KEY=...)"
    echo "  4. Re-run: ./setup.sh"
    echo ""
fi

echo -e "  ${BOLD}First use of LibreChat:${NC}"
echo "  1. Open the web UI"
echo "  2. Register (local account, for you only)"
echo "  3. Select 'Google' as the endpoint"
echo "  4. Pick a Gemini model from the list (loaded live from Google)"
echo "  5. Enable the MCP server 'n8n-mcp' in the chat"
echo "  6. Type: 'Build me a workflow that...'"
echo ""
echo -e "  ${BOLD}System prompt (recommended):${NC}"
echo "  Paste the content of prompts/n8n-builder-system-prompt-extended.md"
echo "  into the 'Prompt prefix' field (model parameters panel)"
echo ""
echo -e "  ${BOLD}Useful commands:${NC}"
echo "  docker compose logs -f       # live logs"
echo "  docker compose restart       # restart"
echo "  ./uninstall.sh               # remove everything"
echo ""
