# Keycloak Secrets Template
# This template renders all Keycloak secrets from Infisical

# Admin credentials
KC_BOOTSTRAP_ADMIN_USERNAME={{- with getSecretByName .ProjectID .Environment "/keycloak" "KC_BOOTSTRAP_ADMIN_USERNAME" }}{{ .Value }}{{ end }}
KC_BOOTSTRAP_ADMIN_PASSWORD={{- with getSecretByName .ProjectID .Environment "/keycloak" "KC_BOOTSTRAP_ADMIN_PASSWORD" }}{{ .Value }}{{ end }}

# Database configuration
KC_DB_USERNAME={{- with getSecretByName .ProjectID .Environment "/keycloak" "KC_DB_USERNAME" }}{{ .Value }}{{ end }}
KC_DB_PASSWORD={{- with getSecretByName .ProjectID .Environment "/keycloak" "KC_DB_PASSWORD" }}{{ .Value }}{{ end }}
KC_DB_URL={{- with getSecretByName .ProjectID .Environment "/keycloak" "KC_DB_URL" }}{{ .Value }}{{ end }}

# Optional: Additional secrets
{{- with listSecrets .ProjectID .Environment "/keycloak/custom" `{"recursive": true}` }}
{{- range . }}
{{ .Key }}={{ .Value }}
{{- end }}
{{- end }}
