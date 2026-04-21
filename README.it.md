# n8n Workflow Builder

> **Lingua / Language / Langue:** [English](README.md) · **Italiano** · [Français](README.fr.md)

Genera workflow n8n a partire da istruzioni in linguaggio naturale, usando Google Gemini come LLM e n8n-mcp come tool server. Interfaccia web basata su LibreChat, tutto containerizzato e portatile tra Mac.

**Autore:** Simone Mureddu
**Licenza:** MIT

---

## Cosa è

Questo progetto ti permette di scrivere cose come *"creami un workflow che ogni ora preleva gli ordini da Stripe e li manda su Slack"* — e te lo costruisce, lo valida e te lo installa direttamente sulla tua istanza n8n.

Sotto il cofano: Google Gemini (free tier) + [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) + LibreChat come UI.

## Architettura

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

## Prerequisiti

- macOS (testato) o Linux
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installato e attivo
- Una **Google Gemini API Key** — gratis con account Google
- n8n — se non ce l'hai, l'installer te lo aggiunge nello stack

### Come ottenere le API key

**Gemini API Key:**

1. Vai su [Google AI Studio](https://aistudio.google.com/apikey)
2. Accedi con il tuo account Google
3. Clicca **"Create API key"**
4. Copia la chiave (inizia con `AIza...`)

Non serve billing — il free tier è sufficiente per usare questo progetto.

**n8n API Key:**

1. Apri la tua istanza n8n su `http://localhost:5678`
2. Vai in **Settings** (icona ingranaggio, in basso a sinistra)
3. Clicca **API** nel menu a sinistra
4. Clicca **"Create an API key"**
5. Dai un nome (es. `workflow-builder`) e copia la chiave

Se non hai ancora n8n, l'installer ne avvia uno per te — crea la API key dopo e rilancia `./setup.sh`.

## Installazione

```bash
git clone https://github.com/apocarpio/n8n-workflow-builder.git
cd n8n-workflow-builder
./setup.sh
```

L'installer:

1. Verifica Docker
2. Rileva se n8n è già attivo su `:5678`
3. Se no, lo include nello stack con volume persistente
4. Chiede le API key (Gemini + n8n)
5. Genera la configurazione LibreChat
6. Scarica le immagini e avvia tutto

Al termine apri http://localhost:3080.

## Primo uso

1. Registra un account locale su LibreChat
2. Seleziona **Google** come endpoint
3. Scegli un modello Gemini dalla lista — viene caricata live dall'API Google, quindi vedi sempre quelli disponibili. Di solito `gemini-2.5-pro` per la qualità o l'ultimo `gemini-flash` per velocità/quota
4. Attiva il server MCP `n8n-mcp` nella chat (checkbox in basso)
5. Scrivi la tua richiesta

Esempio: *"Creami un workflow che riceve un webhook, estrae il campo email dal body e manda un messaggio a Slack nel canale #support"*

## System prompt (consigliato)

Per risultati migliori, incolla il contenuto di `prompts/n8n-builder-system-prompt-extended.md` nel campo **"Préfixe du prompt"** (pannello parametri del modello in LibreChat).

Ci sono due versioni:

- `n8n-builder-system-prompt.md` — versione standard, ~85% di copertura
- `n8n-builder-system-prompt-extended.md` — versione estesa, ~95% di copertura (consigliata)

## Comandi utili

```bash
docker compose logs -f           # log live
docker compose restart           # riavvio
docker compose down              # stop (mantiene i dati)
./uninstall.sh                   # rimuove tutto
```

## Struttura

```
.
├── docker-compose.yml           # Stack Docker
├── librechat.yaml.template      # Config LibreChat con placeholder
├── setup.sh                     # Installer interattivo
├── uninstall.sh                 # Rimozione pulita
├── .env.example                 # Template configurazione
├── prompts/                     # System prompt per Gemini
│   ├── n8n-builder-system-prompt.md
│   └── n8n-builder-system-prompt-extended.md
└── README.md
```

## Troubleshooting

**LibreChat non parte** → `docker compose logs librechat`. Verifica che `JWT_SECRET` sia popolato nel `.env`.

**"Aucun résultat" cercando Gemini** → manca `GOOGLE_KEY` nel `.env`. Rilancia `./setup.sh`.

**n8n-mcp non risponde** → controlla che `N8N_API_KEY` sia valida. Test veloce:
```bash
curl -H "X-N8N-API-KEY: $KEY" http://localhost:5678/api/v1/workflows
```

**Porta 5678 già occupata** → hai già un n8n attivo altrove. L'installer dovrebbe rilevarlo, altrimenti: `docker ps | grep 5678`.

## Crediti

- [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) by Romuald Czlonkowski — il tool MCP che rende tutto possibile
- [LibreChat](https://github.com/danny-avila/LibreChat) by Danny Avila — l'interfaccia web multi-LLM
- [n8n](https://n8n.io/) — la piattaforma di automazione

## Licenza

MIT. Fai quello che vuoi, attribuzione apprezzata.
