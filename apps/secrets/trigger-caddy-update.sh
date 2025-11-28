#!/bin/bash
# =============================================================================
# Trigger GitHub Actions Workflow for Caddy Configuration
# =============================================================================
# This script is called by Coolify post-deployment hook to trigger
# the GitHub Actions workflow that updates Caddy configuration
# Uses GitHub App authentication (organization-approved)
# Uses Node.js (available in Infisical container) for JWT generation
# =============================================================================

set -e

echo "🔐 Using Node.js for GitHub App authentication..."

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

# Download the auth script from the repository
curl -fsSL "https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$REF/apps/secrets/github-app-auth.js" -o /tmp/github-app-auth.js

# Run the auth script to get access token
ACCESS_TOKEN=$(node /tmp/github-app-auth.js 2>&1)

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo "❌ Failed to get access token"
    echo "Debug: $ACCESS_TOKEN"
    exit 1
fi

echo "✅ GitHub App authentication successful"

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
