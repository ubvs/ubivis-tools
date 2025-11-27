# Memory Files - Ubivis Project Context

This folder contains comprehensive documentation about the Ubivis monorepo project to provide context for AI agents and developers.

## Files Overview

### 📋 [project-overview.md](./project-overview.md)
High-level overview of the Ubivis project:
- Project status and purpose
- Current state and what's completed
- Key characteristics

### 🏗️ [architecture.md](./architecture.md)
Technical architecture and stack:
- Technology stack (Node, Nx, TypeScript)
- Infrastructure services (PostgreSQL, Redis, MongoDB)
- Development environment setup
- TypeScript configuration
- CI/CD architecture

### 💻 [development-setup.md](./development-setup.md)
Complete guide for working with the project:
- Getting started with DevContainer
- Working with Nx commands
- VS Code extensions and settings
- Service access credentials
- Common tasks and troubleshooting

### 🔧 [services.md](./services.md)
Detailed documentation of all services:
- Active services (PostgreSQL, Redis, MongoDB)
- Planned services (Keycloak, Rocket.Chat, Supabase)
- Configuration and connection details
- Service communication patterns

### 📦 [nx-workspace.md](./nx-workspace.md)
Nx-specific configuration and usage:
- Workspace structure and organization
- Task orchestration and caching
- Nx Cloud integration
- Project graph management
- Best practices for Nx

### 🗺️ [roadmap-and-status.md](./roadmap-and-status.md)
Project progress and future plans:
- Completed items
- Immediate next steps
- Planned features
- Milestones and metrics

### 📐 [coding-guidelines.md](./coding-guidelines.md)
Coding standards and best practices:
- Core principles (iterate, simplicity, DRY)
- Code organization rules
- Testing guidelines
- Environment awareness
- Bug fixing approach

### 🚀 [coolify-deployment.md](./coolify-deployment.md)
Coolify deployment guide and requirements:
- Apps-only architecture
- Per-app DevContainer requirements
- Coolify compatibility checklist
- Deployment process
- Inter-app communication
- Best practices and examples

### 🛠️ [internal-tools-catalog.md](./internal-tools-catalog.md)
Catalog of planned internal tools:
- Keycloak (IAM)
- Youtrack (Project Management)
- Rocket.Chat (Team Communication)
- Supabase (BaaS)
- Integration strategy
- Resource requirements
- Decision log

## Quick Reference

### Project Purpose
**Internal Tools Platform** - Apps-only monorepo for open-source internal tools with Coolify deployment

### Project Status
🟡 **Foundation Complete** - Infrastructure ready, awaiting first application setup

### Key Services (Active)
- PostgreSQL: `postgres:5432` (postgres/postgres)
- Redis: `redis:6379`
- MongoDB: `mongodb:27017` (admin/password)

### Planned Applications
- Keycloak (Identity & Access Management)
- Youtrack (Project Management)
- Rocket.Chat (Team Communication)
- Supabase (Backend-as-a-Service)

### Next Steps
1. Rename `packages/` to `apps/`
2. Set up Keycloak app with DevContainer
3. Set up Youtrack app with DevContainer
4. Set up Rocket.Chat app with DevContainer
5. Ensure Coolify compatibility for all apps

### Important Links
- Nx Cloud: ID `691102394bbe2d1653a6441e`
- CI Setup: https://cloud.nx.app/connect/AI5vlVbTLb

## Usage

These memory files should be:
1. **Read by AI agents** at the start of work sessions
2. **Updated** when significant changes occur
3. **Referenced** when making architectural decisions
4. **Kept in sync** with actual project state

## Maintenance

Update these files when:
- New services are added or enabled
- Major architectural decisions are made
- New coding patterns are established
- Project status changes significantly
- New milestones are reached
