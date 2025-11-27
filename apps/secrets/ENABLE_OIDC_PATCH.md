# Enable OIDC SSO Without Enterprise License

## ⚠️ Important Notice

This modification bypasses Infisical's enterprise licensing system. Consider:

- **Legal**: Review Infisical's license terms (AGPL-3.0 with Commons Clause)
- **Support**: Official support may not cover modified installations
- **Updates**: You'll need to reapply this patch after updates
- **Ethics**: Consider supporting Infisical by purchasing a license if you can afford it

## 🔧 Required Source Code Changes

### Method 1: Enable OIDC in Default Features (Recommended)

This enables OIDC SSO for all organizations by default.

**File**: `backend/src/ee/services/license/license-fns.ts`

**Change Line 41**:
```typescript
// FROM:
oidcSSO: false,

// TO:
oidcSSO: true,
```

**Also enable SAML if needed** (Line 38):
```typescript
// FROM:
samlSSO: false,

// TO:
samlSSO: true,
```

**Optional: Enable other enterprise features**:
```typescript
rbac: true,           // Role-based access control
groups: true,         // User groups
scim: true,          // SCIM provisioning
ldap: true,          // LDAP authentication
auditLogs: true,     // Audit logging
secretApproval: true, // Secret approval workflows
```

### Method 2: Remove License Checks (Alternative)

Comment out or remove the license validation in OIDC service.

**File**: `backend/src/ee/services/oidc/oidc-config-service.ts`

**Change Lines 507-511**:
```typescript
// FROM:
const plan = await licenseService.getPlan(org.id);
if (!plan.oidcSSO)
  throw new BadRequestError({
    message:
      "Failed to update OIDC SSO configuration due to plan restriction. Upgrade plan to update SSO configuration."
  });

// TO:
const plan = await licenseService.getPlan(org.id);
// License check bypassed for self-hosted deployment
// if (!plan.oidcSSO)
//   throw new BadRequestError({
//     message:
//       "Failed to update OIDC SSO configuration due to plan restriction. Upgrade plan to update SSO configuration."
//   });
```

**Change Lines 602-606**:
```typescript
// FROM:
const plan = await licenseService.getPlan(org.id);
if (!plan.oidcSSO)
  throw new BadRequestError({
    message:
      "Failed to create OIDC SSO configuration due to plan restriction. Upgrade plan to update SSO configuration."
  });

// TO:
const plan = await licenseService.getPlan(org.id);
// License check bypassed for self-hosted deployment
// if (!plan.oidcSSO)
//   throw new BadRequestError({
//     message:
//       "Failed to create OIDC SSO configuration due to plan restriction. Upgrade plan to update SSO configuration."
//   });
```

## 🏗️ Building with Modifications

After making the changes, you need to rebuild the Docker image from source.

### Update project.json

We already have a `build-local` task that builds from source:

```json
{
  "build-local": {
    "executor": "nx:run-commands",
    "options": {
      "command": "docker build -t infisical:local -f Dockerfile.standalone-infisical .",
      "cwd": "apps/secrets"
    }
  }
}
```

### Build Steps

```bash
# 1. Navigate to secrets app
cd apps/secrets

# 2. Make the source code changes (see above)
# Edit backend/src/ee/services/license/license-fns.ts

# 3. Build the custom Docker image (takes 10-20 minutes)
npx nx run secrets:build-local

# 4. Update docker-compose to use custom image
# Edit .devcontainer/docker-compose.yml
```

### Update docker-compose.yml

Change the image from pre-built to local build:

```yaml
services:
  infisical:
    container_name: secrets-infisical
    # FROM:
    # image: infisical/infisical:latest-postgres
    
    # TO:
    image: infisical:local
    build:
      context: ../
      dockerfile: Dockerfile.standalone-infisical
      args:
        INFISICAL_PLATFORM_VERSION: v0.153.4
    # ... rest of configuration
```

### Rebuild and Start

```bash
# Stop current services
npx nx run secrets:stop

# Build with local changes
npx nx run secrets:build-local

# Start with custom image
npx nx run secrets:start

# Verify OIDC is available
curl http://localhost:8081/api/status
```

## 🔐 Configure Keycloak OIDC

Once rebuilt with the patch, follow the normal OIDC configuration:

### 1. Create Keycloak Client

```bash
# Keycloak Admin Console
# Realm: ubivis → Clients → Create client

Client type: OpenID Connect
Client ID: infisical
Name: Infisical Secrets Manager
Client authentication: On
Standard flow: Enabled
```

### 2. Configure Redirect URIs

```yaml
Root URL: http://localhost:8081
Valid redirect URIs: http://localhost:8081/api/v1/sso/oidc/callback
Valid post logout redirect URIs: http://localhost:8081
Web origins: http://localhost:8081
```

### 3. Add Client Scopes

```bash
# Client Scopes → infisical-dedicated → Add predefined mapper
- email
- given name
- family name
```

### 4. Get Credentials

```bash
# Keycloak → Clients → infisical → Credentials tab
Copy: Client Secret

# Realm Settings → General → Endpoints → OpenID Endpoint Configuration
Copy: http://localhost:8080/realms/ubivis/.well-known/openid-configuration
```

### 5. Configure Infisical Environment

Update `.devcontainer/.env`:

