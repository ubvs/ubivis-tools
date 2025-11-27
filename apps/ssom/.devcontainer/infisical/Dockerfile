# Infisical Agent Sidecar for Keycloak
FROM infisical/cli:latest

# Create directories for secrets and config
RUN mkdir -p /run/secrets /etc/infisical

# Copy agent configuration
COPY agent-config.yaml /etc/infisical/agent-config.yaml
COPY secrets-template.tpl /etc/infisical/secrets-template.tpl

# The agent will run and continuously sync secrets
ENTRYPOINT ["infisical", "agent", "--config", "/etc/infisical/agent-config.yaml"]
