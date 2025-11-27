# Keycloak + Infisical Integration

This document describes how to use Infisical to manage secrets for Keycloak (SSOM).

## Overview

The integration uses the **Infisical Agent** as a sidecar container that:
1. Authenticates with Infisical using Machine Identity (Universal Auth)
2. Fetches secrets from a specified project/environment
3. Renders secrets to files that Keycloak can consume
4. Continuously syncs secrets (polling every 60s by default)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Compose                          │
│                                                             │
│  ┌─────────────────┐         ┌─────────────────────────┐   │
│  │ Infisical Agent │         │       Keycloak          │   │
│  │                 │         │                         │   │
│  │  - Fetches      │ shared  │  - Reads secrets from   │   │
│  │    secrets      │ volume  │    /run/secrets/        │   │
│  │  - Renders to   │────────▶│  - Uses env vars        │   │
│  │    files        │         │                         │   │
│  └────────┬────────┘         └─────────────────────────┘   │
│           │                                                 │
│           │ authenticates                                   │
│           ▼                                                 │
│  ┌─────────────────┐                                       │
│  │    Infisical    │ (apps/secrets)                        │
│  │    Server       │                                       │
│  └─────────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
```

## Setup Instructions

### 1. Start Infisical (apps/secrets)

First, ensure Infisical is running:

```bash
cd apps/secrets
docker compose -f docker-compose.dev.yml up -d
```

Access Infisical at: http://localhost:8080

### 2. Create Infisical Project and Secrets

1. **Create a new project** in Infisical (e.g., "SSOM")
2. **Create secrets** in the `/keycloak` path:

| Secret Key | Example Value | Description |
|------------|---------------|-------------|
| `KC_BOOTSTRAP_ADMIN_USERNAME` | `admin` | Keycloak admin username |
| `KC_BOOTSTRAP_ADMIN_PASSWORD` | `<secure-password>` | Keycloak admin password |
| `KC_DB_USERNAME` | `postgres` | Database username |
| `KC_DB_PASSWORD` | `<secure-password>` | Database password |
| `KC_DB_URL` | `jdbc:postgresql://postgres:5432/keycloak` | Database URL |

### 3. Create Machine Identity

1. Go to **Organization Settings** → **Machine Identities**
2. Click **Create Identity**
3. Name it (e.g., "keycloak-agent")
4. Add **Universal Auth** method
5. Copy the **Client ID** and **Client Secret**

### 4. Grant Project Access

1. Go to your project → **Access Control**
2. Add the machine identity
3. Grant **Read** access to the `/keycloak` path

### 5. Configure Credentials

Create credential files in `apps/ssom/.devcontainer/infisical/credentials/`:

```bash
cd apps/ssom/.devcontainer/infisical/credentials

# Create client ID file
echo "your-client-id-here" > infisical-client-id

# Create client secret file
echo "your-client-secret-here" > infisical-client-secret
```

### 6. Configure Environment

Copy and edit the environment file:

```bash
cd apps/ssom/.devcontainer
cp .env.example .env
```

Edit `.env`:
```env
# Point to your Infisical instance
INFISICAL_ADDRESS=http://host.docker.internal:8080

# Your Infisical project ID (from project settings)
INFISICAL_PROJECT_ID=your-project-id

# Environment (dev, staging, prod)
INFISICAL_ENVIRONMENT=dev
```

### 7. Start with Infisical Integration

```bash
cd apps/ssom/.devcontainer

# Start with Infisical agent
docker compose --profile infisical up -d
```

## Usage Modes

### Development Mode (Default)

Without Infisical - uses direct environment variables:

```bash
docker compose up -d
```

Secrets are read from `.env` file or environment variables.

### Production Mode (With Infisical)

With Infisical agent managing secrets:

```bash
docker compose --profile infisical up -d
```

Secrets are fetched from Infisical and rendered to `/run/secrets/`.

## Secret Template Customization

The agent uses templates to render secrets. Edit `infisical/agent-config.yaml` to customize:

```yaml
templates:
  - template-content: |
      {{- with listSecrets .ProjectID .Environment "/keycloak" }}
      {{- range . }}
      {{ .Key }}={{ .Value }}
      {{- end }}
      {{- end }}
    destination-path: /run/secrets/keycloak.env
    config:
      polling-interval: 60s
```

## Troubleshooting

### Check Agent Logs

```bash
docker logs ssom-infisical-agent
```

### Verify Secrets are Rendered

```bash
docker exec ssom-infisical-agent cat /run/secrets/keycloak.env
```

### Test Infisical Connection

```bash
docker exec -it ssom-infisical-agent infisical login --method=universal-auth \
  --client-id=$(cat /run/secrets/credentials/infisical-client-id) \
  --client-secret=$(cat /run/secrets/credentials/infisical-client-secret)
```

### Common Issues

1. **Agent can't connect to Infisical**
   - Ensure Infisical is running
   - Check `INFISICAL_ADDRESS` is correct
   - Verify `host.docker.internal` resolves correctly

2. **Secrets not rendering**
   - Verify project ID and environment are correct
   - Check machine identity has access to the secrets path
   - Review agent logs for authentication errors

3. **Keycloak not reading secrets**
   - Ensure `secrets_data` volume is mounted
   - Check file permissions in `/run/secrets/`

## Security Considerations

1. **Never commit credentials** - The `credentials/` directory is gitignored
2. **Use Docker secrets in production** - Consider using Docker Swarm secrets or Kubernetes secrets
3. **Rotate credentials regularly** - Update machine identity credentials periodically
4. **Limit secret access** - Grant minimal permissions to the machine identity
5. **Use HTTPS in production** - Always use TLS for Infisical connections in production

## File Structure

```
apps/ssom/.devcontainer/
├── docker-compose.yml          # Main compose file with infisical profile
├── .env.example                # Environment template
├── .env                        # Your local config (gitignored)
└── infisical/
    ├── Dockerfile              # Infisical agent container
    ├── agent-config.yaml       # Agent configuration
    ├── secrets-template.tpl    # Secret rendering template
    └── credentials/            # Credential files (gitignored)
        ├── .gitkeep
        ├── infisical-client-id
        └── infisical-client-secret
```
