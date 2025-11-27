# Homarr Dashboard

**Version**: 1.43.2  
**Status**: ✅ **Production Ready**  
**Authentication**: Dual-mode (Credentials + Keycloak SSO)

## Quick Access

- **URL**: http://localhost:7575
- **Keycloak Realm**: `ubivis`
- **Admin Group**: `/Administrators`

## Login Methods

### 1. **Keycloak SSO** (Recommended)
- Click "Sign in with Keycloak"
- Login with: `paulo.cesar@ubivis.io`
- Automatic admin access via `/Administrators` group

### 2. **Local Credentials** (Backup)
- Username/Password form
- For emergency admin access
- Independent of Keycloak

## Architecture

```
┌─────────────────────────────────────────────┐
│         Homarr Dashboard (v1.43.2)          │
│                                             │
│  ┌──────────────┐      ┌─────────────────┐ │
│  │ Next.js UI   │      │  OIDC Provider  │ │
│  │ (Port 7575)  │◄─────┤   (Keycloak)    │ │
│  └──────────────┘      └─────────────────┘ │
│         ▲                                   │
│         │                                   │
│  ┌──────┴───────┐                          │
│  │  Background  │                          │
│  │   Services   │                          │
│  ├──────────────┤                          │
│  │ - Tasks API  │                          │
│  │ - WebSocket  │                          │
│  │ - Redis      │                          │
│  │ - Nginx      │                          │
│  └──────────────┘                          │
│                                             │
│  Database: SQLite (/appdata/db/db.sqlite)  │
└─────────────────────────────────────────────┘
```

## Environment Variables

### Required Secrets (in `.devcontainer/.env`):

```env
# Keycloak OIDC
AUTH_OIDC_CLIENT_ID=dashboard
AUTH_OIDC_CLIENT_SECRET=PHGSO07cGxjVouxxtJfqJegMuYMNjwdu
AUTH_OIDC_ISSUER=http://ssom-keycloak:8080/realms/ubivis

# NextAuth Secret
AUTH_SECRET=vKB0qBe5we/oy62nIuEuB+p6OurnasZRevYqL831/zc=

# Encryption Key (v1.43.2 requirement)
SECRET_ENCRYPTION_KEY=841f05381c014bc9fcae27e54494a32f57e0f1d8aaf558376d08dbdb799561af

# Admin Roles
AUTH_OIDC_ADMIN_ROLE=/Administrators
AUTH_OIDC_OWNER_ROLE=/Administrators
```

### Configuration (in `docker-compose.yml`):

```yaml
AUTH_PROVIDER=oidc
AUTH_PROVIDERS=credentials,oidc  # Enable both login methods
AUTH_OIDC_SCOPE=openid profile email groups
AUTH_OIDC_URI=http://ssom-keycloak:8080/realms/ubivis
```

## Nx Commands

```bash
# Build from source (20-30 min first time)
npx nx build dashboard

# Start (detached)
npx nx start dashboard

# Stop
npx nx stop dashboard

# Restart
npx nx restart dashboard

# View logs
npx nx logs dashboard

# Health check
npx nx health-check dashboard
```

## Project Structure

```
apps/dashboard/
├── .devcontainer/
│   ├── docker-compose.yml    # Container orchestration
│   ├── .env                   # Secrets (gitignored)
│   ├── .env.example          # Template
│   └── setup-env.sh          # Setup script
├── apps/
│   ├── nextjs/               # Main UI application
│   ├── tasks/                # Background job processor
│   └── websocket/            # Real-time updates
├── packages/
│   ├── db/                   # Database & migrations
│   ├── api/                  # tRPC API
│   ├── cli/                  # CLI tools
│   └── [30+ shared packages]
├── Dockerfile                # Multi-stage production build
├── project.json             # Nx configuration
├── package.json             # Dependencies & scripts
└── README.md                # This file
```

## Build Process

### How It Works:

1. **Builder Stage**: 
   - Installs dependencies with pnpm
   - Builds all apps (nextjs, tasks, websocket, cli)
   - Builds database migrations
   - Creates optimized bundles

2. **Runner Stage**:
   - Copies built artifacts
   - Sets up Nginx reverse proxy
   - Configures Redis
   - Starts all services

### Build Time:

- **First build**: ~20-30 minutes
- **Subsequent builds**: ~5-10 minutes (Docker cache)

### Resources Required:

- **Memory**: 12 GB minimum (16 GB recommended)
- **CPUs**: 4+ cores
- **Disk**: ~2 GB for image

## Keycloak Integration

### Client Configuration:

- **Client ID**: `dashboard`
- **Client Type**: Confidential
- **Valid Redirect URIs**: `http://localhost:7575/*`
- **Web Origins**: `http://localhost:7575`

### Client Scopes:

✅ **Default Scopes**:
- `openid` - Core OIDC
- `profile` - User profile info
- `email` - Email address
- `groups` - Group membership (for admin access)

### Groups Mapper:

