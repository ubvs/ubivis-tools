# Use the official Keycloak image as base for development
FROM quay.io/keycloak/keycloak:latest

# Note: This is a minimal Keycloak setup for running the service.
# For custom provider development, you may need to extend this image
# with Java development tools (JDK, Maven, etc.)

# Set workspace directory
WORKDIR /workspace

# Expose Keycloak port
EXPOSE 8080 8443

# Default command (can be overridden in docker-compose)
CMD ["start-dev"]
