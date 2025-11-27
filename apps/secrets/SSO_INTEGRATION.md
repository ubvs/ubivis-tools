# Infisical SSO Integration Guide

## Overview

Infisical supports multiple SSO authentication methods. For self-hosted instances:

- **FREE**: Google, GitHub, GitLab OAuth
- **PAID** (Enterprise License Required): SAML, OIDC (including Keycloak)

## Option 1: Free GitHub/Google SSO (Recommended)

### Prerequisites
- GitHub or Google OAuth app
- Users have GitHub/Google accounts

### Configuration Steps

#### A. Using GitHub SSO

1. **Create GitHub OAuth App**
   - Go to: https://github.com/settings/developers
   - Click "New OAuth App"
   - Set Application name: `Infisical Secrets Manager`
   - Homepage URL: `http://localhost:8081` (or your domain)
   - Authorization callback URL: `http://localhost:8081/api/v1/sso/github/callback`
   - Copy the **Client ID** and generate a **Client Secret**

2. **Update Infisical Environment Variables**
   
   Add to `.devcontainer/.env`:
   ```bash
   # GitHub SSO
   CLIENT_ID_GITHUB_LOGIN=your_github_client_id
   CLIENT_SECRET_GITHUB_LOGIN=your_github_client_secret
   ```

3. **Restart Infisical**
   ```bash
   npx nx run secrets:stop
   npx nx run secrets:start
   ```

4. **Enable in Infisical UI**
   - Login to Infisical: http://localhost:8081
   - Go to Organization Settings > SSO
   - Enable GitHub SSO
   - Users can now login with GitHub

#### B. Using Google SSO

1. **Create Google OAuth App**
   - Go to: https://console.cloud.google.com/apis/credentials
   - Create Project (if needed)
   - Create OAuth 2.0 Client ID
   - Application type: Web application
   - Authorized redirect URIs: `http://localhost:8081/api/v1/sso/google/callback`
   - Copy the **Client ID** and **Client Secret**

2. **Update Infisical Environment Variables**
   
   Add to `.devcontainer/.env`:
   ```bash
   # Google SSO
   CLIENT_ID_GOOGLE_LOGIN=your_google_client_id.apps.googleusercontent.com
   CLIENT_SECRET_GOOGLE_LOGIN=your_google_client_secret
   ```

3. **Restart and Enable** (same as GitHub steps 3-4)

### Advantages
- ✅ **Free** - No license required
- ✅ **Simple setup** - OAuth configuration only
- ✅ **Widely adopted** - Most users have GitHub/Google accounts
- ✅ **Works immediately** - No enterprise license needed

### Limitations
- ❌ Not centralized through your Keycloak instance
- ❌ Users need external accounts (GitHub/Google)
- ❌ Less control over authentication flow

---

## Option 2: Keycloak OIDC Integration (Enterprise License Required)

<Warning>
This option requires purchasing an enterprise license for self-hosted Infisical.
Contact: sales@infisical.com
</Warning>

