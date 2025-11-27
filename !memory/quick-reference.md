# Quick Reference Guide

## 🚀 Common Commands

### Nx Tasks
```bash
# Build specific app
npx nx build <app-name>

# Serve specific app
npx nx serve <app-name>

# Run multiple tasks across all apps
npx nx run-many -t build

# Run affected apps only
npx nx affected -t build

# View project graph
npx nx graph

# Sync TypeScript references
npx nx sync

# Reset cache
npx nx reset
```

### Dashboard (Homarr) Commands
```bash
# Start dashboard
npx nx start dashboard

# Stop dashboard
npx nx stop dashboard

# View logs
npx nx logs dashboard

# Check health
npx nx health-check dashboard

# Restart
npx nx restart dashboard
```

### Keycloak (ssom) Commands
```bash
# Start Keycloak
npx nx start ssom

# Stop Keycloak
npx nx stop ssom

# View logs
npx nx logs ssom

# Check health
npx nx health-check ssom

# Restart
npx nx restart ssom
```

### Service Access
```bash
# PostgreSQL
psql -h localhost -p 5432 -U postgres -d postgres

# MongoDB
mongosh mongodb://admin:password@localhost:27017/admin

# Redis
redis-cli -h localhost -p 6379
```

### Docker
```bash
# Restart services
docker-compose restart

# View logs
docker-compose logs -f <service-name>

# Rebuild container
# VS Code: "Dev Containers: Rebuild Container"
```

---

## 📁 Project Structure

```
mono/
├── apps/             # All applications (NO libs folder)
│   ├── dashboard/   # Homarr Dashboard ✅ CONFIGURED
│   │   ├── .devcontainer/
│   │   ├── project.json
│   │   └── README.md
│   └── ssom/        # Keycloak SSO Manager ✅ RUNNING
│       ├── .devcontainer/
│       ├── project.json
│       └── README.md
├── .devcontainer/   # Main DevContainer config
├── .nx/            # Nx cache (gitignored)
├── !memory/        # This documentation
├── nx.json         # Nx configuration
├── package.json    # Root package
└── docker-compose.yml # Services
```

**Important**: This is an **apps-only** monorepo for internal tools. No shared libraries.

---

## 🔑 Credentials

### PostgreSQL
- Host: `postgres` or `localhost:5432`
- User: `postgres`
- Password: `postgres`
- Database: `postgres`

### MongoDB
- Host: `mongodb` or `localhost:27017`
- User: `admin`
- Password: `password`
- Database: `admin`

### Redis
- Host: `redis` or `localhost:6379`
- No auth

### Homarr Dashboard
- URL: `http://localhost:7575`
- Authentication: Keycloak SSO
- Setup: See `apps/dashboard/QUICK_START.md`

### Keycloak (ssom)
- URL: `http://localhost:8080/admin`
- Username: `admin`
- Password: `admin`
- Admin Console: http://localhost:8080/admin
- Health Check: http://localhost:8080/admin/

---

## 🎯 Next Steps Checklist

- [x] Rename `packages/` to `apps/`
- [x] Update package.json workspaces to `"apps/*"`
- [x] Set up Keycloak app (ssom) with DevContainer
- [x] Set up Dashboard app (dashboard/Homarr) with DevContainer
- [x] Configure Keycloak Ubivis realm
- [ ] Configure dashboard Keycloak client and start using it
- [ ] Set up Youtrack app with DevContainer
- [ ] Set up Rocket.Chat app with DevContainer
- [ ] Ensure each app is Coolify-deployable
- [ ] Document deployment process per app

---

## 📊 Project Status

**Purpose**: Internal Tools Platform (apps-only monorepo)  
**Phase**: Dashboard & SSO Ready  
**Base Services**: PostgreSQL, Redis, MongoDB  
**Active Apps**: 
  - Dashboard (Homarr) - http://localhost:7575
  - Keycloak (ssom) - http://localhost:8080  
**Planned Apps**: Youtrack, Rocket.Chat, Supabase  
**Applications**: 2 configured (dashboard, ssom)  
**Nx Cloud**: ✅ Connected (691102394bbe2d1653a6441e)  
**Deployment**: Coolify-compatible DevContainers

---

## 🔗 Important Links

- **Nx Cloud Setup**: https://cloud.nx.app/connect/AI5vlVbTLb
- **Nx Docs**: https://nx.dev
- **GitLab CI**: Configured in `.gitlab-ci.yml`

---

## ⚠️ Important Notes

1. **Apps-only structure** - No libs folder, only apps
2. **Independent apps** - Each app self-contained and individually deployable
3. **Coolify compatible** - All DevContainers must be Coolify-deployable
4. **Never overwrite .env** without asking first
5. **Run through Nx**, not direct tooling
6. **Keep files under 300 lines**
7. **Only mock data in tests**, never dev/prod
8. **Focus on requested changes** only

---

## 🆘 Troubleshooting

### Container Issues
```bash
# Rebuild container (VS Code Command Palette)
"Dev Containers: Rebuild Container"
```

### Nx Cache Issues
```bash
npx nx reset
```

### TypeScript Sync Issues
```bash
npx nx sync
```

### Service Connection Issues
```bash
# Check if services are running
docker-compose ps

# Restart specific service
docker-compose restart <service-name>
```
