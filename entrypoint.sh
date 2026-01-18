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

CONFIG_DIR="$HOME/.clawdbot"
CONFIG_FILE="$CONFIG_DIR/clawdbot.json"
WORKSPACE_DIR="$HOME/clawd"

echo "🦞 Clawdbot Gateway Starting..."

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"

# Copy default config if none exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "📝 No config found, creating default configuration..."
    if [ -f "/app/config/clawdbot.json" ]; then
        cp /app/config/clawdbot.json "$CONFIG_FILE"
        echo "✅ Config created at $CONFIG_FILE"
    else
        echo "⚠️  No default config template found, clawdbot will use defaults"
    fi
fi

# Set up auth profiles if API key is provided
if [ -n "$ANTHROPIC_API_KEY" ]; then
    AUTH_DIR="$CONFIG_DIR/agents/main/agent"
    mkdir -p "$AUTH_DIR"
    AUTH_FILE="$AUTH_DIR/auth-profiles.json"

    if [ ! -f "$AUTH_FILE" ]; then
        echo "🔑 Setting up Anthropic API key..."
        cat > "$AUTH_FILE" << EOF
{
  "profiles": {
    "anthropic-api": {
      "provider": "anthropic",
      "type": "api-key",
      "apiKey": "$ANTHROPIC_API_KEY"
    }
  },
  "default": "anthropic-api"
}
EOF
        echo "✅ Auth profile created"
    fi
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

# Update gateway token in config if provided
if [ -n "$CLAWDBOT_GATEWAY_TOKEN" ]; then
    echo "🔐 Gateway token configured"
fi

echo ""
echo "🌐 Dashboard will be available at: http://localhost:18789/"
echo "📱 WhatsApp: Use 'clawdbot providers login' or the dashboard to pair"
echo "🤖 Telegram: Configure bot token in environment variables"
echo ""

# Run the gateway
exec clawdbot gateway --port 18789 --bind lan --verbose --allow-unconfigured "$@"
