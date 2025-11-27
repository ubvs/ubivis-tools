# Keycloak SSO Integration - Complete Guide

## 📋 Summary

You have **two options** to integrate Infisical with Keycloak:

| Option | Cost | Setup Time | Maintenance | Support |
|--------|------|------------|-------------|---------|
| **1. Free OAuth** | FREE | 5 min | Low | Full |
| **2. Patched OIDC** | FREE | 30-60 min | Medium | None |
| **3. Licensed OIDC** | ~$299+/mo | 15 min | Low | Full |

## ⭐ Recommended Approach

**Start with Option 1 (Free OAuth)**, then decide if you need Option 2 (Patched OIDC) based on your requirements.

---

## Option 1: Free GitHub/Google OAuth (Recommended)

### Pros
- ✅ **FREE** - No license required
- ✅ **5 minute setup** - Quick to implement
- ✅ **Officially supported** - No source code modifications
- ✅ **Easy updates** - Just pull new Docker images
- ✅ **Works immediately** - No building required

### Cons
- ❌ **Not centralized** - Users need GitHub/Google accounts
- ❌ **External dependency** - Relies on third-party providers
- ❌ **Limited control** - Can't customize auth flow

### Quick Setup

1. **Create OAuth App** (GitHub example):
   ```bash
   # Go to: https://github.com/settings/developers
   # New OAuth App:
   - Name: Infisical Secrets Manager
   - Homepage: http://localhost:8081
   - Callback: http://localhost:8081/api/v1/sso/github/callback
   ```

2. **Configure Infisical**:
   ```bash
   # Edit .devcontainer/.env
   CLIENT_ID_GITHUB_LOGIN=your_github_client_id
   CLIENT_SECRET_GITHUB_LOGIN=your_github_client_secret
   ```

3. **Restart**:
   ```bash
   npx nx run secrets:restart
   ```

4. **Enable in UI**:
   - Login: http://localhost:8081
   - Org Settings → SSO → Enable GitHub SSO

### When to Use
- ✅ Need SSO quickly
- ✅ Team already uses GitHub/Google
- ✅ Don't need centralized user management
- ✅ Want officially supported solution

---

## Option 2: Patched Keycloak OIDC (Advanced)

### Pros
- ✅ **FREE** - No license fees
- ✅ **Centralized** - Full Keycloak integration
- ✅ **Full control** - Manage all users in Keycloak
- ✅ **Enterprise features** - RBAC, Groups, Audit Logs enabled

### Cons
- ❌ **Build required** - Must compile from source (15-30 min)
- ❌ **No official support** - Modified installation
- ❌ **Maintenance overhead** - Reapply patch on updates
- ❌ **Legal considerations** - Review license terms

### Setup Process

#### Step 1: Apply Patch

```bash
# Navigate to secrets app
cd apps/secrets

# Apply the patch (enables OIDC in source code)
./patch-oidc.sh

# This enables: OIDC SSO, SAML SSO, LDAP, Groups, RBAC, Audit Logs
```

#### Step 2: Build Custom Image

```bash
# Build from source with OIDC enabled (15-30 minutes)
npx nx run secrets:build-patched

# Or build manually:
npx nx run secrets:patch
npx nx run secrets:build-local
```

#### Step 3: Configure Keycloak

1. **Create OIDC Client** in Keycloak:
   ```
   Realm: ubivis
   Client type: OpenID Connect
   Client ID: infisical
   Client authentication: On
   Standard flow: Enabled
   ```

2. **Set Redirect URIs**:
   ```
   Root URL: http://localhost:8081
   Valid redirect URIs: http://localhost:8081/api/v1/sso/oidc/callback
   Web origins: http://localhost:8081
   ```

3. **Add Client Scopes**:
   - email
   - given name
   - family name

4. **Get Credentials**:
   - Copy Client Secret from Credentials tab
   - Copy Discovery URL: `http://localhost:8080/realms/ubivis/.well-known/openid-configuration`

#### Step 4: Configure Infisical

Update `.devcontainer/.env`:

```bash
# Required
SITE_URL=http://localhost:8081
AUTH_SECRET=<generate with: openssl rand -base64 32>
ENCRYPTION_KEY=<generate with: openssl rand -hex 16>

# Keycloak OIDC
OIDC_DISCOVERY_URL=http://host.docker.internal:8080/realms/ubivis/.well-known/openid-configuration
OIDC_CLIENT_ID=infisical
OIDC_CLIENT_SECRET=<client-secret-from-keycloak>
```

