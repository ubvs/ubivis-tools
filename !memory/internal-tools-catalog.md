# Internal Tools Catalog

## Overview

This monorepo hosts open-source tools for internal use. Each tool is independently deployable to Coolify and runs in its own container.

---

## Planned Applications

### 1. Homarr Dashboard
**Purpose**: Internal Tools Portal & Homepage

**Features**:
- Beautiful, customizable dashboard
- Single Sign-On integration with Keycloak
- Quick access to all internal tools
- Role-based app visibility
- Drag-and-drop interface
- Themes and widgets
- Responsive design

**Default Port**: 7575

**Database**: SQLite (built-in)

**Status**: ✅ Configured (dashboard app)
**App Directory**: `apps/dashboard/`

**Resources**:
- Official: https://homarr.dev
- GitHub: https://github.com/ajnart/homarr
- Docker: ghcr.io/ajnart/homarr:latest

---

### 2. Keycloak
**Purpose**: Identity and Access Management (IAM)

**Features**:
- Single Sign-On (SSO)
- Identity brokering and social login
- User Federation (LDAP, Active Directory)
- OAuth2 / OpenID Connect
- Fine-grained authorization
- User management

**Default Port**: 8080

**Database**: PostgreSQL

**Status**: ✅ Configured (ssom app)
**App Directory**: `apps/ssom/`

**Resources**:
- Official: https://www.keycloak.org
- Docker: https://quay.io/repository/keycloak/keycloak

---

### 3. Youtrack
**Purpose**: Project Management and Issue Tracking

**Features**:
- Agile project management
- Issue and bug tracking
- Custom workflows
- Time tracking
- Reports and dashboards
- Integrations with development tools
- Knowledge base

**Default Port**: 8080

**Database**: Built-in or PostgreSQL

**Status**: ⏳ To be configured

**Resources**:
- Official: https://www.jetbrains.com/youtrack/
- Docker: https://hub.docker.com/r/jetbrains/youtrack

---

### 4. Rocket.Chat
**Purpose**: Team Communication and Collaboration

**Features**:
- Real-time chat and messaging
- Video conferencing
- File sharing
- Channels and direct messages
- Integrations and webhooks
- Mobile apps (iOS/Android)
- Desktop apps
- Guest access
- End-to-end encryption

**Default Port**: 3000

**Database**: MongoDB (already available)

**Status**: ⏳ To be configured

**Resources**:
- Official: https://rocket.chat
- Docker: https://hub.docker.com/_/rocket-chat

---

### 5. Supabase
**Purpose**: Backend-as-a-Service (BaaS)

**Features**:
- PostgreSQL database
- Auto-generated APIs (REST & GraphQL)
- Real-time subscriptions
- Authentication and authorization
- File storage
- Edge functions
- Database migrations
- Row Level Security (RLS)

**Default Port**: 8000 (API), 5432 (PostgreSQL)

**Database**: PostgreSQL (self-hosted)

**Status**: ⏳ To be configured

**Resources**:
- Official: https://supabase.com
- Self-hosting: https://supabase.com/docs/guides/self-hosting

---

## Future Tools (Potential)

### GitLab / Gitea
**Purpose**: Git repository hosting and CI/CD

**Why**: Self-hosted code repository, issue tracking, CI/CD pipelines

---

### Mattermost
**Purpose**: Alternative to Rocket.Chat

**Why**: Team collaboration, Slack alternative

---

### n8n
**Purpose**: Workflow automation

**Why**: Alternative to Zapier, connect and automate internal tools

---

### Metabase
**Purpose**: Business Intelligence and Analytics

**Why**: Data visualization, dashboards, SQL queries

---

### Nextcloud
**Purpose**: File storage and collaboration

**Why**: Self-hosted cloud storage, calendars, contacts

---

### Grafana + Prometheus
**Purpose**: Monitoring and observability

**Why**: Monitor all internal tools, metrics, alerts

---

### Uptime Kuma
**Purpose**: Uptime monitoring

**Why**: Monitor availability of all services

---

## Integration Strategy

### Authentication
All tools should integrate with **Keycloak** for SSO:
- Single login for all tools
- Centralized user management
- Role-based access control

### Communication
Tools can integrate with **Rocket.Chat**:
- Notifications from Youtrack
- Alerts from monitoring
- CI/CD status updates

### Data Storage
Shared PostgreSQL and MongoDB instances:
- Cost-effective resource usage
- Centralized backups
- Easier maintenance

### File Storage
If using **Nextcloud** or **Supabase**:
- Centralized file storage
- Accessible from all tools
- Backup and versioning

---

## Deployment Architecture

### Per-App Structure
```
apps/
├── keycloak/
│   ├── .devcontainer/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
├── youtrack/
│   ├── .devcontainer/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
└── rocketchat/
    ├── .devcontainer/
    ├── docker-compose.yml
    ├── .env.example
    └── README.md
```

### Coolify Deployment
Each app deploys independently:
1. Point Coolify to specific app directory
2. Configure environment variables
3. Deploy
4. Configure domain/SSL

### Inter-App Communication
Apps communicate via:
- Environment variables with URLs
- Keycloak for authentication
- Webhook integrations
- API calls

---

## Maintenance Considerations

### Updates
- Each tool updates independently
- Test in staging before production
- Document update procedures
- Monitor for breaking changes

### Backups
Per-app backup strategy:
- Database backups (automated)
- Configuration backups
- User data backups
- Document restore procedures

### Scaling
- Horizontal scaling per app
- Load balancing if needed
- Database connection pooling
- Cache layers (Redis)

### Security
- Regular security updates
- SSL/TLS for all apps
- Firewall configuration
- Rate limiting
- Audit logging

---

## Resource Requirements

### Minimum Per App

**Homarr Dashboard**:
- CPU: 0.5 cores
- RAM: 512MB
- Storage: 1GB

**Keycloak**:
- CPU: 1 core
- RAM: 1GB
- Storage: 5GB

**Youtrack**:
- CPU: 2 cores
- RAM: 2GB
- Storage: 10GB

**Rocket.Chat**:
- CPU: 1 core
- RAM: 1GB
- Storage: 5GB

**Supabase**:
- CPU: 2 cores
- RAM: 4GB
- Storage: 20GB

### Recommended Total
- CPU: 8+ cores
- RAM: 16+ GB
- Storage: 100+ GB SSD

**Note**: Dashboard is very lightweight and has minimal resource requirements.

---

## Decision Log

### Why Apps-Only?
- Independent deployments
- Isolated failures
- Easier scaling
- Tool-specific configurations
- No shared code complexity

### Why Coolify?
- Simple deployment
- Self-hosted
- Docker-based
- Environment management
- One-click deployments
- SSL/domain management

### Why Open Source?
- Cost-effective
- Customizable
- Community support
- No vendor lock-in
- Self-hosted control

---

## Getting Started

### 1. Set Up SSO First
Start with **Keycloak (ssom)** as it provides SSO for all tools.

### 2. Set Up Dashboard
Then configure **Homarr Dashboard** as your main entry point for accessing all tools.

### 2. Set Up App Directory
```bash
mkdir -p apps/keycloak/.devcontainer
cd apps/keycloak
```

### 3. Create DevContainer
Configure `.devcontainer/devcontainer.json` for local development.

### 4. Create Docker Compose
Define service in `docker-compose.yml`.

### 5. Document Setup
Create `README.md` with setup and deployment instructions.

### 6. Deploy to Coolify
Follow deployment guide in `coolify-deployment.md`.

### 7. Repeat for Other Tools
Follow same pattern for Youtrack, Rocket.Chat, etc.