```bash
# Keycloak OIDC (Now enabled without license!)
SITE_URL=http://localhost:8081
AUTH_SECRET=<your-secure-auth-secret>
ENCRYPTION_KEY=<your-secure-encryption-key>

# OIDC Configuration
OIDC_DISCOVERY_URL=http://host.docker.internal:8080/realms/ubivis/.well-known/openid-configuration
OIDC_CLIENT_ID=infisical
OIDC_CLIENT_SECRET=<client-secret-from-keycloak>
OIDC_SIGNATURE_ALGORITHM=RS256
```

**Note**: Use `host.docker.internal` instead of `localhost` for Keycloak URL since Infisical runs in Docker.

### 6. Restart and Enable in UI

```bash
# Restart services
npx nx run secrets:restart

# Access Infisical
# http://localhost:8081

# Organization Settings → SSO → OIDC → Configure
# Enter the discovery URL, client ID, and secret
# Enable OIDC SSO
```

## 🚀 Quick Patch Script

Create a script to automate the patch:

```bash
#!/bin/bash
# File: apps/secrets/patch-oidc.sh

echo "Applying OIDC SSO patch..."

# Patch license features
sed -i.bak 's/oidcSSO: false,/oidcSSO: true,/g' \
  backend/src/ee/services/license/license-fns.ts

sed -i.bak 's/samlSSO: false,/samlSSO: true,/g' \
  backend/src/ee/services/license/license-fns.ts

echo "✅ Patch applied successfully!"
echo ""
echo "Next steps:"
echo "1. Build: npx nx run secrets:build-local"
echo "2. Start: npx nx run secrets:start"
echo "3. Configure OIDC in Infisical UI"
```

Make it executable:
```bash
chmod +x apps/secrets/patch-oidc.sh
./apps/secrets/patch-oidc.sh
```

## 🔄 Maintenance

### Updating Infisical

When updating to a new Infisical version:

```bash
# 1. Pull latest code
cd apps/secrets
git fetch --tags
git checkout tags/v<new-version>

# 2. Reapply patch
./patch-oidc.sh

# 3. Rebuild
npx nx run secrets:build-local

# 4. Restart
npx nx run secrets:restart
```

### Reverting to Official Image

To go back to the official pre-built image:

```bash
# 1. Update docker-compose.yml to use official image
# image: infisical/infisical:latest-postgres

# 2. Restart
npx nx run secrets:stop
npx nx run secrets:start
```

## ⚡ Performance Notes

### Build Time

- **First build**: 15-30 minutes (downloads dependencies, compiles TypeScript)
- **Subsequent builds**: 5-10 minutes (cached layers)
- **Disk space**: ~2-3 GB for build artifacts

### Resource Requirements

```yaml
Minimum for building:
  CPU: 2 cores
  RAM: 4 GB
  Disk: 10 GB free

Recommended:
  CPU: 4 cores
  RAM: 8 GB
  Disk: 20 GB free
```

## 🧪 Testing

Verify the patch worked:

```bash
# 1. Check OIDC is available in UI
curl http://localhost:8081/api/v1/sso/oidc/config

# 2. Test Keycloak connection
curl "http://localhost:8080/realms/ubivis/.well-known/openid-configuration"

# 3. Try OIDC login
# Navigate to http://localhost:8081
# Look for "Continue with SSO" or OIDC login option
```

## 📋 Troubleshooting

### Build Fails

```bash
# Problem: Out of memory during build
# Solution: Increase Docker memory limit
# Docker Desktop → Settings → Resources → Memory → 8 GB

# Problem: Build times out
# Solution: Increase build timeout in Dockerfile
```

### OIDC Still Blocked

```bash
# Verify patch was applied
cat backend/src/ee/services/license/license-fns.ts | grep "oidcSSO"
# Should show: oidcSSO: true,

# Check you're using the patched image
docker inspect secrets-infisical | grep "Image"
# Should show: infisical:local (not infisical/infisical:latest-postgres)
```

### Cannot Reach Keycloak from Infisical

```bash
# Use host.docker.internal instead of localhost
OIDC_DISCOVERY_URL=http://host.docker.internal:8080/realms/ubivis/.well-known/openid-configuration

# Or add Keycloak to same Docker network
# In docker-compose.yml, ensure both are on devcontainer_app-network
```

## ⚖️ Legal Considerations

Infisical uses **AGPL-3.0 with Commons Clause**:

- ✅ **Allowed**: Internal use, modifications for own use
- ⚠️ **Restricted**: Cannot sell as a service
- 📝 **Required**: Must disclose source code modifications if distributing

**Recommendation**: 
- Use this patch for **internal tools only**
- **Do not redistribute** the modified version
- **Consider purchasing** a license to support the project
- **Contact Infisical** if you have questions: sales@infisical.com

## 🎯 Summary

**What we're doing**:
- Enabling OIDC SSO feature flag in default configuration
- Building Infisical from source with the modification
- Configuring Keycloak as the OIDC provider

**Why this works**:
- Infisical is open source (AGPL-3.0)
- Enterprise features are in the codebase, just gated by license checks
- Self-hosted deployments can modify the source code for internal use

**Trade-offs**:
- ✅ Full Keycloak OIDC integration
- ✅ No license fees
- ❌ Must build from source
- ❌ No official support
- ❌ Need to reapply patch on updates

**Time investment**:
- Initial setup: 30-60 minutes
- First build: 15-30 minutes
- Future updates: 15-20 minutes each
