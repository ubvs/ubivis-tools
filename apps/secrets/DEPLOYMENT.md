# Infisical Secrets Manager - Deployment Guide

## Overview

Infisical is an open-source secrets management platform integrated into the Ubivis monorepo as an Nx application. This deployment is configured for easy deployment to Coolify on Hetzner VPS.

## Quick Start

### Local Development

```bash
# Start services (Infisical + PostgreSQL + Redis)
npx nx run secrets:start

# View logs
npx nx run secrets:logs

# Check health
npx nx run secrets:health-check

# Stop services
npx nx run secrets:stop

# Restart services
npx nx run secrets:restart
```

### Access

- **Infisical UI**: http://localhost:8081
- **API Status**: http://localhost:8081/api/status

## Configuration

### Environment Variables

Required environment variables are configured in `.devcontainer/.env`:

```bash
# Copy the example file (already done)
cp .devcontainer/.env.example .devcontainer/.env
```

**Key variables:**
- `ENCRYPTION_KEY` - Platform encryption key (change in production!)
- `AUTH_SECRET` - JWT signing secret (change in production!)
- `POSTGRES_*` - PostgreSQL credentials
- `SITE_URL` - Public URL for Infisical
- `REDIS_URL` - Redis connection string

### Ports

- **8081** - Infisical web interface (external)
- **5432** - PostgreSQL (internal only)
- **6380** - Redis (external for debugging)

> Port 8081 avoids conflict with Keycloak on 8080

## Nx Commands

```bash
# Pull latest Docker image
npx nx run secrets:build

# Build from source (if needed)
npx nx run secrets:build-local

# Development mode
npx nx run secrets:dev

# Production mode (detached)
npx nx run secrets:start

# View service status
docker compose -f apps/secrets/.devcontainer/docker-compose.yml ps
```

## Coolify Deployment

### Prerequisites

1. Coolify instance running on Hetzner VPS
2. Git repository connected to Coolify
3. Docker environment configured

### Deployment Steps

#### Option 1: Using Docker Compose (Recommended)

1. **Create New Service in Coolify**
   - Type: Docker Compose
   - Repository: Point to this monorepo
   - Base Directory: `apps/secrets`
   - Docker Compose File: `.devcontainer/docker-compose.yml`

2. **Configure Environment Variables**
   
   In Coolify, set these environment variables:
   
   ```bash
   # Generate secure keys for production!
   ENCRYPTION_KEY=<generate-32-char-key>
   AUTH_SECRET=<generate-secure-key>
   
   # Database
   POSTGRES_USER=infisical
   POSTGRES_PASSWORD=<secure-password>
   POSTGRES_DB=infisical
   
   # Site URL (use your domain)
   SITE_URL=https://secrets.yourdomain.com
   
   # Disable telemetry
   TELEMETRY_ENABLED=false
   ```

3. **Set Up Volumes**
   
   Ensure persistent volumes are configured:
   - `postgres-data` → PostgreSQL data
   - `redis-data` → Redis persistence
   - `infisical-data` → Application data

4. **Configure Domain**
   - Point your domain to the VPS IP
   - Enable SSL/TLS in Coolify
   - Set up automatic certificate renewal

5. **Deploy**
   - Click "Deploy" in Coolify
   - Monitor logs for startup
   - Verify health at `/api/status`

#### Option 2: Using Pre-built Image

1. **Create Service**
   - Type: Docker Image
   - Image: `infisical/infisical:latest-postgres`

2. **Configure**
   - Add PostgreSQL and Redis as separate services
   - Link services via Docker network
   - Configure environment variables as above

### Production Checklist

