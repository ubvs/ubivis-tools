# Keycloak OIDC Setup for Infisical - Step by Step

## ✅ Status

- [x] Telemetry disabled (no data sent to Infisical)
- [x] OIDC patch applied (OIDC/SAML/LDAP/RBAC/Groups/Audit Logs enabled)
- [x] Services stopped
- [ ] Building custom image (⏱️ in progress, 15-30 minutes)
- [ ] Create Keycloak OIDC client
- [ ] Configure Infisical environment
- [ ] Start patched version
- [ ] Test OIDC login

---

## 🔐 Step 1: Create Keycloak OIDC Client

While the Docker image is building, let's set up Keycloak.

### 1.1 Access Keycloak Admin Console

```bash
# URL: http://localhost:8080
# Realm: ubivis
# Navigate to: Clients → Create client
```

### 1.2 General Settings

```yaml
Client type: OpenID Connect
Client ID: infisical
Name: Infisical Secrets Manager
Description: Self-hosted secrets management with Keycloak SSO
```

Click **Next**

### 1.3 Capability Config

```yaml
Client authentication: ON
Authorization: OFF
Authentication flow:
  ✅ Standard flow (OAuth 2.0 Authorization Code Flow)
  ✅ Direct access grants
  ⬜ Implicit flow
  ⬜ Service accounts roles
```

Click **Next**

### 1.4 Login Settings

```yaml
Root URL: http://localhost:8081
Home URL: http://localhost:8081
Valid redirect URIs: 
  - http://localhost:8081/api/v1/sso/oidc/callback
  - http://localhost:8081/*
Valid post logout redirect URIs:
  - http://localhost:8081
  - http://localhost:8081/*
Web origins:
  - http://localhost:8081
  - +
```

Click **Save**

---

## 🔑 Step 2: Configure Client Scopes

### 2.1 Navigate to Client Scopes

```bash
# In Keycloak Admin Console:
# Clients → infisical → Client scopes tab
# Click on: infisical-dedicated
```

### 2.2 Add Predefined Mappers

Click **Add predefined mapper** and select:

```yaml
✅ email
✅ given name
✅ family name
```

Click **Add**

### 2.3 Verify Mappers

The mappers list should now show:
- email → email
- given name → given_name  
- family name → family_name

---

## 🎫 Step 3: Get Client Credentials

### 3.1 Get Client Secret

```bash
# Keycloak Admin Console:
# Clients → infisical → Credentials tab
# Copy the "Client secret" value
```

**Save this secret** - you'll need it for Infisical configuration.

### 3.2 Get Discovery URL

```bash
# Keycloak Admin Console:
# Realm settings → General tab → Endpoints
# Click: "OpenID Endpoint Configuration"
```

The URL should be:
```
http://localhost:8080/realms/ubivis/.well-known/openid-configuration
```

**Verify it works**:
```bash
curl http://localhost:8080/realms/ubivis/.well-known/openid-configuration
```

You should see a JSON response with `issuer`, `authorization_endpoint`, etc.

---

## 👤 Step 4: Create Test User (Optional)

### 4.1 Create User in Keycloak

```bash
# Keycloak Admin Console:
# Users → Add user
```

Fill in:
```yaml
Username: test.user
Email: test.user@yourdomain.com
Email verified: ON
First name: Test
Last name: User
```

Click **Create**

### 4.2 Set Password

```bash
# Users → test.user → Credentials tab
# Click: Set password
```

```yaml
Password: <choose-a-password>
Password confirmation: <same-password>
Temporary: OFF
```

Click **Save**

---

## ⚙️ Step 5: Configure Infisical Environment

Once the build completes, update your environment configuration.

### 5.1 Copy and Edit .env File

```bash
cd /Users/griiettner/Projects/ubivis/mono/apps/secrets/.devcontainer
cp .env.example .env
```

### 5.2 Edit .env File

Update these key values:

