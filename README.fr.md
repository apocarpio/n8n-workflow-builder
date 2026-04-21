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
- Une **clé API Google Gemini** — gratuite avec un compte Google
- n8n — si tu l'as pas, l'installer te l'ajoute dans le stack

### Récupérer les clés API

**Clé API Gemini :**

1. Va sur [Google AI Studio](https://aistudio.google.com/apikey)
2. Connecte-toi avec ton compte Google
3. Clique **"Create API key"**
4. Copie la clé (elle commence par `AIza...`)

Pas besoin de billing — le free tier suffit largement.

**Clé API n8n :**

1. Ouvre ton instance n8n sur `http://localhost:5678`
2. Va dans **Settings** (icône engrenage, en bas à gauche)
3. Clique **API** dans le menu de gauche
4. Clique **"Create an API key"**
5. Donne un nom (genre `workflow-builder`) et copie la clé

Si t'as pas encore n8n, l'installer en lance un pour toi — crée la clé API après et relance `./setup.sh`.

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

- `n8n-builder-system-prompt.md` — version standard, ~85% de couverture
- `n8n-builder-system-prompt-extended.md` — version étendue, ~95% de couverture (recommandée)

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
