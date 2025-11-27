# Docker Configuration

This directory contains Docker-related configuration files for the Homarr Dashboard.

## Files

### `nginx.conf`
- **Purpose**: Nginx reverse proxy configuration
- **Usage**: Copied into Docker image at `/etc/nginx/templates/nginx.conf`
- **Function**: Routes traffic between frontend (port 3000) and websockets (port 3001)

## Structure

```
docker/
├── README.md          # This file
└── nginx.conf         # Nginx proxy configuration
```

## Related Files

### Root Level (Stay in Root)
- `Dockerfile` - Main Docker build configuration
- `.dockerignore` - Files to exclude from Docker build context

### Development Container
- `.devcontainer/docker-compose.yml` - Development container configuration
- `.devcontainer/.env` - Development environment variables

## Usage

The nginx.conf is automatically copied during Docker build:
```dockerfile
COPY docker/nginx.conf /etc/nginx/templates/nginx.conf
```

## Port Configuration

- **7575**: External port (nginx proxy)
- **3000**: NextJS application (internal)
- **3001**: WebSocket server (internal)
- **3002**: Tasks API (internal)