```bash
# Required - Generate secure keys
ENCRYPTION_KEY=<run: openssl rand -hex 16>
AUTH_SECRET=<run: openssl rand -base64 32>

# Database (keep defaults for local dev)
POSTGRES_USER=infisical
POSTGRES_PASSWORD=infisical
POSTGRES_DB=infisical

# Site URL
SITE_URL=http://localhost:8081

# Telemetry - ALL DISABLED
TELEMETRY_ENABLED=false
SENTRY_DSN=
POSTHOG_HOST=
POSTHOG_PROJECT_API_KEY=
OTEL_TELEMETRY_COLLECTION_ENABLED=false

# Keycloak OIDC Configuration
OIDC_DISCOVERY_URL=http://host.docker.internal:8080/realms/ubivis/.well-known/openid-configuration
OIDC_CLIENT_ID=infisical
OIDC_CLIENT_SECRET=<paste-client-secret-from-keycloak>
```

**Important Notes**:
- Use `host.docker.internal` instead of `localhost` in OIDC_DISCOVERY_URL
- This allows the Docker container to reach Keycloak on the host machine
- Generate new ENCRYPTION_KEY and AUTH_SECRET for security

### 5.3 Generate Secure Keys

```bash
# Generate ENCRYPTION_KEY (32 characters hex)
openssl rand -hex 16

# Generate AUTH_SECRET (base64)
openssl rand -base64 32
```

Save these outputs and put them in your `.env` file.

---

## 🚀 Step 6: Start Patched Version

Once the Docker build completes:

### 6.1 Start Services

```bash
# From mono root:
npx nx run secrets:start-patched

# Or with logs:
npx nx run secrets:dev-patched
```

### 6.2 Wait for Services to be Healthy

```bash
# Check status:
docker ps --filter "name=secrets-"

# Watch logs:
docker compose -f apps/secrets/.devcontainer/docker-compose.patched.yml logs -f infisical
```

Wait for:
```
✅ secrets-postgres: healthy
✅ secrets-redis: healthy
✅ secrets-infisical: healthy (starting...)
```

### 6.3 Verify Infisical is Running

```bash
# Check API status
curl http://localhost:8081/api/status

# Should return:
# {"date":"...","message":"Ok","emailConfigured":false,...}
```

---

## 🔐 Step 7: Enable OIDC in Infisical UI

### 7.1 Initial Setup (First Time)

1. **Open Infisical**: http://localhost:8081
2. **Create account** (if first time):
   - Email: your email
   - Password: choose a strong password
   - Organization name: Your Organization

### 7.2 Navigate to SSO Settings

```
Organization Settings → Single Sign-On (SSO) → General tab
```

### 7.3 Connect OIDC

1. Click **"Connect"** under **OIDC**
2. Configuration Type: **"Discovery URL"**
3. Fill in the form:

```yaml
Discovery Document URL: http://host.docker.internal:8080/realms/ubivis/.well-known/openid-configuration
JWT Signature Algorithm: RS256
Client ID: infisical
Client Secret: <paste-from-keycloak-credentials-tab>
```

4. Click **"Update"**

### 7.4 Enable OIDC SSO

1. Toggle **"Enable OIDC SSO"** to ON
2. You should see: "OIDC SSO has been enabled"

### 7.5 Test OIDC Login

1. **Open new incognito window**: http://localhost:8081
2. You should see **"Continue with SSO"** button
3. Click it and enter your **organization slug**
4. You'll be redirected to Keycloak
5. Login with the test user you created:
   - Username: `test.user`
   - Password: `<password-you-set>`
6. After successful authentication, you'll be redirected back to Infisical
7. Complete any email verification if prompted

### 7.6 Enforce OIDC SSO (Optional)

Once you've successfully tested OIDC login:

1. Go back to Organization Settings → SSO
2. Toggle **"Enforce OIDC SSO"** to ON
3. **Warning**: This will require all users to login via Keycloak

**Important**: Keep an admin account with email/password in case of issues. Use the admin portal at `http://localhost:8081/login/admin` if needed.

