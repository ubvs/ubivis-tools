# DevContainer Setup for Nx Monorepo

This directory contains the DevContainer configuration for developing applications and services in this Nx monorepo.

## Structure

```
.devcontainer/
├── devcontainer.json          # Main Nx development environment
├── Dockerfile                 # Development container image
├── services/                  # Individual service configurations
│   ├── keycloak-devcontainer.json
│   ├── rocketchat-devcontainer.json
│   └── supabase-devcontainer.json
└── README.md                  # This file
```

## Usage

### Main Development Environment
1. Open the project in VS Code
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Select "Dev Containers: Reopen in Container"
4. Choose "Nx Monorepo Development"

This will start:
- Nx development container with Node.js, TypeScript, Angular CLI
- PostgreSQL, Redis, and MongoDB services
- Docker-in-Docker for container management

### Individual Service Development
For working on specific services like Keycloak, Rocket.Chat, or Supabase:

1. Navigate to the service directory in VS Code
2. Open the corresponding devcontainer.json file in `.devcontainer/services/`
3. Use "Dev Containers: Reopen in Container"

## Available Services

### Pre-configured Services
- **PostgreSQL**: `localhost:5432` (postgres/postgres)
- **Redis**: `localhost:6379`
- **MongoDB**: `localhost:27017` (admin/password)

### Placeholder Services (to be enabled later)
- **Keycloak**: Uncomment in docker-compose.yml
- **Rocket.Chat**: Uncomment in docker-compose.yml
- **Supabase**: To be configured

## Features

- **Nx Workspace**: Full Nx CLI support with caching
- **Node.js 20**: Latest Node.js with npm
- **TypeScript**: TypeScript compiler and language support
- **Angular CLI**: For Angular development
- **Docker-in-Docker**: Build and run containers inside dev container
- **VS Code Extensions**: Pre-installed extensions for optimal development
- **Port Forwarding**: Automatic port forwarding for common services

## Environment Variables

- `NODE_ENV=development`
- `NX_DAEMON=false` (disabled for container compatibility)
- `JAVA_HOME` set for Java-based services

## Adding New Services

1. Add the service to `docker-compose.yml`
2. Create a new devcontainer.json in `.devcontainer/services/`
3. Update the main `devcontainer.json` if needed for port forwarding

## Coolify Integration

The same `docker-compose.yml` can be used with Coolify for deployment:
- Use individual services for production deployment
- Modify environment variables for production
- Remove development-specific configurations