- **Name**: `group-membership`
- **Type**: `oidc-group-membership-mapper`
- **Full Path**: `true` ✅ (Required for `/Administrators`)
- **Claim Name**: `groups`
- **Included in**: ID Token, Access Token, Userinfo

### Group Structure:

```
/Administrators  → Full admin access
/Users          → Standard access
/Viewers        → Read-only access
```

## Admin Access

**Admin User**: `paulo.cesar@ubivis.io`  
**Group**: `/Administrators`  
**Access Level**: Full admin

### How Admin Access Works:

1. User logs in via Keycloak
2. Token includes `groups: ["/Administrators"]`
3. Homarr checks `AUTH_OIDC_ADMIN_ROLE` env var
4. Match found → Admin access granted

## Features

### Built-in Integrations:

- **Media Servers**: Plex, Jellyfin, Emby
- **Download Clients**: qBittorrent, Transmission, SABnzbd
- **Arr Stack**: Sonarr, Radarr, Lidarr, Readarr, Prowlarr
- **DNS/Network**: Pi-hole, AdGuard Home, OPNsense
- **Containers**: Docker, Kubernetes
- **Monitoring**: Prometheus, Grafana, Healthchecks
- **And many more...**

### Key Features:

- 📊 **Customizable Dashboards** - Drag & drop widgets
- 🔐 **SSO Integration** - Keycloak OIDC
- 🎨 **Themes** - Light/Dark mode
- 📱 **Responsive** - Mobile-friendly
- 🔔 **Notifications** - Real-time updates
- 🐳 **Docker Integration** - Manage containers
- 📈 **Monitoring** - System stats & health checks

## Troubleshooting

### Dashboard not loading:

```bash
# Check container status
docker ps | grep dashboard

# View logs
npx nx logs dashboard

# Restart
npx nx restart dashboard
```

### Keycloak login not working:

```bash
# Verify Keycloak connection
docker exec dashboard-homarr wget -qO- http://ssom-keycloak:8080/realms/ubivis/.well-known/openid-configuration

# Check environment variables
docker exec dashboard-homarr env | grep AUTH
```

### Admin access denied:

1. Verify user is in `/Administrators` group in Keycloak
2. Check groups mapper includes full path
3. Logout and login again to refresh token
4. Check browser DevTools for token content

### "Invalid environment variables" error:

```bash
# Recreate .env file
cd apps/dashboard/.devcontainer
./setup-env.sh

# Restart dashboard
npx nx restart dashboard
```

## Development

### Local Development:

```bash
# Install dependencies
cd apps/dashboard
pnpm install

# Start Next.js dev server
pnpm dev:next

# Start background services
pnpm start:local
```

### Database:

```bash
# Run migrations
pnpm db:push

# Open Drizzle Studio
pnpm db:studio
```

## Project Structure

```
apps/dashboard/
├── Dockerfile              # Main Docker build configuration
├── .dockerignore           # Docker build exclusions
├── README.md               # This file
├── docs/                   # 📚 All documentation
├── scripts/                # 🔧 Essential runtime scripts
│   ├── start-with-secrets.sh  # Infisical secrets integration
│   ├── fetch-secrets.js       # Node.js secrets fetcher
│   ├── test-secrets.js        # Infisical connection testing
│   ├── run.sh                 # Main application startup
│   ├── entrypoint.sh          # Docker entrypoint
│   └── *-groups.*             # Group management scripts
├── docker/                 # 🐳 Docker configuration files
│   ├── nginx.conf         # Nginx reverse proxy config
│   └── README.md          # Docker setup documentation
├── .devcontainer/         # 🛠️ VS Code dev container
│   ├── docker-compose.yml # Development environment
│   └── .env               # Development variables
└── apps/nextjs/           # 🚀 Main application code
```

## Documentation

- **Homarr Official**: https://homarr.dev/docs/

### Project Documentation
- **[Infisical Integration](docs/INFISICAL.md)** - Secrets management with Infisical
- **[Keycloak Setup](docs/KEYCLOAK_SETUP.md)** - SSO configuration and user management
- **[Group Sync](docs/GROUP_SYNC.md)** - Synchronizing groups between Keycloak and Homarr
- **[Update System](docs/UPDATE_SYSTEM.md)** - Automated update system for safe upgrades
- **[Docker Build](docs/DOCKER_BUILD.md)** - Building and deploying with Docker
- **[Nx Migration](docs/NX_MIGRATION.md)** - Monorepo integration details
- **[Security](docs/SECURITY.md)** - Security considerations and best practices
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Changelog](docs/CHANGELOG.md)** - Version history and changes

## Version History

### v1.43.2 (Current)
- ✅ Built from source
- ✅ Integrated with Nx monorepo
- ✅ Dual authentication (Credentials + OIDC)
- ✅ Keycloak SSO configured
- ✅ Groups-based admin access

## License

Apache-2.0

---

**Status**: ✅ **Fully Operational**  
**Deployed**: Nov 12, 2025  
**Maintained**: Nx Monorepo
