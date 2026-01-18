#!/bin/bash
set -e

echo "🔗 Starting Tailscale..."
tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state &
sleep 2
if [ -n "$TAILSCALE_AUTHKEY" ]; then
    tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname=dazdotdev-clawdbot
    echo "✅ Tailscale connected"
else
    echo "⚠️  No TAILSCALE_AUTHKEY set, skipping Tailscale auth"
fi

echo "🔑 Starting SSH server..."
/usr/sbin/sshd
echo "✅ SSH server running"

CONFIG_DIR="/root/.clawdbot"
CONFIG_FILE="$CONFIG_DIR/clawdbot.json"
WORKSPACE_DIR="/root/clawd"

echo "🦞 Clawdbot Gateway Starting..."

# Create directories
mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$CONFIG_DIR/agents/main/agent"

# Always copy config from image (to pick up updates)
if [ -f "/app/config/clawdbot.json" ]; then
    echo "📝 Copying config from image..."
    cp /app/config/clawdbot.json "$CONFIG_FILE"
    echo "✅ Config created at $CONFIG_FILE"
else
    echo "⚠️  No config template found, clawdbot will use defaults"
fi

# Always set up MiniMax auth from env var
if [ -n "$MINIMAX_API_KEY" ]; then
    AUTH_FILE="$CONFIG_DIR/agents/main/agent/auth-profiles.json"
    echo "🔑 Setting up MiniMax API key..."
    cat > "$AUTH_FILE" << EOF
{
  "version": 1,
  "profiles": {
    "minimax:default": {
      "type": "api_key",
      "provider": "minimax",
      "key": "$MINIMAX_API_KEY"
    }
  }
}
EOF
    echo "✅ MiniMax auth profile created"
else
    echo "⚠️  No MINIMAX_API_KEY set"
fi

# Create basic AGENTS.md if workspace is empty
if [ ! -f "$WORKSPACE_DIR/AGENTS.md" ]; then
    echo "📄 Creating default AGENTS.md..."
    cat > "$WORKSPACE_DIR/AGENTS.md" << 'EOF'
# Agent Instructions

You are a helpful AI assistant running via Clawdbot.

## Capabilities
- Answer questions and have conversations
- Help with coding and technical tasks
- Assist with writing and analysis

## Guidelines
- Be helpful, harmless, and honest
- Ask clarifying questions when needed
- Keep responses concise for chat interfaces
EOF
    echo "✅ AGENTS.md created"
fi

echo ""
echo "🌐 Dashboard will be available at: http://localhost:18789/"
echo "📱 WhatsApp: Use 'clawdbot providers login' or the dashboard to pair"
echo "🤖 Telegram: Configured with allowlist"
echo ""

# Run the gateway
exec clawdbot gateway --port 18789 --bind lan --verbose --allow-unconfigured "$@"