- [ ] Generate secure `ENCRYPTION_KEY` (32+ characters)
- [ ] Generate secure `AUTH_SECRET` (use `openssl rand -base64 32`)
- [ ] Set strong PostgreSQL password
- [ ] Configure custom domain with SSL
- [ ] Enable automatic backups for PostgreSQL
- [ ] Configure SMTP for email notifications (optional)
- [ ] Set up SSO if needed (Google, GitHub, etc.)
- [ ] Configure firewall rules
- [ ] Test database connectivity
- [ ] Verify Redis persistence
- [ ] Test secret creation and retrieval

## Architecture

```
┌─────────────────────────────────────────┐
│         Infisical (Port 8081)           │
│   - Frontend (React/Vite)               │
│   - Backend (Node.js/Express)           │
│   - API + Web UI                        │
└────────────┬────────────────────────────┘
             │
        ┌────┴────┐
        │         │
   ┌────▼───┐ ┌──▼──────┐
   │ PostgreSQL │ │  Redis   │
   │ (Port 5432)│ │(Port 6379)│
   └──────────┘ └─────────┘
```

## Security Notes

### Development

The `.devcontainer/.env` file contains **SAMPLE** credentials suitable for local development only.

### Production

**NEVER use the sample credentials in production!**

Generate secure credentials:

```bash
# Generate encryption key
openssl rand -hex 16

# Generate auth secret
openssl rand -base64 32

# Generate strong password
openssl rand -base64 24
```

## Backup & Recovery

### Database Backup

```bash
# Backup PostgreSQL
docker exec secrets-postgres pg_dump -U infisical infisical > backup.sql

# Restore
docker exec -i secrets-postgres psql -U infisical infisical < backup.sql
```

### Volume Backup

```bash
# Backup volumes
docker run --rm -v devcontainer_postgres-data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz /data
```

## Troubleshooting

### Services Won't Start

```bash
# Check logs
npx nx run secrets:logs

# Check service status
docker compose -f apps/secrets/.devcontainer/docker-compose.yml ps

# Check port conflicts
lsof -i :8081
```

### Database Connection Issues

```bash
# Test database connectivity
docker exec secrets-postgres psql -U infisical -d infisical -c "SELECT 1;"

# Check environment variables
docker exec secrets-infisical env | grep DB_
```

### Reset Everything

```bash
# Stop and remove all containers and volumes
npx nx run secrets:stop
docker volume rm devcontainer_postgres-data devcontainer_redis-data devcontainer_infisical-data
npx nx run secrets:start
```

## Integration with Other Apps

### SSO Integration

Infisical supports multiple SSO options:

**FREE Options** (Available immediately):
- GitHub OAuth
- Google OAuth
- GitLab OAuth

**PAID Options** (Requires Enterprise License):
- Keycloak OIDC
- Keycloak SAML
- Okta, Azure AD, etc.

**📖 See `SSO_INTEGRATION.md` for complete setup instructions** for all SSO providers, including:
- GitHub/Google OAuth configuration (free, immediate)
- Keycloak OIDC configuration (requires license)
- Production deployment considerations
- Troubleshooting guide

Quick setup for GitHub SSO:
```bash
# Add to .devcontainer/.env
CLIENT_ID_GITHUB_LOGIN=your_github_client_id
CLIENT_SECRET_GITHUB_LOGIN=your_github_client_secret
```

### API Access

Other apps can fetch secrets via Infisical API:

```bash
# Install Infisical CLI
curl -1sLf 'https://artifacts-cli.infisical.com/setup.deb.sh' | bash
apt-get install infisical

# Login and fetch secrets
infisical login
infisical secrets
```

## Resources

- **Official Docs**: https://infisical.com/docs
- **Docker Hub**: https://hub.docker.com/r/infisical/infisical
- **GitHub**: https://github.com/Infisical/infisical
- **Self-Hosting Guide**: https://infisical.com/docs/self-hosting/overview

## Support

For issues related to:
- **Nx integration**: Check `project.json` configuration
- **Docker setup**: Review `.devcontainer/docker-compose.yml`
- **Coolify deployment**: Consult Coolify docs
- **Infisical features**: See official Infisical documentation
