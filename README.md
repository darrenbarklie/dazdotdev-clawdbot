# Clawdbot Server

Self-hosted [Clawdbot](https://docs.clawd.bot) gateway for WhatsApp and Telegram, deployed via Coolify.

## Quick Start

### 1. Push to GitHub

```bash
git init
git add .
git commit -m "Initial clawdbot setup"
git remote add origin git@github.com:YOUR_USERNAME/clawdbot-server.git
git push -u origin main
```

### 2. Deploy on Coolify

1. **Add Application** → Select your GitHub repo
2. **Build Pack**: Dockerfile
3. **Port**: `18789`
4. **Environment Variables** (add in Coolify):
   ```
   ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx
   CLAWDBOT_GATEWAY_TOKEN=<generate with: openssl rand -hex 32>
   TELEGRAM_BOT_TOKEN=<from @BotFather>  # optional
   TZ=Europe/London
   ```
5. **Persistent Storage** (critical!):
   - `/home/clawdbot/.clawdbot` → Volume for state/sessions
   - `/home/clawdbot/clawd` → Volume for workspace

### 3. Connect WhatsApp

Once deployed, access the dashboard at `https://your-domain:18789/`

**Option A: Via Dashboard**
1. Open dashboard → Settings → Providers
2. Click "Login" for WhatsApp
3. Scan QR code with WhatsApp → Linked Devices

**Option B: Via SSH into container**
```bash
# In Coolify, open terminal for the container
clawdbot providers login
# Scan the QR code shown
```

### 4. Connect Telegram

1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Create a new bot: `/newbot`
3. Copy the token
4. Add `TELEGRAM_BOT_TOKEN` to Coolify environment variables
5. Restart the container

### 5. Pair Your Account

When you first DM the bot, you'll receive a pairing code. Approve it:

```bash
# Via container terminal
clawdbot pairing list whatsapp
clawdbot pairing approve whatsapp <code>

clawdbot pairing list telegram
clawdbot pairing approve telegram <code>
```

Or approve via the dashboard.

---

## Coolify Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | ✅ | Your Anthropic API key |
| `CLAWDBOT_GATEWAY_TOKEN` | Recommended | Secures the dashboard |
| `TELEGRAM_BOT_TOKEN` | For Telegram | From @BotFather |
| `TZ` | Optional | Timezone (default: UTC) |

### Persistent Volumes

**These are essential** — without them, you'll lose WhatsApp sessions on every restart:

| Container Path | Description |
|----------------|-------------|
| `/home/clawdbot/.clawdbot` | Config, sessions, credentials |
| `/home/clawdbot/clawd` | Workspace (AGENTS.md, memory) |

### Networking

- **Port**: `18789` (HTTP/WebSocket)
- The gateway binds to `0.0.0.0` inside the container (LAN mode)
- Coolify handles HTTPS termination

---

## Commands Reference

Access these via Coolify's terminal or SSH:

```bash
# Check status
clawdbot health
clawdbot daemon status

# Provider management
clawdbot providers status
clawdbot providers login          # WhatsApp QR

# Pairing
clawdbot pairing list whatsapp
clawdbot pairing approve whatsapp <code>

# Send a test message
clawdbot message send --to +447123456789 --message "Hello from Clawdbot"

# Diagnostics
clawdbot doctor
```

---

## Chat Commands

Once connected, these work in any chat:

| Command | Description |
|---------|-------------|
| `/new` | Start a new session |
| `/reset` | Reset current session |
| `/model` | Show/change AI model |
| `/model list` | List available models |

---

## Customisation

### Changing the AI Model

Edit `config/clawdbot.json`:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-sonnet-4-20250514"
      }
    }
  }
}
```

Available models include:
- `anthropic/claude-sonnet-4-20250514` (default)
- `anthropic/claude-opus-4-20250514`
- `anthropic/claude-haiku-3-5-20241022`

### Agent Instructions

Edit `/home/clawdbot/clawd/AGENTS.md` in the container (or mount your own):

```markdown
# Agent Instructions

You are a helpful assistant. Be concise in chat responses.

## Your personality
- Friendly and professional
- Direct answers, no waffle
```

---

## Troubleshooting

### WhatsApp disconnects after restart
- Ensure `/home/clawdbot/.clawdbot` is mounted as a persistent volume
- Check volume permissions

### "No auth configured" error
- Verify `ANTHROPIC_API_KEY` is set correctly
- Check `/home/clawdbot/.clawdbot/agents/main/agent/auth-profiles.json` exists

### Pairing codes not being approved
```bash
clawdbot pairing list whatsapp
clawdbot pairing approve whatsapp <code>
```

### View logs
```bash
# In container
cat /tmp/clawdbot/clawdbot-*.log

# Or via Coolify's log viewer
```

### Full reset
```bash
# Nuclear option - removes all sessions
rm -rf /home/clawdbot/.clawdbot/agents/*/sessions/*
# Then re-login to WhatsApp
clawdbot providers login
```

---

## Security Notes

1. **Gateway Token**: Always set `CLAWDBOT_GATEWAY_TOKEN` in production
2. **Pairing Policy**: Default is `pairing` — unknown DMs require approval
3. **HTTPS**: Let Coolify handle SSL termination
4. **API Keys**: Use Coolify's encrypted environment variables

---

## Links

- [Clawdbot Docs](https://docs.clawd.bot)
- [Getting Started](https://docs.clawd.bot/start/getting-started)
- [Docker Guide](https://docs.clawd.bot/install/docker)
- [Configuration](https://docs.clawd.bot/gateway/configuration)
