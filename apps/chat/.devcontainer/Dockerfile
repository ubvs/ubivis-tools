# Use official Rocket.Chat image
FROM registry.rocket.chat/rocketchat/rocket.chat:7.12.1

# Switch to root to install dependencies
USER root

# Install Infisical SDK in /app where Rocket.Chat runs
WORKDIR /app
RUN npm install @infisical/sdk

# Copy scripts for fetching secrets and startup
COPY scripts/fetch-secrets.js /app/scripts/fetch-secrets.js
COPY scripts/start-with-secrets.sh /app/scripts/start-with-secrets.sh
RUN chmod +x /app/scripts/start-with-secrets.sh

# Switch back to rocketchat user
USER rocketchat
WORKDIR /app

# Set environment variables
ENV NODE_ENV=production \
    PORT=3000

# Expose port
EXPOSE 3000

# Health check using wget (available in the official image)
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/info || exit 1

# Use startup script that fetches secrets from Infisical then starts Rocket.Chat
CMD ["/bin/sh", "/app/scripts/start-with-secrets.sh"]
