#!/bin/bash
# =============================================================================
# Infisical (Secrets) - Post-Deployment Caddy Configuration
# =============================================================================
# This script configures Caddy reverse proxy after Coolify deployment
# Must be run on the HOST (not inside a container)
# Triggered by: GitHub Actions workflow
# =============================================================================

set -e

# Configuration
DOMAIN="ubivis-secrets.ideasnet.app"
BACKEND_PORT="8080"
CADDY_CONFIG_DIR="/data/coolify/proxy/caddy/dynamic"
CADDY_CONFIG_FILE="${CADDY_CONFIG_DIR}/ubivis-secrets.caddy"

echo "🚀 Configuring Caddy for Infisical (Secrets)..."

# Find the backend container dynamically
# Look for any container with name pattern: backend-<coolify-app-id>-<timestamp>
BACKEND_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^backend-[a-z0-9]+-[0-9]+$' | grep -v 'coolify' | head -1)

if [ -z "$BACKEND_CONTAINER" ]; then
    echo "❌ Error: Backend container not found"
    echo "Available containers:"
    docker ps --format '{{.Names}}'
    exit 1
fi

echo "✓ Found backend container: $BACKEND_CONTAINER"

# Auto-detect the network the backend container is on
APP_NETWORK=$(docker inspect "$BACKEND_CONTAINER" --format '{{range $net,$v := .NetworkSettings.Networks}}{{$net}}{{end}}' | head -1)

if [ -z "$APP_NETWORK" ]; then
    echo "❌ Error: Could not detect backend container's network"
    exit 1
fi

echo "✓ Detected network: $APP_NETWORK"

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
