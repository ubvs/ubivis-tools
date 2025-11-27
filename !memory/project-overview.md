# Ubivis Monorepo - Project Overview

## Project Name
**Ubivis** - A modern, microservices-based monorepo using Nx

## Status
🟡 **Early Stage Setup** - Infrastructure and development environment configured, no applications/packages yet

## Organization
- **Package Scope**: `@ubivis`
- **Root Package**: `@ubivis/root`
- **Version**: 0.0.0 (Initial setup)
- **License**: MIT

## Purpose
**Internal Tools Platform** - A monorepo for orchestrating open-source internal tools:
- Each app is an independent, deployable service
- Open source projects: Keycloak, Youtrack, Rocket.Chat, and more
- DevContainers deployable via Coolify
- No shared libraries - only standalone applications
- Each app runs and deploys individually

## Current State
- ✅ Nx workspace initialized (v22.0.2)
- ✅ DevContainer environment configured
- ✅ Docker Compose setup complete
- ✅ CI/CD pipeline configured (GitLab CI)
- ✅ Nx Cloud integration ready (ID: 691102394bbe2d1653a6441e)
- ✅ Apps folder structure created
- ✅ First app deployed: **ssom** (Keycloak SSO Manager)
- ⏳ Additional apps pending (Youtrack, Rocket.Chat, Supabase, etc.)

## Key Characteristics
1. **Internal Tools Hub**: Orchestration of open-source tools for internal use
2. **Independent Apps**: Each app is self-contained and individually deployable
3. **Coolify Compatible**: DevContainers designed for Coolify deployment
4. **No Shared Libraries**: Apps folder only, no libs folder
5. **Modern Stack**: Node 20, Docker, Nx for orchestration
6. **CI/CD Ready**: GitLab CI with Nx Cloud integration
