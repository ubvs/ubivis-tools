#!/bin/bash
# =============================================================================
# Trigger GitHub Actions Workflow for Caddy Configuration
# =============================================================================
# This script is called by Coolify post-deployment hook to trigger
# the GitHub Actions workflow that updates Caddy configuration
# Uses GitHub App authentication (organization-approved)
# =============================================================================

set -e

# Detect if we're running inside a container or on host
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "⚠️  Running inside container - installing dependencies"
    # Install required tools
    apk add --no-cache curl jq openssl bash 2>/dev/null || \
    apt-get update && apt-get install -y curl jq openssl 2>/dev/null || true
fi

# GitHub repository info
REPO_OWNER="ubvs"
REPO_NAME="ubivis-tools"
WORKFLOW_FILE="caddy-update.yml"
REF="main"

# GitHub App credentials (set these in Coolify environment variables)
if [ -z "$GITHUB_APP_ID" ] || [ -z "$GITHUB_APP_PRIVATE_KEY" ]; then
    echo "❌ Error: GitHub App credentials not set"
    echo "ℹ️  Required environment variables:"
    echo "    - GITHUB_APP_ID: Your GitHub App ID"
    echo "    - GITHUB_APP_PRIVATE_KEY: Your GitHub App private key (base64 encoded)"
    exit 1
fi

# Generate JWT for GitHub App authentication
generate_jwt() {
    local app_id="$1"
    local private_key="$2"
    
    # Decode private key if base64 encoded
    if echo "$private_key" | grep -q "^[A-Za-z0-9+/]*={0,2}$"; then
        private_key=$(echo "$private_key" | base64 -d 2>/dev/null)
    fi
    
    # Write private key to temp file (openssl needs a file, not stdin)
    local key_file=$(mktemp)
    echo "$private_key" > "$key_file"
    
    local now=$(date +%s)
    local iat=$((now - 60))
    local exp=$((now + 600))
    
    local header='{"alg":"RS256","typ":"JWT"}'
    local payload='{"iat":'$iat',"exp":'$exp',"iss":'$app_id'}'
    
    local header_base64=$(echo -n "$header" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
    local payload_base64=$(echo -n "$payload" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
    local signature_base64=$(echo -n "${header_base64}.${payload_base64}" | openssl dgst -binary -sha256 -sign "$key_file" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
    
    # Clean up temp file
    rm -f "$key_file"
    
    echo "${header_base64}.${payload_base64}.${signature_base64}"
}

echo "🔐 Generating GitHub App JWT..."
JWT=$(generate_jwt "$GITHUB_APP_ID" "$GITHUB_APP_PRIVATE_KEY")

echo "🔑 Getting installation access token..."
INSTALLATION_ID=$(curl -s -H "Authorization: Bearer $JWT" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/app/installations" | jq -r '.[0].id')

if [ -z "$INSTALLATION_ID" ] || [ "$INSTALLATION_ID" = "null" ]; then
    echo "❌ Failed to get installation ID"
    exit 1
fi

ACCESS_TOKEN=$(curl -s -X POST \
    -H "Authorization: Bearer $JWT" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" | jq -r '.token')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo "❌ Failed to get access token"
    exit 1
fi

echo "🚀 Triggering GitHub Actions workflow to update Caddy..."

# Trigger workflow via GitHub API using App access token
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/$WORKFLOW_FILE/dispatches" \
    -d "{\"ref\":\"$REF\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "204" ]; then
    echo "✅ GitHub Actions workflow triggered successfully!"
    echo "ℹ️  Workflow will update Caddy configuration on the server"
    exit 0
else
    echo "❌ Failed to trigger workflow (HTTP $HTTP_CODE)"
    echo "$RESPONSE"
    exit 1
fi
