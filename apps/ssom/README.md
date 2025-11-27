# SSOM - SSO Manager (Keycloak)

SSO Manager is Keycloak configured for managing authentication and authorization across all Ubivis internal tools.

## Overview

**Technology**: Keycloak 25+ (Java-based)
**Port**: 8080 (HTTP), 8443 (HTTPS)
**Database**: PostgreSQL
**Container**: Minimal Keycloak image (Maven available via Dockerfile.dev)

## Features

- 🔐 **Single Sign-On (SSO)** - One login for all internal tools
- 🔑 **OAuth2 / OpenID Connect** - Modern authentication protocols
- 👥 **User Management** - Centralized user administration
- 🏢 **Identity Brokering** - Social login and external IdP integration
- 🛡️ **Fine-grained Authorization** - Role-based access control

## Quick Start

### Development with DevContainer (Recommended)

1. **Open in DevContainer**:
   ```bash
   # In VS Code, open this folder and use "Reopen in Container"
   # Or use the DevContainer CLI
   devcontainer open apps/ssom
   ```

2. **Access Keycloak**:
   - Admin Console: http://localhost:8080/admin
   - Default credentials: admin / admin (see `.env` file)

### Development with Nx Commands

```bash
# Start Keycloak
nx start ssom

# View logs
nx logs ssom

# Stop Keycloak
nx stop ssom

# Restart Keycloak
nx restart ssom

# Build Docker image
nx build ssom

# Health check
nx health-check ssom
```

### Manual Docker Compose

```bash
# From workspace root
cd apps/ssom/.devcontainer

# Copy environment file
cp ../.env.example ../.env

# Start services
docker compose up -d

# View logs
docker compose logs -f keycloak

# Stop services
docker compose down
```

## Configuration

### Environment Variables

Create a `.env` file in `apps/ssom/` (copy from `.env.example`):

```env
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin
KC_DB_USERNAME=postgres
KC_DB_PASSWORD=postgres
KC_HOSTNAME=localhost
KC_LOG_LEVEL=INFO
```

### Database

Keycloak uses PostgreSQL with the following default settings:
- **Database**: keycloak
- **Host**: postgres (container name)
- **Port**: 5432
- **User**: postgres
- **Password**: postgres (configurable via `.env`)

### Ports

- **8080**: HTTP (Admin Console and APIs)
- **8443**: HTTPS (for production use)

## Project Structure

```
apps/ssom/
├── .devcontainer/
│   ├── devcontainer.json    # VS Code DevContainer config
│   ├── Dockerfile            # Java + Keycloak base image
│   ├── docker-compose.yml    # Local development services
│   └── init-db.sql           # Database initialization
├── themes/                   # Custom Keycloak themes (optional)
├── providers/                # Custom SPI providers (optional)
├── .env.example              # Environment variables template
├── .env                      # Local environment (git-ignored)
├── project.json              # Nx project configuration
└── README.md                 # This file
```

## Customization

### Custom Themes

Place custom themes in `apps/ssom/themes/`:

```
themes/
└── my-theme/
    ├── login/
    ├── account/
    └── admin/
```

The themes folder is mounted to `/opt/keycloak/themes` in the container.

### Custom Providers

Add custom SPI providers in `apps/ssom/providers/`:

```
providers/
└── my-provider.jar
```

The providers folder is mounted to `/opt/keycloak/providers` in the container.

## Development

### Java Development

The default setup uses a minimal Keycloak image. For custom provider development:

1. **Switch to development Dockerfile**:
   ```bash
   # Edit .devcontainer/docker-compose.yml
   # Change: dockerfile: Dockerfile
   # To:     dockerfile: Dockerfile.dev
   ```

2. **Rebuild the container**:
   ```bash
   nx build ssom
   nx start ssom
   ```

The development image includes:
- **Java 21** (OpenJDK - built into Keycloak)
- **Maven 3.9.5**
- Development tools

You can then develop custom Keycloak providers:

```bash
# Create a Maven project
mvn archetype:generate -DgroupId=com.ubivis.keycloak \
  -DartifactId=custom-provider \
  -DarchetypeArtifactId=maven-archetype-quickstart

# Build provider
cd custom-provider
mvn clean package

# Copy JAR to providers folder
cp target/custom-provider.jar ../providers/
```

