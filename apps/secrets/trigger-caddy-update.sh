#!/bin/bash
# =============================================================================
# Trigger GitHub Actions Workflow for Caddy Configuration
# =============================================================================
# This script is called by Coolify post-deployment hook to trigger
# the GitHub Actions workflow that updates Caddy configuration
# =============================================================================

set -e

# GitHub repository info
REPO_OWNER="ubvs"
REPO_NAME="ubivis-tools"
WORKFLOW_FILE="caddy-update.yml"
REF="main"

# GitHub PAT should be passed as environment variable
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN environment variable not set"
    exit 1
fi

echo "🚀 Triggering GitHub Actions workflow to update Caddy..."

# Trigger workflow via GitHub API
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/$WORKFLOW_FILE/dispatches" \
    -d "{\"ref\":\"$REF\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "204" ]; then
    echo "✅ GitHub Actions workflow triggered successfully!"
    exit 0
else
    echo "❌ Failed to trigger workflow (HTTP $HTTP_CODE)"
    echo "$RESPONSE"
    exit 1
fi