### Prerequisites
- Infisical Enterprise License
- Keycloak instance running (http://localhost:8080)
- Access to create clients in Keycloak

### Configuration Steps

#### 1. Create OIDC Client in Keycloak

1.1. **Navigate to Clients**
   - Keycloak Admin Console → Realm: `ubivis` → Clients
   - Click "Create client"

1.2. **General Settings**
   - Client type: `OpenID Connect`
   - Client ID: `infisical`
   - Name: `Infisical Secrets Manager`
   - Click "Next"

1.3. **Capability Config**
   - Client authentication: `On`
   - Authorization: `Off`
   - Authentication flow:
     - ✅ Standard flow
     - ✅ Direct access grants
   - Click "Next"

1.4. **Login Settings**
   - Root URL: `http://localhost:8081`
   - Home URL: `http://localhost:8081`
   - Valid redirect URIs: `http://localhost:8081/api/v1/sso/oidc/callback`
   - Valid post logout redirect URIs: `http://localhost:8081`
   - Web origins: `http://localhost:8081`
   - Click "Save"

#### 2. Configure Client Scopes and Mappers

2.1. **Navigate to Client Scopes**
   - Go to the `infisical` client
   - Click "Client scopes" tab
   - Click on the client's dedicated scope (e.g., `infisical-dedicated`)

2.2. **Add Predefined Mappers**
   - Click "Add predefined mapper"
   - Select: `email`, `given name`, `family name`
   - Click "Add"

2.3. **Add Custom Username Mapper** (if needed)
   - Click "Add mapper" → "By configuration"
   - Mapper type: `User Property`
   - Name: `username`
   - Property: `username`
   - Token Claim Name: `preferred_username`
   - Claim JSON Type: `String`
   - Add to ID token: `On`
   - Add to access token: `On`
   - Add to userinfo: `On`
   - Click "Save"

#### 3. Get Client Credentials

3.1. **Get Client Secret**
   - Go to `infisical` client → "Credentials" tab
   - Copy the **Client Secret**

3.2. **Get Discovery URL**
   - Go to Realm Settings → General tab → Endpoints
   - Click "OpenID Endpoint Configuration"
   - Copy the URL (should be: `http://localhost:8080/realms/ubivis/.well-known/openid-configuration`)

#### 4. Configure Infisical for OIDC

Update `.devcontainer/.env`:

```bash
# Keycloak OIDC Configuration
# Discovery URL
OIDC_DISCOVERY_URL=http://localhost:8080/realms/ubivis/.well-known/openid-configuration

# Client credentials
OIDC_CLIENT_ID=infisical
OIDC_CLIENT_SECRET=your_client_secret_from_keycloak

# JWT Algorithm (RS256 is default for Keycloak)
OIDC_SIGNATURE_ALGORITHM=RS256

# Optional: Configure specific OIDC endpoints (if not using discovery)
# OIDC_AUTHORIZATION_ENDPOINT=http://localhost:8080/realms/ubivis/protocol/openid-connect/auth
# OIDC_TOKEN_ENDPOINT=http://localhost:8080/realms/ubivis/protocol/openid-connect/token
# OIDC_USERINFO_ENDPOINT=http://localhost:8080/realms/ubivis/protocol/openid-connect/userinfo
# OIDC_JWKS_URI=http://localhost:8080/realms/ubivis/protocol/openid-connect/certs
```

#### 5. Restart Infisical

```bash
npx nx run secrets:stop
npx nx run secrets:start
```

#### 6. Enable OIDC in Infisical UI

6.1. **Access Infisical Admin**
   - Login: http://localhost:8081
   - Go to Organization Settings → Single Sign-On (SSO)

6.2. **Configure OIDC**
   - Click "Connect" for OIDC
   - Configuration Type: `Discovery URL`
   - Discovery Document URL: `http://localhost:8080/realms/ubivis/.well-known/openid-configuration`
   - JWT Signature Algorithm: `RS256`
   - Client ID: `infisical`
   - Client Secret: (paste from Keycloak)
   - Click "Update"

6.3. **Enable OIDC SSO**
   - Toggle "Enable OIDC SSO"
   - Test with a user account first

6.4. **Enforce OIDC (Optional)**
   - After successful test, toggle "Enforce OIDC SSO"
   - ⚠️ This requires all users to login via Keycloak

### Keycloak User Management

#### Create Test User in Keycloak

```bash
# Via Keycloak Admin Console
1. Go to Users → Add user
2. Set username, email, first name, last name
3. Go to Credentials tab
4. Set password (uncheck "Temporary")
5. Save
```

#### Group Mapping (Enterprise Feature)

Configure group-based access control:
- Map Keycloak groups to Infisical roles
- See: https://infisical.com/docs/documentation/platform/sso/keycloak-oidc/group-membership-mapping

### Advantages
- ✅ Centralized authentication through Keycloak
- ✅ Full control over user lifecycle
- ✅ Group-based access control
- ✅ Integration with existing identity infrastructure

### Limitations
- ❌ Requires enterprise license purchase
- ❌ More complex setup
- ❌ Additional licensing cost

---

## Production Deployment Considerations

### For Coolify Deployment

1. **Update URLs** in Keycloak and Infisical:
   ```bash
   # Replace localhost URLs with production domain
   SITE_URL=https://secrets.yourdomain.com
   OIDC_DISCOVERY_URL=https://keycloak.yourdomain.com/realms/ubivis/.well-known/openid-configuration
   ```

2. **Configure Redirect URIs** in OAuth/OIDC provider:
   - GitHub: `https://secrets.yourdomain.com/api/v1/sso/github/callback`
   - Google: `https://secrets.yourdomain.com/api/v1/sso/google/callback`
   - Keycloak OIDC: `https://secrets.yourdomain.com/api/v1/sso/oidc/callback`

3. **SSL/TLS Configuration**:
   - Ensure SSL certificates are properly configured
   - Use HTTPS for all redirect URIs
   - Configure Coolify to handle SSL termination

### Security Best Practices

1. **Strong Secrets**:
   ```bash
   # Generate secure AUTH_SECRET
   openssl rand -base64 32
   
   # Generate secure ENCRYPTION_KEY
   openssl rand -hex 16
   ```

2. **Environment Isolation**:
   - Use different OAuth apps for dev/staging/prod
   - Separate Keycloak realms or clients per environment

3. **Backup Admin Access**:
   - Maintain email/password login for at least one admin
   - Use Admin Login Portal (/login/admin) for emergency access

4. **Regular Security Audits**:
   - Review SSO configuration regularly
   - Monitor authentication logs
   - Update client secrets periodically

---

## Troubleshooting

### GitHub/Google SSO Issues

**Problem**: "OAuth app not configured"
```bash
# Solution: Check environment variables
docker exec secrets-infisical env | grep CLIENT_ID
docker exec secrets-infisical env | grep CLIENT_SECRET
```

**Problem**: Redirect URI mismatch
```bash
# Solution: Ensure callback URL matches exactly in OAuth app
# GitHub: http://localhost:8081/api/v1/sso/github/callback
# Google: http://localhost:8081/api/v1/sso/google/callback
```

### Keycloak OIDC Issues

**Problem**: "Discovery endpoint unreachable"
```bash
# Test discovery endpoint
curl http://localhost:8080/realms/ubivis/.well-known/openid-configuration

# Check if Infisical can reach Keycloak
docker exec secrets-infisical curl http://host.docker.internal:8080/realms/ubivis/.well-known/openid-configuration
```

**Problem**: "Invalid client credentials"
```bash
# Verify client secret in Keycloak
# Keycloak Admin → Clients → infisical → Credentials tab
# Regenerate secret if needed
```

**Problem**: "User attributes missing"
```bash
# Check client scope mappers
# Ensure email, given_name, family_name mappers are configured
# Verify "Add to ID token" and "Add to userinfo" are enabled
```

### General SSO Issues

**Problem**: Can't login after enabling SSO enforcement
```bash
# Solution: Use Admin Login Portal
# Access: http://localhost:8081/login/admin
# Login with email/password (must be Organization Admin)
```

**Problem**: Email verification loop
```bash
# Solution: Configure email trust in Server Admin Console
# Or: Complete email verification for each user
```

---

## Testing SSO Integration

### Test GitHub SSO

```bash
1. Navigate to http://localhost:8081
2. Click "Continue with GitHub"
3. Authorize the OAuth app
4. Verify successful login
5. Check user appears in Infisical organization
```

### Test Keycloak OIDC

```bash
1. Create test user in Keycloak
2. Navigate to http://localhost:8081
3. Click "Continue with OIDC" or organization-specific login
4. Enter Keycloak credentials
5. Verify successful authentication
6. Check user profile in Infisical
```

### Verify SSO Configuration

```bash
# Check Infisical logs
npx nx run secrets:logs

# Check for SSO-related errors
docker exec secrets-infisical cat /var/log/infisical.log | grep -i sso

# Test API health
curl http://localhost:8081/api/status
```

---

## Next Steps

### Immediate (Free Option)
1. ✅ Set up GitHub or Google OAuth app
2. ✅ Configure environment variables
3. ✅ Test SSO login
4. ✅ Onboard team members

### Future (Enterprise Option)
1. 📧 Contact sales@infisical.com for enterprise license
2. 💳 Purchase license
3. 🔐 Configure Keycloak OIDC integration
4. 👥 Migrate users to centralized authentication

---

## Resources

- **Infisical SSO Docs**: https://infisical.com/docs/documentation/platform/sso/overview
- **GitHub OAuth Apps**: https://docs.github.com/en/developers/apps/building-oauth-apps
- **Google OAuth Setup**: https://developers.google.com/identity/protocols/oauth2
- **Keycloak OIDC**: https://infisical.com/docs/documentation/platform/sso/keycloak-oidc
- **Enterprise License**: mailto:sales@infisical.com

---

## Summary

**Current Recommendation**: Start with **free GitHub or Google SSO** to get your team access immediately. Later, when budget allows, upgrade to enterprise license for full Keycloak OIDC integration.

This approach provides:
- ✅ Immediate SSO functionality
- ✅ No additional costs
- ✅ Simple setup
- ✅ Easy migration path to Keycloak later
