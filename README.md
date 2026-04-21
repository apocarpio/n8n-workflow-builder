# n8n Workflow Builder

> **Language / Lingua / Langue:** **English** · [Italiano](README.it.md) · [Français](README.fr.md)

Generate n8n workflows from natural language, using Google Gemini as the LLM and n8n-mcp as the tool server. Web UI powered by LibreChat, fully containerized and portable across Macs.

**Author:** Simone Mureddu
**License:** MIT

---

## What it is

This project lets you write things like *"build me a workflow that pulls Stripe orders every hour and sends them to Slack"* — and it builds it, validates it, and deploys it directly to your n8n instance.

Under the hood: Google Gemini (free tier) + [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) + LibreChat as UI.

## Architecture

```
┌─────────────┐       ┌──────────────┐       ┌────────────┐
│  Browser    │ ────► │  LibreChat   │ ────► │  Gemini    │
│ localhost   │       │  (Docker)    │       │  API       │
│  :3080      │       │              │       └────────────┘
└─────────────┘       │              │
                      │   ┌──────────┴──┐    ┌────────────┐
                      │   │  n8n-mcp    │──► │   n8n      │
                      │   │  (stdio)    │    │  :5678     │
                      │   └─────────────┘    └────────────┘
                      └──────────────┘
```

## Requirements

- macOS (tested) or Linux
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- A **Google Gemini API Key** — free with any Google account
- n8n — if you don't have one, the installer adds it to the stack

### Getting your API keys

**Gemini API Key:**

1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click **"Create API key"**
4. Copy the key (starts with `AIza...`)

No billing required — the free tier is enough to use this project.

**n8n API Key:**

1. Open your n8n instance at `http://localhost:5678`
2. Go to **Settings** (gear icon, bottom-left)
3. Click **API** in the left menu
4. Click **"Create an API key"**
5. Give it a name (e.g. `workflow-builder`) and copy the key

If you don't have n8n yet, the installer will start one for you — create the API key afterwards and re-run `./setup.sh`.

## Installation

```bash
git clone https://github.com/apocarpio/n8n-workflow-builder.git
cd n8n-workflow-builder
./setup.sh
```

The installer:

1. Checks Docker
2. Detects whether n8n is already running on `:5678`
3. If not, includes it in the stack with a persistent volume
4. Asks for your API keys (Gemini + n8n)
5. Generates the LibreChat configuration
6. Pulls the images and starts everything

When it's done, open http://localhost:3080.

## First use

1. Register a local account on LibreChat
2. Select **Google** as the endpoint
3. Pick a Gemini model from the list — it's fetched live from the Google API so you always see what's available (`gemini-2.5-pro` for quality, latest `gemini-flash` for speed/quota)
4. Enable the `n8n-mcp` MCP server in the chat (checkbox at the bottom)
5. Write your request

Example: *"Build a workflow that receives a webhook, extracts the email field from the body, and sends a message to the Slack #support channel"*

## System prompt (recommended)

For better results, paste the content of `prompts/n8n-builder-system-prompt-extended.md` into the **"Prompt prefix"** field (model parameters panel in LibreChat).

Two versions are available:

- `n8n-builder-system-prompt.md` — standard version, ~85% coverage
- `n8n-builder-system-prompt-extended.md` — extended version, ~95% coverage (recommended)

## Useful commands

```bash
docker compose logs -f           # live logs
docker compose restart           # restart
docker compose down              # stop (keeps data)
./uninstall.sh                   # remove everything
```

## Structure

```
.
├── docker-compose.yml           # Docker stack
├── librechat.yaml.template      # LibreChat config with placeholders
├── setup.sh                     # Interactive installer
├── uninstall.sh                 # Clean removal
├── .env.example                 # Config template
├── prompts/                     # System prompts for Gemini
│   ├── n8n-builder-system-prompt.md
│   └── n8n-builder-system-prompt-extended.md
└── README.md
```

## Troubleshooting

**LibreChat won't start** → `docker compose logs librechat`. Check that `JWT_SECRET` is set in `.env`.

**"No results" when searching for Gemini** → `GOOGLE_KEY` is missing from `.env`. Re-run `./setup.sh`.

**n8n-mcp not responding** → check that `N8N_API_KEY` is valid. Quick test:
```bash
curl -H "X-N8N-API-KEY: $KEY" http://localhost:5678/api/v1/workflows
```

**Port 5678 already in use** → you already have n8n running somewhere else. The installer should detect it, otherwise: `docker ps | grep 5678`.

## Credits

- [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) by Romuald Czlonkowski — the MCP tool that makes this possible
- [LibreChat](https://github.com/danny-avila/LibreChat) by Danny Avila — the multi-LLM web interface
- [n8n](https://n8n.io/) — the automation platform

## License

MIT. Do what you want, attribution appreciated.