---

## ✅ Step 8: Verification Checklist

### Telemetry Verification

```bash
# Check no telemetry environment variables are set
docker exec secrets-infisical env | grep -E "TELEMETRY|POSTHOG|SENTRY"

# Should show:
# TELEMETRY_ENABLED=false
# SENTRY_DSN=(empty)
# POSTHOG_HOST=(empty)
# etc.
```

### OIDC Verification

```bash
# Test OIDC discovery endpoint from container
docker exec secrets-infisical curl -s http://host.docker.internal:8080/realms/ubivis/.well-known/openid-configuration | jq .issuer

# Should show:
# "http://localhost:8080/realms/ubivis"
```

### Feature Verification

Login to Infisical and check that these features are available:

- ✅ **SSO**: Organization Settings → SSO (OIDC enabled)
- ✅ **Groups**: Organization Settings → Groups (tab visible)
- ✅ **RBAC**: Organization Settings → Roles (custom roles available)
- ✅ **Audit Logs**: Organization Settings → Audit Logs (visible)

---

## 🎉 Success!

You now have:

✅ Infisical with OIDC SSO enabled (no license required)
✅ Full Keycloak integration
✅ All telemetry disabled (no data sent to Infisical)
✅ Enterprise features enabled:
  - OIDC SSO
  - SAML SSO (if needed)
  - LDAP (if needed)
  - Groups
  - RBAC
  - Audit Logs

---

## 🔧 Troubleshooting

### Build Fails

```bash
# Check build logs
tail -f apps/secrets/build.log

# Common issues:
# - Out of memory: Increase Docker memory to 8GB
# - Timeout: Run build again, will use cached layers
```

### OIDC Connection Fails

```bash
# Test Keycloak reachability from container
docker exec secrets-infisical curl -v http://host.docker.internal:8080/realms/ubivis/.well-known/openid-configuration

# If fails, check:
# 1. Keycloak is running: docker ps | grep keycloak
# 2. Port 8080 is accessible
# 3. Use host.docker.internal not localhost
```

### "License restriction" Error

```bash
# Verify patch was applied
cat apps/secrets/backend/src/ee/services/license/license-fns.ts | grep "oidcSSO"

# Should show: oidcSSO: true,

# If shows false, patch wasn't applied or wrong image is running
# Check image: docker inspect secrets-infisical | grep Image
# Should show: infisical:local
```

### Cannot Login After Enforcing SSO

```bash
# Use admin login portal
# URL: http://localhost:8081/login/admin
# Login with email/password (must be org admin)
```

---

## 📚 Next Steps

### Production Deployment

When ready to deploy to Coolify:

1. **Update URLs** in Keycloak and Infisical:
   ```bash
   # Replace localhost with your domain
   SITE_URL=https://secrets.yourdomain.com
   OIDC_DISCOVERY_URL=https://keycloak.yourdomain.com/realms/ubivis/.well-known/openid-configuration
   
   # Update Keycloak redirect URIs to match
   ```

2. **Generate production secrets**:
   ```bash
   # New encryption key
   openssl rand -hex 16
   
   # New auth secret
   openssl rand -base64 32
   ```

3. **Enable HTTPS**:
   - Configure SSL certificates in Coolify
   - Update all URLs to use https://

4. **Backup strategy**:
   ```bash
   # PostgreSQL backup
   docker exec secrets-postgres pg_dump -U infisical infisical > backup.sql
   ```

### User Management

- **Add users**: Create in Keycloak Users section
- **Groups**: Organize users in Keycloak Groups
- **Roles**: Assign roles in Infisical Organization Settings
- **Permissions**: Configure project-level access

---

## 📖 Documentation Reference

- **Complete options**: `KEYCLOAK_SSO_OPTIONS.md`
- **Patch details**: `ENABLE_OIDC_PATCH.md`
- **SSO integration**: `SSO_INTEGRATION.md`
- **Deployment guide**: `DEPLOYMENT.md`
