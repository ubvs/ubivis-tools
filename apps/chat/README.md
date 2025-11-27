# Rocket.Chat with Keycloak OAuth

Rocket.Chat deployment with Keycloak SSO integration using the official Docker image.

## Architecture

- **Base Image**: `registry.rocket.chat/rocketchat/rocket.chat:7.12.1`
- **Secrets**: Managed via Infisical (fetched at runtime)
- **OAuth**: Configured via environment variables (no patches needed)
- **Networking**: Uses `extra_hosts` to enable container-to-host communication

## Quick Start (Development)

### 1. Configure Infisical

Copy the template and add your Infisical credentials:

```bash
cp .devcontainer/.env.template .devcontainer/.env
# Edit .env with your Infisical project credentials
```

### 2. Add Secrets to Infisical

In your Infisical project, add these secrets:
- `KEYCLOAK_CLIENT_SECRET` - OAuth client secret from Keycloak
- `ADMIN_PASS` - Rocket.Chat admin password
- `ADMIN_EMAIL` - Rocket.Chat admin email

### 3. Start Services

```bash
cd .devcontainer
docker compose up -d
```

Access:
- **Rocket.Chat**: http://localhost:3000
- **Keycloak**: http://localhost:8080
- **Infisical**: http://localhost:8081

## Keycloak Configuration

### Prerequisites

Keycloak client must be configured in the `ubivis` realm:
- **Client ID**: `chat`
- **Client Protocol**: `openid-connect`
- **Access Type**: `confidential`
- **Valid Redirect URIs**: `http://localhost:3000/_oauth/keycloak`

### Critical: extra_hosts

The `extra_hosts` directive makes `localhost` inside the container resolve to the host machine:

```yaml
extra_hosts:
  - "localhost:host-gateway"
```

This allows both browser and server to use `localhost:8080` for Keycloak.

## Production Deployment

### 1. Update URLs via Infisical

For production, set these **in Infisical**, not in docker-compose:

- `ROOT_URL` → `https://chat.yourdomain.com`
- `KEYCLOAK_URL` → `https://keycloak.yourdomain.com`

The startup script `scripts/start-with-secrets.sh` reads these from Infisical and maps them to the appropriate `OVERWRITE_SETTING_Accounts_OAuth_Custom_Keycloak_*` variables at runtime.

### 2. Update Keycloak Client Redirect URI

In Keycloak admin, update the `chat` client Valid Redirect URIs to:

```text
https://chat.yourdomain.com/_oauth/keycloak
```

### 3. (Optional) Run OAuth Init Script

If for some reason the env-based configuration does not apply correctly, you can still run the MongoDB init script as a fallback:

```bash
nx init-oauth chat
# or manually:
docker exec <mongodb-container> mongosh rocketchat /path/to/scripts/init-keycloak-oauth.js
```

## File Structure

```
apps/chat/
├── .devcontainer/
│   ├── Dockerfile           # Installs Infisical SDK, overrides entrypoint to run startup script
│   ├── docker-compose.yml   # Non-sensitive config (Mongo URL, NATS, TEST_MODE, etc.) + .env mount
│   ├── .env                 # Infisical credentials only (no app secrets)
│   └── .env.template        # Template for Infisical machine identity + docs of required secrets
├── scripts/
│   ├── fetch-secrets.js      # Fetches all secrets from Infisical and prints KEY=VALUE
│   ├── start-with-secrets.sh # Startup script: fetches from Infisical, exports env, starts Rocket.Chat
│   └── init-keycloak-oauth.js # MongoDB init script (backup)
├── patches/                  # Reserved for future patches (currently empty)
└── README.md
```

## Troubleshooting

### Secrets Not Loading
1. Check Infisical is running: `docker ps | grep infisical`
2. Verify credentials in `.env` match your Infisical machine identity
3. Check Rocket.Chat logs: `docker compose logs rocketchat`

### OAuth Login Fails
1. Check Keycloak client redirect URIs include `http://localhost:3000/_oauth/keycloak`
2. Verify `KEYCLOAK_CLIENT_SECRET` exists in Infisical
3. Check Rocket.Chat logs for OAuth errors

### "Restart login cookie not found"
- Ensure `extra_hosts` is configured in docker-compose.yml
- All Keycloak URLs should use `localhost:8080` (not container hostname)

### Container Can't Reach Keycloak or Infisical
- Verify network is `devcontainer_app-network`
- Check services are running: `docker ps`
