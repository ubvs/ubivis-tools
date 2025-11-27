#!/bin/sh

# Rocket.Chat Startup Script - Fetches ONLY secrets from Infisical
# All other config is in docker-compose.yml

set -e

echo "Rocket.Chat Startup with Infisical Secrets"
echo "=============================================="

echo "Fetching secrets from Infisical..."

# Use Node.js SDK to fetch secrets
if [ -f /app/scripts/fetch-secrets.js ]; then
  SECRETS_OUTPUT=$(node /app/scripts/fetch-secrets.js 2>&1)
  FETCH_EXIT_CODE=$?
else
  echo "ERROR: fetch-secrets.js not found"
  FETCH_EXIT_CODE=1
  SECRETS_OUTPUT="Script not found"
fi

if [ "$FETCH_EXIT_CODE" -eq 0 ]; then
  echo "Successfully fetched secrets from Infisical"
  
  # Export secrets to environment
  eval $(echo "$SECRETS_OUTPUT" | grep -v "^SUCCESS:" | grep -v "^#" | grep "=" | sed 's/^/export /')
else
  echo "ERROR: Failed to fetch secrets from Infisical:"
  echo "$SECRETS_OUTPUT"
  exit 1
fi

# Validate required secrets
echo "Validating required secrets..."
MISSING=""

if [ -z "$KEYCLOAK_CLIENT_SECRET" ]; then
  MISSING="$MISSING KEYCLOAK_CLIENT_SECRET"
fi
if [ -z "$ADMIN_PASS" ]; then
  MISSING="$MISSING ADMIN_PASS"
fi
if [ -z "$ADMIN_EMAIL" ]; then
  MISSING="$MISSING ADMIN_EMAIL"
fi

if [ -n "$MISSING" ]; then
  echo "ERROR: Missing required secrets:$MISSING"
  exit 1
fi

echo "All required secrets validated"

# Map Infisical secrets to Rocket.Chat OVERWRITE_SETTING env vars
# The base secrets (ROOT_URL, PORT, ADMIN_*, etc.) are already exported from line 27

# Keycloak OAuth settings
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_id="$KEYCLOAK_CLIENT_ID"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_secret="$KEYCLOAK_CLIENT_SECRET"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_url="$KEYCLOAK_URL"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_token_path="$KEYCLOAK_TOKEN_PATH"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_identity_path="$KEYCLOAK_IDENTITY_PATH"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_authorize_path="$KEYCLOAK_AUTHORIZE_PATH"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_scope="$KEYCLOAK_SCOPE"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_button_label_text="$KEYCLOAK_BUTTON_LABEL_TEXT"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_button_label_color="$KEYCLOAK_BUTTON_LABEL_COLOR"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_button_color="$KEYCLOAK_BUTTON_COLOR"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_login_style="$KEYCLOAK_LOGIN_STYLE"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_username_field="$KEYCLOAK_USERNAME_FIELD"
export OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_merge_users="$KEYCLOAK_MERGE_USERS"

echo "All secrets from Infisical mapped to Rocket.Chat env vars"

# Clean up Infisical credentials for security
unset INFISICAL_CLIENT_ID
unset INFISICAL_CLIENT_SECRET

echo "Starting Rocket.Chat..."
cd /app/bundle
exec node --unhandled-rejections=warn main.js
