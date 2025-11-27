# Homarr → Nx Migration

## ✅ What We've Done

### 1. Checked out Homarr v1.43.2
- Cloned Homarr source at tag `v1.43.2`
- Latest stable version with all features

### 2. Removed Turbo Monorepo
- Removed `turbo.json` and `turbo/` folder
- Updated package.json to remove Turbo commands
- Simplified scripts to work with Nx

### 3. Created Nx Integration
- Created `project.json` for Nx targets
- Configured Docker targets (start, stop, restart, logs, health-check)
- Added build, dev, lint, and test targets

### 4. Updated Package Scripts
**Old (Turbo monorepo)**:
```json
"build": "cross-env CI=true turbo build"
"dev": "turbo dev --parallel"
```

**New (Nx-compatible)**:
```json
"build:next": "cd apps/nextjs && pnpm build"
"dev:next": "cd apps/nextjs && pnpm dev"
```

## 📦 Homarr Structure

Homarr is internally a monorepo with:
```
apps/
  ├── nextjs/          # Main Next.js dashboard app
  ├── tasks/           # Background task runner
  └── websocket/       # WebSocket server

packages/
  ├── db/              # Database (Drizzle ORM)
  ├── api/             # tRPC API
  ├── ui/              # Shared UI components
  └── ...              # Other shared packages
```

## 🚀 Next Steps

### Option 1: Use Docker (Recommended for Production)
Keep using the pre-built Docker image in `.devcontainer/docker-compose.yml`:
```bash
npx nx start dashboard    # Uses existing docker-compose
```

### Option 2: Build from Source
If you need to customize Homarr:

1. **Install dependencies**:
   ```bash
   cd apps/dashboard
   pnpm install
   ```

2. **Build the app**:
   ```bash
   npx nx build dashboard
   ```

3. **Run locally**:
   ```bash
   npx nx dev dashboard
   ```

### Option 3: Build Custom Docker Image
Create a production Dockerfile:

1. Use the existing `Dockerfile` in the dashboard folder
2. Update `.devcontainer/docker-compose.yml` to use local build:
   ```yaml
   services:
     homarr:
       build:
         context: .
         dockerfile: Dockerfile
       # ... rest of config
   ```

## 🔧 Nx Commands

```bash
# Start dashboard (Docker)
npx nx start dashboard

# Stop dashboard
npx nx stop dashboard

# Restart dashboard
npx nx restart dashboard

# View logs
npx nx logs dashboard

# Health check
npx nx health-check dashboard

# Build from source
npx nx build dashboard

# Run dev mode (source)
npx nx dev dashboard

# Lint
npx nx lint dashboard

# Test
npx nx test dashboard
```

## ⚠️ Important Notes

1. **Keep Docker Approach**: The pre-built Docker image is production-ready and tested
2. **Source Build**: Only needed if you want to customize Homarr code
3. **Dependencies**: Homarr requires Node.js >=24.11.0 and pnpm 10.20.0
4. **Database**: Uses SQLite by default, stored in `apps/dashboard/data/`
5. **Config**: Dashboard configuration stored in `apps/dashboard/config/`

## 🎯 Recommended Workflow

**For Development**:
```bash
npx nx start dashboard          # Start with Docker
npx nx logs dashboard           # Check logs
```

**For Production**:
- Use the Docker image (already configured)
- Or build from source and create custom Docker image
- Keep config and data volumes separate

## 📝 Files Modified

- ✅ `project.json` - Created Nx configuration
- ✅ `package.json` - Updated scripts to remove Turbo
- ✅ `tooling/eslint/tsconfig.json` - Fixed paths
- ⚠️ Removed: `turbo.json`, `turbo/`, `pnpm-workspace.yaml`

## 🔗 Integration with Keycloak

The current configuration already has:
- ✅ `AUTH_OIDC_URI=http://ssom-keycloak:8080/realms/ubivis`
- ✅ Groups scope configured
- ✅ Admin role set to `/Administrators`

Everything should work with the existing Docker setup!
