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

# Use Node.js to generate JWT and get access token (works in Infisical container)
ACCESS_TOKEN=$(node -e "
const crypto = require('crypto');
const https = require('https');

const appId = process.env.GITHUB_APP_ID;
const privateKeyB64 = process.env.GITHUB_APP_PRIVATE_KEY;
const privateKey = Buffer.from(privateKeyB64, 'base64').toString('utf8');

// Generate JWT
const now = Math.floor(Date.now() / 1000);
const payload = {
  iat: now - 60,
  exp: now + 600,
  iss: appId
};

const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
const payloadB64 = Buffer.from(JSON.stringify(payload)).toString('base64url');
const signatureInput = header + '.' + payloadB64;
const signature = crypto.sign('RSA-SHA256', Buffer.from(signatureInput), privateKey).toString('base64url');
const jwt = signatureInput + '.' + signature;

// Get installation ID
function httpsRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    });
    req.on('error', reject);
    if (postData) req.write(postData);
    req.end();
  });
}

(async () => {
  const installations = await httpsRequest({
    hostname: 'api.github.com',
    path: '/app/installations',
    headers: {
      'Authorization': 'Bearer ' + jwt,
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'Coolify-Deployment'
    }
  });
  
  const installationId = installations[0].id;
  
  const tokenResponse = await httpsRequest({
    hostname: 'api.github.com',
    path: '/app/installations/' + installationId + '/access_tokens',
    method: 'POST',
    headers: {
      'Authorization': 'Bearer ' + jwt,
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'Coolify-Deployment'
    }
  });
  
  console.log(tokenResponse.token);
})();
" 2>&1)

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
