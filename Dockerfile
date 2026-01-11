FROM node:22-bookworm-slim

# Install dependencies for Puppeteer/Chromium (needed for WhatsApp QR) and general utilities
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
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd -m -s /bin/bash clawdbot

# Set up directories with correct permissions
RUN mkdir -p /home/clawdbot/.clawdbot /home/clawdbot/clawd /app/config \
    && chown -R clawdbot:clawdbot /home/clawdbot /app

# Copy config and entrypoint
COPY --chown=clawdbot:clawdbot config/clawdbot.json /app/config/
COPY --chown=clawdbot:clawdbot entrypoint.sh /app/

# Make entrypoint executable
RUN chmod +x /app/entrypoint.sh

# Switch to non-root user
USER clawdbot
WORKDIR /home/clawdbot

# Install clawdbot globally for this user
RUN npm install -g clawdbot@latest

# Expose gateway port
EXPOSE 18789

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

# Use entrypoint script for setup
ENTRYPOINT ["/app/entrypoint.sh"]
