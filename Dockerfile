FROM node:22-bookworm-slim

# Install dependencies for Puppeteer/Chromium, SSH, and general utilities
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Install pnpm globally
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install clawdbot globally
RUN pnpm add -g clawdbot@latest

# Create non-root user for security
RUN useradd -m -s /bin/bash clawdbot

# Set up directories with correct permissions
RUN mkdir -p /home/clawdbot/.clawdbot /home/clawdbot/clawd /app/config \
    /run/sshd /home/clawdbot/.ssh /var/lib/tailscale \
    && chown -R clawdbot:clawdbot /home/clawdbot /app

# SSH setup
COPY --chown=clawdbot:clawdbot authorized_keys /home/clawdbot/.ssh/authorized_keys
RUN chmod 700 /home/clawdbot/.ssh && chmod 600 /home/clawdbot/.ssh/authorized_keys

# Copy config and entrypoint
COPY --chown=clawdbot:clawdbot config/clawdbot.json /app/config/
COPY entrypoint.sh /app/

# Make entrypoint executable
RUN chmod +x /app/entrypoint.sh

WORKDIR /home/clawdbot

# Expose gateway port + SSH
EXPOSE 18789 22

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
