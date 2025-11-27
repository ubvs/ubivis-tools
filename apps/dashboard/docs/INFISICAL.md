# Homarr Dashboard - Infisical Integration

This document describes the Infisical integration for the Homarr Dashboard, which enables secure secret management without hardcoding sensitive values in environment files.

## 🔐 Overview

The dashboard now fetches secrets from Infisical at startup using a machine identity, providing:
- **Secure secret storage** in Infisical instead of `.env` files
- **Easy secret rotation** without redeploying the application
- **Graceful fallback** to environment variables if Infisical is unavailable
- **Hybrid approach** - static config in `.env`, sensitive secrets in Infisical

## 🚀 Nx Commands

### Test Secrets Connection
```bash
# Test the connection to Infisical and verify all secrets are available
nx run dashboard:test-secrets
```

### Development with Secrets
```bash
# Start dashboard in development mode with secrets integration
# This automatically tests the connection first
nx run dashboard:dev-with-secrets
```

### Build with Secrets Support
```bash
# Build Docker image with secrets startup script included
nx run dashboard:build-with-secrets
```

### Standard Commands
```bash
# Standard development mode (basic docker-compose)
nx run dashboard:dev

# Standard build (production image)
nx run dashboard:build
```

### Group Management
```bash
# Setup initial Homarr groups (bash script)
nx run dashboard:setup-groups

# Create groups directly in database (Node.js script)
nx run dashboard:create-groups

# Sync groups from Keycloak to Homarr
nx run dashboard:sync-groups
```

### Container Management
```bash
# Start in background
nx run dashboard:start

# Stop services
nx run dashboard:stop

# Health check
nx run dashboard:health-check
```

## 📋 Required Secrets in Infisical

The following secrets must be configured in Infisical (`dev` environment):

- `AUTH_SECRET` - NextAuth secret key
- `SECRET_ENCRYPTION_KEY` - Application encryption key (64 character hex)
- `AUTH_OIDC_CLIENT_ID` - OIDC client identifier
- `AUTH_OIDC_CLIENT_SECRET` - OIDC client secret
- `AUTH_OIDC_ISSUER` - OIDC issuer URL

## ⚙️ Configuration

### Environment Variables (.env)
```bash
# Infisical connection settings
INFISICAL_SITE_URL=http://localhost:8081
INFISICAL_PROJECT_ID=11386912-a785-4460-bad5-c7a7deab377c
INFISICAL_PROJECT_SLUG=ubivis-dashboard
INFISICAL_ENVIRONMENT=dev

# Machine Identity credentials
INFISICAL_CLIENT_ID=74039c0a-500a-489e-8d9e-09314613174c
INFISICAL_CLIENT_SECRET=566d5a96e2a359f576be78dc88d02a3b2c3363df6a63b4ae4ffc936a947bf420
```

## 🔄 How It Works

1. **Container starts** → Runs `/app/scripts/start-with-secrets.js`
2. **Script authenticates** with Infisical using machine identity
3. **Fetches secrets** from the configured project and environment
4. **Injects secrets** as environment variables
5. **Starts Homarr** with the injected secrets
6. **If Infisical fails** → Falls back to `.env` file values

## 🧪 Testing

### Quick Test
```bash
# Test secrets connection
nx run dashboard:test-secrets
```

### Full Integration Test
```bash
# Start with secrets integration (includes connection test)
nx run dashboard:dev-with-secrets
```

### Expected Output
```
🔐 Fetching secrets from Infisical...
✅ Authenticated with Infisical
📦 Found 5 secrets in Infisical
✅ All required secrets found
🚀 Starting Homarr with injected secrets...
```

## 🔧 Troubleshooting

### Connection Issues
1. Verify Infisical is running: `curl http://localhost:8081/api/status`
2. Check machine identity credentials in Infisical UI
3. Verify project ID and environment name
4. Ensure machine identity has "Developer" role

### Missing Secrets
1. Check secrets exist in Infisical project
2. Verify environment name matches (`dev`)
3. Ensure machine identity has access to the project

### Fallback Mode
If Infisical is unavailable, the application will fall back to `.env` file values. Uncomment the secret lines in `.env` for fallback mode.

## 📁 Files Created

- `scripts/test-secrets.js` - Test script to verify Infisical connection
- `scripts/fetch-secrets.js` - Node.js script to fetch secrets using Infisical SDK
- `scripts/start-with-secrets.sh` - Startup script that fetches secrets and starts Homarr
- `scripts/setup-groups.sh` - Script to setup Homarr groups (moved from .devcontainer)
- `scripts/create-groups.cjs` - Node.js script to create groups directly in database (moved from .devcontainer)
- `scripts/sync-groups-from-keycloak.sh` - Script to sync groups from Keycloak (moved from .devcontainer)
- Updated `Dockerfile` to include Infisical SDK and startup scripts
- Updated `docker-compose.yml` to use the new startup command
- Updated `project.json` with new Nx targets
