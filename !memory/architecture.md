# Ubivis Architecture

## Technology Stack

### Core
- **Node.js**: v20 (LTS)
- **Package Manager**: npm with workspaces
- **Monorepo Tool**: Nx 22.0.2
- **Language**: TypeScript 5.9.2
- **Module System**: NodeNext (ES Modules)

### Development Tools
- **Nx**: Monorepo management, task orchestration, caching
- **SWC**: Fast TypeScript/JavaScript compilation
- **Prettier**: Code formatting
- **TypeScript**: Type checking and compilation

### Infrastructure Services

#### Database Layer
1. **PostgreSQL** (v15-alpine)
   - Port: 5432
   - Default DB: postgres
   - Credentials: postgres/postgres
   - Volume: postgres_data

2. **MongoDB** (v7)
   - Port: 27017
   - Root User: admin/password
   - Volume: mongodb_data

#### Caching & State
3. **Redis** (v7-alpine)
   - Port: 6379
   - Persistence: AOF enabled
   - Volume: redis_data

#### Planned Services (Currently Commented Out)
4. **Keycloak** - Identity and Access Management
   - Port: 8080
   - Purpose: Authentication/Authorization

5. **Rocket.Chat** - Team Communication
   - Port: 3000
   - Depends on MongoDB

6. **Supabase** - Backend as a Service
   - Configuration pending

## Development Environment

### DevContainer Setup
- **Base Image**: node:20-bullseye
- **Features**: Docker-in-Docker support
- **Workspace**: /workspace
- **Networks**: app-network (bridge)

### Port Mapping
- `4200`: Angular applications
- `3000`: Node.js/Rocket.Chat applications
- `8080`: Keycloak/Admin interfaces
- `5432`: PostgreSQL
- `6379`: Redis
- `27017`: MongoDB

## TypeScript Configuration

### Compiler Options
- **Target**: ES2022
- **Module**: NodeNext (ESM)
- **Strict Mode**: Enabled
- **Features**:
  - Composite projects
  - Declaration maps
  - Isolated modules
  - No unused locals/returns
  - No implicit overrides/returns
  - Custom conditions: `@ubivis/source`

## Nx Workspace Structure

### Organization Philosophy
- **Apps Only**: No `libs/` folder - only `apps/` folder
- **Independent Services**: Each app is self-contained
- **Open Source Tools**: Keycloak, Youtrack, Rocket.Chat, etc.
- **Individual Deployment**: Each app can run and deploy independently
- **Coolify Compatible**: DevContainers designed for Coolify deployment

### Configuration
- **Nx Cloud**: Enabled (ID: 691102394bbe2d1653a6441e)
- **Plugins**: @nx/js/typescript
- **Named Inputs**:
  - default: All project files + shared globals
  - production: Same as default
  - sharedGlobals: .gitlab-ci.yml

### Task Configuration
- **typecheck**: Type checking tasks
- **build**: Build tasks (tsconfig.lib.json)
- **build-deps**: Build dependencies
- **watch-deps**: Watch mode for dependencies

## CI/CD Architecture

### GitLab CI
- **Image**: node:20
- **Triggers**: main branch + merge requests
- **Tasks**: lint, test, build, typecheck (via `nx run-many`)
- **Features**:
  - Task distribution ready (commented out)
  - Nx Cloud CI recording
  - Self-healing CI with `nx fix-ci`
  - Interruptible jobs

## Network Architecture
- Single Docker bridge network: `app-network`
- Services communicate via service names
- External access via port forwarding

## Deployment Strategy

### Local Development
- DevContainer for each app
- Docker Compose for service orchestration
- Individual app containers can be started separately

### Production Deployment (Coolify)
- Each app has its own DevContainer configuration
- DevContainers are Coolify-compatible
- Individual deployment per app
- Environment-aware configuration (dev/test/prod)
- Each app is independently scalable

### App Structure
```
apps/
├── keycloak/           # Identity & Access Management
│   └── .devcontainer/
├── youtrack/           # Project Management
│   └── .devcontainer/
├── rocketchat/         # Team Communication
│   └── .devcontainer/
└── [other-tools]/      # Additional internal tools
    └── .devcontainer/
```