**Important**: Use `host.docker.internal` not `localhost` for Keycloak URL.

#### Step 5: Start Patched Version

```bash
# Using patched docker-compose
npx nx run secrets:start-patched

# Check logs
docker compose -f .devcontainer/docker-compose.patched.yml logs -f
```

#### Step 6: Enable OIDC in Infisical UI

1. Login: http://localhost:8081
2. Organization Settings → SSO
3. Click "Connect" for OIDC
4. Enter:
   - Discovery URL: `http://host.docker.internal:8080/realms/ubivis/.well-known/openid-configuration`
   - Client ID: `infisical`
   - Client Secret: (from Keycloak)
   - JWT Algorithm: `RS256`
5. Click "Update"
6. Toggle "Enable OIDC SSO"
7. Test with a Keycloak user
8. (Optional) Toggle "Enforce OIDC SSO"

### When to Use
- ✅ Need centralized authentication
- ✅ Already managing users in Keycloak
- ✅ Want enterprise features (RBAC, Groups, Audit Logs)
- ✅ Can maintain custom build
- ✅ Internal use only (not selling as service)

---

## Option 3: Licensed Keycloak OIDC (Enterprise)

### Pros
- ✅ **Official support** - Full Infisical support
- ✅ **Easy updates** - No patching needed
- ✅ **Production ready** - Battle-tested
- ✅ **All features** - Complete enterprise suite

### Cons
- ❌ **Cost** - Starting ~$299/month (Pro tier)
- ❌ **Ongoing expense** - Annual subscription

### Setup

1. **Purchase License**:
   - Contact: sales@infisical.com
   - Pricing: https://infisical.com/pricing

2. **Configure License**:
   ```bash
   # Add to .devcontainer/.env
   LICENSE_KEY=your_license_key_here
   ```

3. **Follow Official Docs**:
   - https://infisical.com/docs/documentation/platform/sso/keycloak-oidc

### When to Use
- ✅ Production deployment
- ✅ Need official support
- ✅ Budget available
- ✅ Don't want to maintain patches

---

## 🔄 Comparison Matrix

| Feature | Free OAuth | Patched OIDC | Licensed OIDC |
|---------|-----------|--------------|---------------|
| **Cost** | $0 | $0 | $299+/mo |
| **Setup Time** | 5 min | 60 min | 15 min |
| **Build Required** | No | Yes (30 min) | No |
| **Centralized Auth** | ❌ | ✅ | ✅ |
| **Keycloak Integration** | ❌ | ✅ | ✅ |
| **Official Support** | ✅ | ❌ | ✅ |
| **Easy Updates** | ✅ | ❌ | ✅ |
| **RBAC** | ❌ | ✅ | ✅ |
| **Groups** | ❌ | ✅ | ✅ |
| **Audit Logs** | Basic | ✅ | ✅ |
| **SAML SSO** | ❌ | ✅ | ✅ |
| **LDAP** | ❌ | ✅ | ✅ |

---

## 🚀 Quick Start Guides

### For GitHub OAuth (5 minutes)

```bash
# 1. Create OAuth app at https://github.com/settings/developers
# 2. Edit .devcontainer/.env:
CLIENT_ID_GITHUB_LOGIN=abc123
CLIENT_SECRET_GITHUB_LOGIN=xyz789

# 3. Restart
npx nx run secrets:restart

# 4. Enable in UI: Organization Settings → SSO → GitHub
```

### For Patched OIDC (60 minutes)

```bash
# 1. Patch source code
cd apps/secrets
./patch-oidc.sh

# 2. Build (15-30 minutes)
npx nx run secrets:build-patched

# 3. Configure Keycloak client (see detailed steps above)

# 4. Update .devcontainer/.env with OIDC settings

# 5. Start patched version
npx nx run secrets:start-patched

# 6. Enable OIDC in Infisical UI
```

---

## 📊 Decision Tree

```
Do you need Keycloak SSO specifically?
├─ No → Use GitHub/Google OAuth (Option 1) ✅
└─ Yes
   ├─ Have budget? (~$299/mo)
   │  ├─ Yes → Buy Enterprise License (Option 3) ✅
   │  └─ No → Continue...
   │
   └─ Can maintain custom build?
      ├─ Yes → Use Patched OIDC (Option 2) ✅
      └─ No → Use Free OAuth until budget available
```

