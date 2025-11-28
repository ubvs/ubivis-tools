#!/bin/bash
# =============================================================================
# Infisical (Secrets) - Post-Deployment Caddy Configuration
# =============================================================================
# This script configures Caddy reverse proxy after Coolify deployment
# Can be run on host or from within a container (via nsenter)
# =============================================================================

set -e

# Configuration
DOMAIN="ubivis-secrets.ideasnet.app"
BACKEND_PORT="8080"
# Note: We use the actual container name instead of alias because
# Coolify places containers on its own network where aliases don't resolve
CADDY_CONFIG_DIR="/data/coolify/proxy/caddy/dynamic"
CADDY_CONFIG_FILE="${CADDY_CONFIG_DIR}/ubivis-secrets.caddy"

# Auto-detect Coolify network name
APP_NETWORK=$(docker network ls --format '{{.Name}}' | grep '^gw8g80g4' | head -1)

echo "🚀 Configuring Caddy for Infisical (Secrets)..."

# Find the actual backend container name (Coolify-generated pattern)
BACKEND_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^backend-gw8g80g4kog0c4so4o0o0k48-[0-9]+$' | head -1)

if [ -z "$BACKEND_CONTAINER" ]; then
    echo "❌ Error: Backend container not found"
    echo "Available containers:"
    docker ps --format '{{.Names}}'
    exit 1
fi

echo "✓ Found backend container: $BACKEND_CONTAINER"

# Ensure Caddy proxy is connected to the app network
echo "✓ Connecting Caddy proxy to app network..."
docker network connect "$APP_NETWORK" coolify-proxy 2>/dev/null || echo "  Already connected"

# Create Caddy configuration using actual container name
echo "✓ Creating Caddy configuration..."
cat > "$CADDY_CONFIG_FILE" <<EOF
${DOMAIN} {
    reverse_proxy ${BACKEND_CONTAINER}:${BACKEND_PORT}
}
EOF

echo "✓ Caddy config created at: $CADDY_CONFIG_FILE"
cat "$CADDY_CONFIG_FILE"

# Restart Caddy to apply configuration
echo "✓ Restarting Caddy proxy..."
docker restart coolify-proxy

echo ""
echo "✅ Deployment complete!"
echo "🌐 Infisical is now accessible at: https://${DOMAIN}"
echo ""
echo "📝 To verify:"
echo "   curl -I https://${DOMAIN}"
