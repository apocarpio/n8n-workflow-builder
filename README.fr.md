# n8n Workflow Builder

> **Langue / Language / Lingua:** [English](README.md) · [Italiano](README.it.md) · **Français**

Génère des workflows n8n à partir d'instructions en langage naturel, avec Google Gemini comme LLM et n8n-mcp comme tool server. Interface web basée sur LibreChat, tout dans Docker et portable d'un Mac à l'autre.

**Auteur :** Simone Mureddu
**Licence :** MIT

---

## C'est quoi

Ce projet te permet d'écrire des trucs comme *"crée-moi un workflow qui récupère les commandes Stripe toutes les heures et les envoie sur Slack"* — et il le construit, le valide et le déploie directement sur ton instance n8n.

Sous le capot : Google Gemini (free tier) + [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) + LibreChat comme UI.

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

## Prérequis

- macOS (testé) ou Linux
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installé et actif
- Une [clé API Google Gemini](https://aistudio.google.com/apikey) — gratuite avec un compte Google
- n8n — si tu l'as pas, l'installer te l'ajoute dans le stack

## Installation

```bash
git clone https://github.com/apocarpio/n8n-workflow-builder.git
cd n8n-workflow-builder
./setup.sh
```

Ce que fait l'installer :

1. Vérifie Docker
2. Détecte si n8n tourne déjà sur `:5678`
3. Sinon, l'ajoute au stack avec un volume persistent
4. Demande les clés API (Gemini + n8n)
5. Génère la config LibreChat
6. Pull les images et démarre tout

À la fin, ouvre http://localhost:3080.

## Première utilisation

1. Crée un compte local sur LibreChat
2. Sélectionne **Google** comme endpoint
3. Choisis un modèle Gemini dans la liste — elle est chargée en live depuis l'API Google, donc tu vois toujours ce qui est dispo (`gemini-2.5-pro` pour la qualité, dernier `gemini-flash` pour la vitesse/quota)
4. Active le serveur MCP `n8n-mcp` dans le chat (checkbox en bas)
5. Écris ta demande

Exemple : *"Crée un workflow qui reçoit un webhook, extrait le champ email du body et envoie un message sur Slack dans le channel #support"*

## System prompt (recommandé)

Pour de meilleurs résultats, colle le contenu de `prompts/n8n-builder-system-prompt-extended.md` dans le champ **"Préfixe du prompt"** (panneau paramètres du modèle dans LibreChat).

Deux versions sont dispo :

- `n8n-builder-system-prompt.md` — 693 lignes, ~85% de couverture
- `n8n-builder-system-prompt-extended.md` — 966 lignes, ~95% de couverture

## Commandes utiles

```bash
docker compose logs -f           # logs en live
docker compose restart           # redémarre
docker compose down              # stop (garde les données)
./uninstall.sh                   # supprime tout
```

## Structure

```
.
├── docker-compose.yml           # Stack Docker
├── librechat.yaml.template      # Config LibreChat avec placeholders
├── setup.sh                     # Installer interactif
├── uninstall.sh                 # Suppression propre
├── .env.example                 # Template de config
├── prompts/                     # System prompts pour Gemini
│   ├── n8n-builder-system-prompt.md
│   └── n8n-builder-system-prompt-extended.md
└── README.md
```

## Troubleshooting

**LibreChat démarre pas** → `docker compose logs librechat`. Vérifie que `JWT_SECRET` est bien rempli dans `.env`.

**"Aucun résultat" en cherchant Gemini** → il manque `GOOGLE_KEY` dans `.env`. Relance `./setup.sh`.

**n8n-mcp répond pas** → check que `N8N_API_KEY` soit bonne. Test rapide :
```bash
curl -H "X-N8N-API-KEY: $KEY" http://localhost:5678/api/v1/workflows
```

**Port 5678 déjà occupé** → t'as déjà un n8n qui tourne ailleurs. L'installer devrait le détecter, sinon : `docker ps | grep 5678`.

## Crédits

- [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) par Romuald Czlonkowski — le tool MCP qui rend tout ça possible
- [LibreChat](https://github.com/danny-avila/LibreChat) par Danny Avila — l'interface web multi-LLM
- [n8n](https://n8n.io/) — la plateforme d'automatisation

## Licence

MIT. Fais ce que tu veux, attribution appréciée.
