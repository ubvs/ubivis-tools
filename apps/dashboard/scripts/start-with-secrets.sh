#!/bin/bash

# Homarr Startup Script with Secrets Integration
# Fetch secrets from Infisical using Node.js SDK and inject as env vars before starting Homarr.

set -e

echo "🎯 Homarr Startup with Secrets Integration"
echo "=================================================="

REQUIRED_SECRETS=(
  "AUTH_SECRET"
  "SECRET_ENCRYPTION_KEY"
  "AUTH_OIDC_CLIENT_SECRET"
  "AUTH_OIDC_CLIENT_ID"
  "AUTH_OIDC_ISSUER"
)

echo "🔐 Attempting to fetch secrets from Infisical..."

# Try to fetch secrets using Node.js SDK
echo "🔍 Testing Node.js and dependencies..."
if ! node -e "console.log('Node.js working')" 2>/dev/null; then
  echo "❌ Node.js not available"
  FETCH_EXIT_CODE=1
  SECRETS_OUTPUT="Node.js not available"
else
  echo "✅ Node.js available"
  echo "🔍 Testing Infisical SDK..."
  if ! (cd /app && node -e "import('@infisical/sdk').then(() => console.log('SDK available')).catch(e => { console.error('SDK error:', e.message); process.exit(1) })") 2>/dev/null; then
    echo "❌ Infisical SDK not available, falling back to env vars"
    FETCH_EXIT_CODE=1
    SECRETS_OUTPUT="Infisical SDK not available"
  else
    echo "✅ Infisical SDK available"
    echo "🔍 Fetching secrets..."
    # Run from /app directory to ensure node_modules is accessible
    SECRETS_OUTPUT=$(cd /app && node scripts/fetch-secrets.js 2>&1)
    FETCH_EXIT_CODE=$?
  fi
fi

if [[ $FETCH_EXIT_CODE -eq 0 ]]; then
  echo "✅ Successfully fetched secrets from Infisical"
  
  # Write secrets to a temporary file that can be sourced
  SECRETS_FILE="/tmp/infisical-secrets.env"
  echo "# Secrets fetched from Infisical" > "$SECRETS_FILE"
  
  # Parse the output and write the secrets to file
  while IFS= read -r line; do
    if [[ "$line" == *"="* ]] && [[ "$line" != "SUCCESS:"* ]]; then
      # Write to secrets file and export for current shell
      echo "export $line" >> "$SECRETS_FILE"
      export "$line"
      SECRET_NAME=$(echo "$line" | cut -d'=' -f1)
      echo "   ✅ $SECRET_NAME: Retrieved from Infisical"
    fi
  done <<< "$SECRETS_OUTPUT"
  
else
  echo "❌ Failed to fetch secrets from Infisical:"
  echo "$SECRETS_OUTPUT"
  echo ""
  echo "❌ Cannot start without secrets from Infisical"
  echo "💡 Please ensure:"
  echo "   1. Infisical is running and accessible"
  echo "   2. Machine identity credentials are correct"
  echo "   3. All required secrets exist in Infisical"
  exit 1
fi

# Final validation - check all required secrets are available
echo "🔍 Validating all required secrets are available..."
MISSING=()
for SECRET in "${REQUIRED_SECRETS[@]}"; do
  if [[ -z "${!SECRET}" ]]; then
    MISSING+=("$SECRET")
  else
    echo "   ✅ $SECRET: Available"
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❌ Missing required secrets:"
  printf '   - %s\n' "${MISSING[@]}"
  echo ""
  echo "💡 Make sure these secrets are either:"
  echo "   1. Available in Infisical (preferred)"
  echo "   2. Set as environment variables (fallback)"
  exit 1
fi

echo "📊 All ${#REQUIRED_SECRETS[@]} required secrets are available"

# Clean up Infisical credentials for security
unset INFISICAL_CLIENT_ID
unset INFISICAL_CLIENT_SECRET

echo "🚀 Starting Homarr with injected secrets..."

# Modify run.sh to source our secrets file and not overwrite AUTH_SECRET if it already exists
sed -i '1i# Source Infisical secrets\nif [ -f /tmp/infisical-secrets.env ]; then source /tmp/infisical-secrets.env; fi' /app/run.sh
sed -i 's/export AUTH_SECRET=$(openssl rand -base64 32)/if [ -z "$AUTH_SECRET" ]; then export AUTH_SECRET=$(openssl rand -base64 32); fi/' /app/run.sh

# Start Homarr using the original run.sh script
exec sh run.sh