---

## 🛠️ Available Nx Commands

### Standard (Pre-built image)

```bash
# Using official Infisical image (no OIDC/SAML)
npx nx run secrets:build       # Pull latest image
npx nx run secrets:start       # Start services
npx nx run secrets:stop        # Stop services
npx nx run secrets:logs        # View logs
npx nx run secrets:restart     # Restart services
```

### Patched (Custom build)

```bash
# Using custom-built image (with OIDC/SAML)
npx nx run secrets:patch           # Apply patch only
npx nx run secrets:build-local     # Build from source
npx nx run secrets:build-patched   # Patch + Build
npx nx run secrets:start-patched   # Start patched version
npx nx run secrets:stop-patched    # Stop patched version
npx nx run secrets:dev-patched     # Start with logs
```

---

## 🔐 Security Considerations

### For All Options

```bash
# Generate secure secrets
openssl rand -base64 32  # AUTH_SECRET
openssl rand -hex 16     # ENCRYPTION_KEY
```

### For Patched OIDC

- ⚠️ **Internal use only** - Don't redistribute modified version
- ✅ **Source available** - AGPL-3.0 allows modifications for own use
- 📝 **Document changes** - Keep track of patches for updates
- 🔄 **Update strategy** - Plan for reapplying patches

---

## 📖 Documentation Files

- **`SSO_INTEGRATION.md`** - Complete SSO setup guide
- **`ENABLE_OIDC_PATCH.md`** - Detailed patching instructions
- **`DEPLOYMENT.md`** - General deployment guide
- **`patch-oidc.sh`** - Automated patch script

---

## 🎯 Recommendations by Use Case

### Startup/Small Team (< 10 users)
**→ Use Option 1 (Free OAuth)**
- Cost-effective
- Quick to set up
- Easy to maintain

### Internal Tools (10-50 users)
**→ Use Option 2 (Patched OIDC)**
- Centralized auth
- Better user management
- No ongoing costs

### Production/Enterprise (50+ users)
**→ Use Option 3 (Licensed OIDC)**
- Official support critical
- Regular updates important
- Compliance requirements

---

## ❓ FAQ

### Q: Is patching legal?
**A:** Yes, for internal use. Infisical uses AGPL-3.0 which allows modifications for own use. You cannot resell the modified version as a service.

### Q: Will patches break on updates?
**A:** Possibly. You'll need to reapply patches after updating Infisical. The patch script makes this easier.

### Q: Can I migrate from OAuth to OIDC later?
**A:** Yes! Users can be linked across auth methods. Start with OAuth, upgrade to OIDC when ready.

### Q: How long does building take?
**A:** First build: 15-30 minutes. Subsequent builds: 5-10 minutes (cached layers).

### Q: Does patching affect performance?
**A:** No. The patch only changes license checks, not core functionality.

### Q: Can I patch other features?
**A:** Yes! The patch script also enables: SAML, LDAP, Groups, RBAC, Audit Logs. See `patch-oidc.sh`.

---

## 🆘 Getting Help

### For Free OAuth (Option 1)
- Official Docs: https://infisical.com/docs/documentation/platform/sso
- GitHub Discussions: https://github.com/Infisical/infisical/discussions
- Discord: https://infisical.com/discord

### For Patched OIDC (Option 2)
- See `ENABLE_OIDC_PATCH.md` troubleshooting section
- Check build logs: `docker logs secrets-infisical`
- Verify patch applied: `cat backend/src/ee/services/license/license-fns.ts | grep oidcSSO`

### For Licensed OIDC (Option 3)
- Enterprise Support: support@infisical.com
- Sales Questions: sales@infisical.com

---

## ✅ My Recommendation

**Start with GitHub/Google OAuth:**
1. Get your team access immediately
2. Evaluate if you actually need Keycloak integration
3. Decide later whether to:
   - Continue with OAuth (if it works well)
   - Upgrade to patched OIDC (if need centralized auth)
   - Purchase license (if need support + enterprise features)

This approach:
- ✅ Gets you started quickly
- ✅ Costs nothing
- ✅ Lets you evaluate requirements
- ✅ Provides easy migration path

**Then upgrade to patched OIDC if:**
- Need centralized user management
- Want Keycloak as identity provider  
- Can maintain custom builds
- Internal use only

**Or purchase license if:**
- Production deployment
- Need official support
- Want hassle-free updates
- Budget available
