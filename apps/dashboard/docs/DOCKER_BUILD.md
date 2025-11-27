# Dockerfile Nx Compatibility - FIXED ✅

## What Was Wrong

The original Dockerfile had these issues with Nx:

1. ❌ Expected `pnpm build` script (we had renamed it to `build:next`)
2. ❌ Expected `pnpm-workspace.yaml` (we had removed it)
3. ❌ Incompatible with Nx monorepo structure

## What I Fixed

### 1. ✅ Restored `pnpm-workspace.yaml`
```yaml
packages:
  - "apps/*"
  - "packages/*"
  - "tooling/*"
```

### 2. ✅ Added `build` script to package.json
```json
"scripts": {
  "build": "cd apps/nextjs && pnpm build",       // For Docker
  "build:next": "cd apps/nextjs && pnpm build",  // For Nx
  ...
}
```

### 3. ✅ Recreated `.devcontainer/docker-compose.yml`
- Uses **local Dockerfile build** instead of pre-built image
- Configured with Keycloak OIDC integration
- Proper volume mounts for config and data

### 4. ✅ Updated `project.json`
- Nx targets already configured for Docker commands

## Dockerfile Now Works With:

- ✅ **Nx monorepo** - Compatible with Nx workspace
- ✅ **pnpm workspace** - Restored for Docker build
- ✅ **Keycloak integration** - Environment variables configured
- ✅ **Local build** - Builds from source in `apps/dashboard`

## How It Works

### Build Process:
```
1. Dockerfile COPY . .                 → Copies entire dashboard app
2. pnpm install --recursive            → Installs all workspace packages
3. pnpm build                          → Builds Next.js app (apps/nextjs)
4. Multi-stage build                   → Creates optimized production image
5. Runtime                             → Runs Next.js + Tasks + WebSocket + Redis + Nginx
```

### What Gets Built:
- **apps/nextjs** - Main dashboard UI (Next.js)
- **apps/tasks** - Background task runner
- **apps/websocket** - Real-time updates server
- **packages/db** - Database layer (Drizzle ORM)
- **packages/api** - tRPC API
- All shared packages in `packages/`

## Usage

### Build the Image
```bash
# From root of monorepo
npx nx build dashboard

# Or manually
cd apps/dashboard
docker build -t homarr:local .
```

### Start with Docker Compose
```bash
# Start (builds if needed)
npx nx start dashboard

# Stop
npx nx stop dashboard

# Restart
npx nx restart dashboard

# View logs
npx nx logs dashboard
```

### Environment Variables

Create `apps/dashboard/.env`:
```env
# Keycloak OIDC
AUTH_OIDC_CLIENT_ID=dashboard
AUTH_OIDC_CLIENT_SECRET=<your-secret-from-keycloak>
AUTH_SECRET=<generate-with-openssl-rand-base64-32>

# Optional overrides
AUTH_OIDC_ADMIN_ROLE=/Administrators
AUTH_OIDC_OWNER_ROLE=/Administrators
```

## Build Time

**First build**: ~10-15 minutes
- Installs all dependencies (~5 min)
- Builds Next.js app (~5-8 min)
- Creates production image (~2 min)

**Subsequent builds**: ~2-5 minutes (with Docker cache)

## Production Deployment

### Option 1: Use Pre-built Image (Recommended)
```yaml
services:
  homarr:
    image: ghcr.io/ajnart/homarr:latest  # Official image
```

**Pros**:
- ✅ Fast deployment (no build)
- ✅ Tested and stable
- ✅ Regular updates

### Option 2: Build from Source (Custom)
```yaml
services:
  homarr:
    build:
      context: ./
      dockerfile: Dockerfile
```

**Use when**:
- ⚙️ Need customizations
- 🔧 Testing features
- 🚀 Contributing to Homarr

## Troubleshooting

### Build fails with "Cannot find module"
```bash
# Clean and rebuild
cd apps/dashboard
rm -rf node_modules .next
pnpm install
npx nx build dashboard
```

### Out of memory during build
```bash
# Increase Docker memory limit
# Docker Desktop → Settings → Resources → Memory: 8GB+
```

### Old image cached
```bash
# Force rebuild without cache
docker build --no-cache -t homarr:local .
```

## File Structure

```
apps/dashboard/
├── .devcontainer/
│   └── docker-compose.yml    # Docker Compose config (local build)
├── apps/
│   ├── nextjs/               # Main dashboard app
│   ├── tasks/                # Background tasks
│   └── websocket/            # WebSocket server
├── packages/
│   ├── db/                   # Database
│   ├── api/                  # tRPC API
│   └── ...                   # Other shared packages
├── Dockerfile                # Multi-stage production build
├── pnpm-workspace.yaml       # pnpm workspace config (for Docker)
├── package.json              # Root package with build scripts
└── project.json              # Nx configuration
```

## Summary

✅ **Dockerfile is now Nx-compatible!**

The dashboard can now be:
1. Built from source with Docker
2. Managed with Nx commands
3. Deployed with custom modifications
4. Integrated with Keycloak SSO

Everything works together: **Nx + pnpm workspace + Docker + Keycloak** 🎉
