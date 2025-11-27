# Coolify Deployment Guide

## Overview

This monorepo is designed for deploying internal tools to Coolify. Each application in the `apps/` folder must be independently deployable.

## Architecture

### Apps-Only Structure
- **No shared libraries** (`libs/` folder)
- **Only applications** (`apps/` folder)
- Each app is self-contained
- Independent deployment per app

### Open Source Tools
The monorepo hosts open-source internal tools:
- **Keycloak**: Identity and Access Management
- **Youtrack**: Project management and issue tracking
- **Rocket.Chat**: Team communication
- **Supabase**: Backend-as-a-Service (optional)
- Additional tools as needed

---

## DevContainer Requirements

### Per-App DevContainer
Each application must have:

```
apps/
└── <app-name>/
    ├── .devcontainer/
    │   └── devcontainer.json
    ├── Dockerfile (if custom)
    ├── docker-compose.yml (optional)
    └── [app-specific files]
```

### Coolify Compatibility Checklist

#### 1. DevContainer Configuration
```json
{
  "name": "<App Name>",
  "dockerComposeFile": "docker-compose.yml",
  "service": "<service-name>",
  "workspaceFolder": "/workspace",
  "forwardPorts": [3000, 8080],
  "remoteUser": "node"
}
```

#### 2. Docker Compose Service
Each app should define its service clearly:
```yaml
services:
  app-name:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    volumes:
      - app-data:/data
    networks:
      - app-network
```

#### 3. Environment Variables
- Use `.env.example` for templates
- Never commit `.env` files
- Document required environment variables
- Support multiple environments (dev/staging/prod)

#### 4. Health Checks
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

---

## Deployment Process

### 1. Local Development
```bash
# Open specific app in DevContainer
# Navigate to apps/<app-name>/
# Open DevContainer in VS Code

# Test the app locally
npx nx serve <app-name>
```

### 2. Build and Test
```bash
# Build specific app
npx nx build <app-name>

# Run tests
npx nx test <app-name>

# Test Docker build
docker-compose -f apps/<app-name>/docker-compose.yml up --build
```

### 3. Deploy to Coolify
Each app deploys independently to Coolify:

1. **Connect Repository**: Link Git repo to Coolify
2. **Select App Directory**: Point to `apps/<app-name>/`
3. **Configure Environment**: Set environment variables
4. **Deploy**: Coolify builds and deploys the app

---

## Inter-App Communication

### Service Discovery
Apps may need to communicate with each other:

```yaml
environment:
  - KEYCLOAK_URL=https://keycloak.yourdomain.com
  - ROCKETCHAT_URL=https://chat.yourdomain.com
  - DATABASE_URL=postgresql://...
```

### Shared Services
Some apps may share base services:
- PostgreSQL (shared or per-app)
- Redis (shared or per-app)
- MongoDB (shared or per-app)

**Configuration**: Define in each app's docker-compose.yml or environment variables

---

## Best Practices

### 1. Independent Deployability
- Each app should run without requiring others
- Use environment variables for dependencies
- Graceful degradation if services unavailable

### 2. Configuration Management
```
apps/<app-name>/
├── .env.example          # Template
├── .env.development      # Local dev (gitignored)
├── .env.production       # Production (Coolify secrets)
└── config/
    ├── development.js
    ├── staging.js
    └── production.js
```

### 3. Data Persistence
```yaml
volumes:
  - app-data:/app/data
  - app-uploads:/app/uploads
  - app-config:/app/config
```

### 4. Logging
- Use structured logging (JSON)
- Log to stdout/stderr
- Coolify captures logs automatically

### 5. Secrets Management
- Use Coolify's secrets management
- Never hardcode credentials
- Use environment variables
- Rotate secrets regularly

---

## Monitoring and Maintenance

### Health Endpoints
Each app should expose:
- `/health` - Health check endpoint
- `/ready` - Readiness check endpoint
- `/metrics` - Metrics endpoint (optional)

### Backup Strategy
Per-app data backup:
- Database backups (automated)
- File storage backups
- Configuration backups
- Document restore procedures

### Updates and Rollbacks
- Use semantic versioning
- Tag releases in Git
- Coolify supports easy rollbacks
- Test updates in staging first

---

## Example: Keycloak App Structure

```
apps/keycloak/
├── .devcontainer/
│   └── devcontainer.json
├── docker-compose.yml
├── .env.example
├── Dockerfile (if custom)
├── config/
│   └── keycloak-config.json
└── README.md
```

### Keycloak docker-compose.yml
```yaml
version: '3.8'

services:
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    environment:
      KEYCLOAK_ADMIN: ${KEYCLOAK_ADMIN}
      KEYCLOAK_ADMIN_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD}
      KC_DB: postgres
      KC_DB_URL: ${DATABASE_URL}
      KC_DB_USERNAME: ${DB_USER}
      KC_DB_PASSWORD: ${DB_PASSWORD}
    ports:
      - "8080:8080"
    command: start --optimized
    depends_on:
      - postgres
    networks:
      - app-network

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - keycloak-db:/var/lib/postgresql/data
    networks:
      - app-network

volumes:
  keycloak-db:

networks:
  app-network:
    driver: bridge
```

---

## Troubleshooting

### App Won't Start
1. Check environment variables
2. Verify database connectivity
3. Review logs in Coolify
4. Check health endpoint

### Port Conflicts
- Ensure ports don't conflict
- Use environment variables for ports
- Document required ports per app

### Database Connection Issues
- Verify connection strings
- Check network connectivity
- Ensure database is running
- Review firewall rules

---

## Resources

- **Coolify Docs**: https://coolify.io/docs
- **Docker Docs**: https://docs.docker.com
- **Keycloak Docs**: https://www.keycloak.org/documentation
- **Youtrack Docs**: https://www.jetbrains.com/youtrack/
- **Rocket.Chat Docs**: https://docs.rocket.chat