### Accessing Keycloak Admin Console

1. Navigate to http://localhost:8080/admin
2. Login with admin credentials (from `.env`)
3. Configure realms, clients, users, and roles

### Creating a Realm

1. Open Admin Console
2. Click "Create Realm"
3. Name it (e.g., "ubivis")
4. Configure authentication flows
5. Add clients for each internal tool

### Integrating Other Apps

To integrate other Ubivis apps with Keycloak:

1. **Create Client** in Keycloak Admin Console
2. **Configure Redirect URIs** for the app
3. **Set Client Authentication** (public/confidential)
4. **Note Client ID and Secret**
5. **Configure App** with Keycloak endpoints:
   - Authorization: http://keycloak:8080/realms/{realm}/protocol/openid-connect/auth
   - Token: http://keycloak:8080/realms/{realm}/protocol/openid-connect/token
   - Userinfo: http://keycloak:8080/realms/{realm}/protocol/openid-connect/userinfo

## Deployment to Coolify

### Prerequisites

1. Coolify instance running
2. PostgreSQL database available
3. Domain/subdomain configured

### Deployment Steps

1. **Push to Git Repository**:
   ```bash
   git add apps/ssom
   git commit -m "Add SSOM Keycloak app"
   git push
   ```

2. **Create Coolify Service**:
   - Type: Docker Compose
   - Repository: Your Git repo
   - Branch: main
   - Base Directory: `/apps/ssom/.devcontainer`
   - Docker Compose File: `docker-compose.yml`

3. **Configure Environment Variables** in Coolify:
   ```
   KEYCLOAK_ADMIN=your-admin-username
   KEYCLOAK_ADMIN_PASSWORD=your-secure-password
   KC_DB_USERNAME=your-db-user
   KC_DB_PASSWORD=your-db-password
   KC_HOSTNAME=your-domain.com
   KC_HTTP_ENABLED=false
   ```

4. **Configure Domain**:
   - Add domain: `sso.yourdomain.com`
   - Enable SSL/TLS
   - Configure reverse proxy

5. **Deploy**:
   - Click "Deploy"
   - Monitor deployment logs
   - Verify health check

### Production Considerations

- ✅ Use strong admin passwords
- ✅ Enable HTTPS only (`KC_HTTP_ENABLED=false`)
- ✅ Configure proper hostname
- ✅ Set up database backups
- ✅ Configure logging and monitoring
- ✅ Review security settings
- ✅ Set up rate limiting
- ✅ Configure session timeouts

## Monitoring

### Health Check

```bash
# Using Nx
nx health-check ssom

# Using curl
curl http://localhost:8080/health
```

### Logs

```bash
# Using Nx
nx logs ssom

# Using Docker Compose
cd apps/ssom/.devcontainer
docker compose logs -f keycloak
```

### Metrics

Keycloak provides metrics at:
- http://localhost:8080/metrics

## Troubleshooting

### Container won't start

```bash
# Check logs
nx logs ssom

# Rebuild container
nx build ssom
nx start ssom
```

### Cannot access Admin Console

1. Verify container is running: `docker ps`
2. Check port 8080 is available: `lsof -i :8080`
3. Verify admin credentials in `.env`
4. Check container logs for errors

### Database connection issues

1. Verify PostgreSQL is running
2. Check database credentials in `.env`
3. Verify network connectivity: `docker network ls`
4. Check init-db.sql was executed

### Performance issues

1. Increase container resources in Docker settings
2. Check database connection pool settings
3. Review Keycloak cache configuration
4. Monitor Java heap usage

## Resources

- **Official Docs**: https://www.keycloak.org/documentation
- **Docker Image**: https://quay.io/repository/keycloak/keycloak
- **Admin Guide**: https://www.keycloak.org/docs/latest/server_admin/
- **Developer Guide**: https://www.keycloak.org/docs/latest/server_development/

## Support

For issues or questions:
1. Check Keycloak documentation
2. Review container logs
3. Check Docker Compose configuration
4. Verify environment variables

## License

Keycloak is licensed under Apache License 2.0
