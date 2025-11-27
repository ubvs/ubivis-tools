# Services Documentation

## Active Services

### 1. PostgreSQL Database
**Status**: ✅ Active

**Configuration**:
```yaml
Image: postgres:15-alpine
Port: 5432
Database: postgres
Username: postgres
Password: postgres
Volume: postgres_data
```

**Purpose**: Primary relational database for structured data storage

**Connection String**:
```
postgresql://postgres:postgres@postgres:5432/postgres
```

**Use Cases**:
- User data storage
- Application state
- Relational data models
- ACID-compliant transactions

---

### 2. Redis Cache
**Status**: ✅ Active

**Configuration**:
```yaml
Image: redis:7-alpine
Port: 6379
Persistence: AOF (Append-Only File)
Volume: redis_data
```

**Purpose**: In-memory cache and session storage

**Connection String**:
```
redis://redis:6379
```

**Use Cases**:
- Session management
- Caching layer
- Real-time data
- Pub/Sub messaging
- Rate limiting

---

### 3. MongoDB
**Status**: ✅ Active

**Configuration**:
```yaml
Image: mongo:7
Port: 27017
Root Username: admin
Root Password: password
Database: admin
Volume: mongodb_data
```

**Purpose**: Document database for flexible data models

**Connection String**:
```
mongodb://admin:password@mongodb:27017/admin
```

**Use Cases**:
- Document storage
- Flexible schemas
- Large-scale data
- Analytics data
- Log storage

---

## Planned Services (Currently Disabled)

### 4. Keycloak
**Status**: ⏳ Planned

**Configuration**:
```yaml
Image: quay.io/keycloak/keycloak:latest
Port: 8080
Admin Username: admin
Admin Password: admin
Mode: Development (start-dev)
Volume: keycloak_data
```

**Purpose**: Identity and Access Management (IAM)

**Features**:
- Single Sign-On (SSO)
- Identity brokering
- Social login
- User federation
- Fine-grained authorization
- OAuth2/OpenID Connect

**To Enable**:
1. Uncomment the keycloak section in `docker-compose.yml`
2. Restart DevContainer
3. Access at `http://localhost:8080`

---

### 5. Rocket.Chat
**Status**: ⏳ Planned

**Configuration**:
```yaml
Image: rocket.chat:latest
Port: 3000
ROOT_URL: http://localhost:3000
MongoDB: Connected to mongodb service
```

**Purpose**: Team communication and collaboration platform

**Features**:
- Real-time chat
- Video conferencing
- File sharing
- Integrations
- Mobile apps
- Team channels

**Dependencies**: MongoDB (already active)

**To Enable**:
1. Uncomment the rocket-chat section in `docker-compose.yml`
2. Restart DevContainer
3. Access at `http://localhost:3000`

---

### 6. Supabase
**Status**: ⏳ Planned (Not yet configured)

**Purpose**: Open-source Firebase alternative

**Planned Features**:
- PostgreSQL database
- Auto-generated APIs
- Real-time subscriptions
- Authentication
- Storage
- Edge functions

**Notes**: Configuration pending, integration with existing PostgreSQL TBD

---

## Service DevContainers

Individual DevContainers are configured for service-specific development:

### Keycloak DevContainer
- **File**: `.devcontainer/services/keycloak-devcontainer.json`
- **Workspace**: `/opt/keycloak`
- **Extensions**: JSON, YAML support

### Rocket.Chat DevContainer
- **File**: `.devcontainer/services/rocketchat-devcontainer.json`
- **Workspace**: `/app/bundle`
- **Extensions**: JSON, ESLint

### Supabase DevContainer
- **File**: `.devcontainer/services/supabase-devcontainer.json`
- **Workspace**: `/supabase`
- **Extensions**: JSON, Tailwind CSS

---

## Network Configuration

All services run on a shared Docker network:
- **Network Name**: `app-network`
- **Driver**: Bridge
- **DNS**: Services accessible by service name (e.g., `postgres`, `redis`, `mongodb`)

---

## Data Persistence

Volumes ensure data persists across container restarts:
- `postgres_data`: PostgreSQL data
- `redis_data`: Redis AOF files
- `mongodb_data`: MongoDB data files
- `keycloak_data`: Keycloak configuration (when enabled)

---

## Service Communication

### Internal (Container-to-Container)
Use service names as hostnames:
```
postgres:5432
redis:6379
mongodb:27017
keycloak:8080 (when enabled)
rocket-chat:3000 (when enabled)
```

### External (Host-to-Container)
Use localhost with port mapping:
```
localhost:5432 (PostgreSQL)
localhost:6379 (Redis)
localhost:27017 (MongoDB)
localhost:8080 (Keycloak)
localhost:3000 (Rocket.Chat or Node.js)
localhost:4200 (Angular)
```

---

## Deployment Considerations

### Coolify Integration
The `docker-compose.yml` is designed for both development and production:
- Remove development-specific settings for production
- Update environment variables for security
- Use external managed databases for production (optional)
- Configure proper secrets management
- Set up SSL/TLS termination

### Production Checklist
- [ ] Change all default passwords
- [ ] Use environment-specific secrets
- [ ] Configure backups for volumes
- [ ] Set up monitoring and logging
- [ ] Enable HTTPS/TLS
- [ ] Configure proper resource limits
- [ ] Set up health checks
