# Development Setup Guide

## Prerequisites
- VS Code with Remote - Containers extension
- Docker and Docker Compose
- Git

## Getting Started

### 1. Open in DevContainer
```bash
# In VS Code
# Press Ctrl+Shift+P (Cmd+Shift+P on Mac)
# Select "Dev Containers: Reopen in Container"
# Choose "Ubivis Tools"
```

This starts:
- Nx development container
- PostgreSQL, Redis, MongoDB
- Docker-in-Docker support

### 2. Install Dependencies
```bash
npm install
```

This runs automatically via `postCreateCommand` in devcontainer.json

### 3. Verify Setup
```bash
# Check Nx installation
npx nx --version

# View project graph (when projects exist)
npx nx graph
```

## Working with Applications

### Application Structure
This is an **apps-only monorepo** for internal tools:
- No `libs/` folder - only `apps/` folder
- Each app is an independent open-source tool (Keycloak, Youtrack, Rocket.Chat, etc.)
- Each app has its own DevContainer for individual development
- All apps are Coolify-deployable

### Running Individual Apps
```bash
# Start a specific app
npx nx serve <app-name>

# Build a specific app
npx nx build <app-name>

# Run tasks for all apps
npx nx run-many -t build

# Run tasks for affected apps only
npx nx affected -t build
```

### Task Distribution
```bash
# Sync TypeScript project references
npx nx sync

# Check sync status (useful in CI)
npx nx sync:check
```

## VS Code Extensions (Pre-installed)

### Core Extensions
- **Nx Console** (nrwl.angular-console): Visual interface for Nx commands
- **Prettier** (esbenp.prettier-vscode): Code formatting
- **ESLint** (dbaeumer.vscode-eslint): Linting
- **TypeScript** (ms-vscode.vscode-typescript-next): Language support
- **Tailwind CSS** (bradlc.vscode-tailwindcss): Tailwind IntelliSense

### Container Extensions
- **Remote - Containers**: DevContainer support
- **JSON/YAML**: Configuration file support

## Editor Settings

### Auto-Format on Save
- Enabled by default
- Default formatter: Prettier
- TypeScript imports: Relative paths

### Hidden Files
- `.git`, `.DS_Store`, `node_modules`, `.nx/cache`

## Service Access

### Development Services
```bash
# PostgreSQL
Host: postgres (or localhost:5432)
Database: postgres
Username: postgres
Password: postgres

# MongoDB
Host: mongodb (or localhost:27017)
Database: admin
Username: admin
Password: password

# Redis
Host: redis (or localhost:6379)
No authentication
```

### Enabling Additional Services
To enable Keycloak or Rocket.Chat:
1. Uncomment service in `docker-compose.yml`
2. Restart DevContainer
3. Access via configured ports

## Environment Variables

### Development
```bash
NODE_ENV=development
NX_DAEMON=false  # Disabled for container compatibility
```

## Adding New Internal Tools

### Setting Up a New App
Each app should be self-contained with its own:
1. DevContainer configuration (`.devcontainer/`)
2. Docker Compose service definition
3. Independent deployment configuration
4. Coolify-compatible setup

Example structure:
```bash
apps/
└── my-tool/
    ├── .devcontainer/
    │   └── devcontainer.json
    ├── docker-compose.yml (or reference to root)
    └── [app-specific files]
```

### Release/Version
```bash
# Dry run
npx nx release --dry-run

# Actual release
npx nx release
```

### CI Simulation
```bash
# Run the same tasks as CI
npx nx run-many -t lint test build typecheck
```

## Troubleshooting

### Container Issues
```bash
# Rebuild container
# Command Palette -> "Dev Containers: Rebuild Container"
```

### Nx Cache Issues
```bash
# Reset Nx cache
npx nx reset
```

### TypeScript Issues
```bash
# Sync TypeScript project references
npx nx sync
```

## Best Practices

1. **Always use Nx commands** for tasks (not direct tooling)
2. **Run affected tasks** in development (`nx affected`)
3. **Check project graph** before major changes (`npx nx graph`)
4. **Use Nx Console** for visual task management
5. **Keep TypeScript references synced** (`npx nx sync`)

## File Structure
```
/workspace/
├── apps/              # All applications (no libs folder)
│   ├── keycloak/     # Each app is independent
│   ├── youtrack/
│   └── rocketchat/
├── .devcontainer/     # Main DevContainer configuration
├── .nx/              # Nx cache (gitignored)
├── !memory/          # Project documentation
├── node_modules/     # Dependencies
├── nx.json           # Nx configuration
├── package.json      # Root package configuration
└── docker-compose.yml # Service orchestration
```
