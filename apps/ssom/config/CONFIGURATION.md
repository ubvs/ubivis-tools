# Keycloak Configuration Guide - Ubivis Realm

This guide walks you through configuring Keycloak for the Ubivis internal tools platform.

## Overview

This configuration includes:
- **Ubivis Realm**: Pre-configured realm for internal tools
- **Roles**: admin, user, viewer
- **Groups**: Administrators, Users, Viewers with role mappings
- **Security Settings**: Brute force protection, session management
- **Event Logging**: Login/logout events tracked
- **LDAP Integration**: Ready for corporate SSO (see `ldap-setup-guide.md`)

---

## Quick Start

### 1. Import the Ubivis Realm

1. **Access Keycloak Admin Console**:
   ```bash
   # Ensure Keycloak is running
   nx start ssom
   
   # Open in browser
   open http://localhost:8080/admin
   ```

2. **Login**:
   - Username: `admin`
   - Password: `admin`

3. **Import Realm**:
   - Click **Create Realm** (top-left dropdown next to "master")
   - Click **Browse** button
   - Navigate to `apps/ssom/config/ubivis-realm.json`
   - Select the file
   - Click **Create**

4. **Verify Import**:
   - You should now see "Ubivis" in the realm selector
   - Check that roles exist: Go to **Realm roles**
   - Check that groups exist: Go to **Groups**

---

## Realm Configuration Details

### Security Settings

**Session Management**:
- Access Token Lifespan: 5 minutes
- SSO Session Idle: 30 minutes
- SSO Session Max: 10 hours
- Remember Me: Enabled

**Brute Force Protection**:
- Enabled with 5 max failed attempts
- 15 minute lockout after failures
- Progressive wait time increase

**Password Policy** (to be configured):
- Go to **Authentication** → **Policies** → **Password Policy**
- Recommended settings:
  - Minimum Length: 8
  - Not Username
  - Uppercase
  - Lowercase
  - Digits
  - Special Characters

### Roles

Three realm roles are pre-configured:

1. **admin**: Full administrative access to all tools
2. **user**: Standard user access
3. **viewer**: Read-only access

Default role for new users: `user`

### Groups

Three groups with automatic role assignment:

1. **Administrators** → `admin` role
2. **Users** → `user` role
3. **Viewers** → `viewer` role

---

## LDAP / Corporate SSO Setup

For LDAP/Active Directory integration, see the comprehensive guide:

**📘 [LDAP Setup Guide](./ldap-setup-guide.md)**

Quick overview:
1. Configure LDAP connection in User Federation
2. Map LDAP groups to Keycloak groups/roles
3. Synchronize users and groups
4. Test authentication

---

## Setting Up SSO Clients for Your Apps

Once the realm is configured, add SSO clients for your internal tools.

### Client Types

**Public Clients**: For browser-based apps (SPAs)
- React, Angular, Vue apps
- No client secret needed
- Uses PKCE for security

**Confidential Clients**: For backend services
- Node.js, Java, Python services
- Requires client secret
- Server-to-server communication

### Example: Creating a Client

1. **Navigate to Clients**:
   - Select **Ubivis** realm
   - Go to **Clients** in left menu
   - Click **Create client**

2. **General Settings**:
   ```
   Client type: OpenID Connect
   Client ID: youtrack  (or your app name)
   Name: Youtrack Issue Tracker
   Description: Project management tool
   Always display in UI: ON
   ```
   Click **Next**

3. **Capability Config**:
   ```
   Client authentication: ON (for confidential) or OFF (for public)
   Authorization: OFF (unless using fine-grained auth)
   Authentication flow:
     ☑ Standard flow (OAuth 2.0 Authorization Code)
     ☑ Direct access grants (for testing)
     ☐ Implicit flow (deprecated, don't use)
     ☐ Service accounts roles (for machine-to-machine)
   ```
   Click **Next**

4. **Login Settings**:
   ```
   Root URL: http://localhost:8080 (your app's base URL)
   Home URL: http://localhost:8080
   Valid redirect URIs: 
     - http://localhost:8080/*
     - http://youtrack.yourdomain.com/*
   Valid post logout redirect URIs:
     - http://localhost:8080
     - +  (means: allow all redirect URIs)
   Web origins:
     - *  (or specific: http://localhost:8080)
   ```
   Click **Save**

5. **Get Client Credentials** (for confidential clients):
   - Go to **Credentials** tab
   - Copy the **Client secret**
   - Save this securely for your app configuration

### Client Configuration Examples

#### For Youtrack (Confidential Client)
```
Client ID: youtrack
Client Authentication: ON
Valid Redirect URIs: http://localhost:8080/hub/api/rest/oauth2/auth
Client Secret: [generated-secret]
```

#### For Rocket.Chat (Confidential Client)
```
Client ID: rocketchat
Client Authentication: ON
Valid Redirect URIs: http://localhost:3000/_oauth/keycloak
Client Secret: [generated-secret]
```

#### For React/Angular App (Public Client)
```
Client ID: admin-portal
Client Authentication: OFF
Valid Redirect URIs: http://localhost:4200/*
PKCE: Required (set in Advanced Settings)
```

---

## Role Mapping for Clients

Map realm roles to client-specific roles:

1. **Go to Client**:
   - Select your client
   - Go to **Client scopes** tab
   - Click on the dedicated scope (e.g., `youtrack-dedicated`)

2. **Add Mappers**:
   - Click **Add mapper** → **By configuration**
   - Select **User Realm Role**
   ```
   Name: realm-roles
   Mapper Type: User Realm Role
   Token Claim Name: realm_roles
   Claim JSON Type: String
   Add to ID token: ON
   Add to access token: ON
   Add to userinfo: ON
   ```

3. **Test Token Contents**:
   - Go to **Client scopes** → **Evaluate**
   - Select a user
   - Click **Generated access token**
   - Verify roles are included

---

## OpenID Connect Endpoints

Your apps will need these endpoints:

### Discovery URL (Recommended)
```
http://localhost:8080/realms/ubivis/.well-known/openid-configuration
```

### Individual Endpoints
```
Authorization: http://localhost:8080/realms/ubivis/protocol/openid-connect/auth
Token: http://localhost:8080/realms/ubivis/protocol/openid-connect/token
Userinfo: http://localhost:8080/realms/ubivis/protocol/openid-connect/userinfo
JWKS: http://localhost:8080/realms/ubivis/protocol/openid-connect/certs
End Session: http://localhost:8080/realms/ubivis/protocol/openid-connect/logout
```

### For Production
Replace `http://localhost:8080` with your domain:
```
https://sso.yourdomain.com/realms/ubivis/...
```

---

## Testing SSO

### 1. Test with Account Console

```bash
# Open account console
open http://localhost:8080/realms/ubivis/account
```

- Login with a test user (or LDAP user if configured)
- Verify user info is displayed
- Test logout

### 2. Test Token Generation

Use curl to test token generation:

```bash
curl -X POST 'http://localhost:8080/realms/ubivis/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'client_id=youtrack' \
  -d 'client_secret=YOUR_CLIENT_SECRET' \
  -d 'grant_type=password' \
  -d 'username=testuser' \
  -d 'password=testpass'
```

Successful response:
```json
{
  "access_token": "eyJhbG...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbG...",
  "token_type": "Bearer"
}
```

### 3. Decode and Verify Token

Use https://jwt.io to decode the access token and verify:
- `iss`: Issuer is your Keycloak realm
- `aud`: Audience includes your client ID
- `realm_access.roles`: Contains user's roles
- `exp`: Token expiration

---

## User Management

### Creating Test Users (Manual)

1. **Navigate to Users**:
   - Select **Ubivis** realm
   - Go to **Users**
   - Click **Add user**

2. **User Details**:
   ```
   Username: testuser
   Email: testuser@example.com
   First name: Test
   Last name: User
   Email verified: ON
   Enabled: ON
   ```
   Click **Create**

3. **Set Password**:
   - Go to **Credentials** tab
   - Click **Set password**
   - Enter password
   - Temporary: OFF (so user doesn't have to change it)
   - Click **Save**

4. **Assign Roles**:
   - Go to **Role mapping** tab
   - Click **Assign role**
   - Select roles (e.g., `user`)
   - Click **Assign**

5. **Assign to Group** (Optional):
   - Go to **Groups** tab
   - Click **Join Group**
   - Select group (e.g., "Users")
   - Click **Join**

### Bulk User Import

For importing many users, use LDAP federation (see `ldap-setup-guide.md`) or create a JSON import file.

---

## Monitoring and Logs

### Event Logs

View user activity:

1. **Navigate to Events**:
   - Select **Ubivis** realm
   - Go to **Events** → **Login events**

2. **View Activity**:
   - See all login/logout events
   - Filter by user, client, or date
   - Events retained for 3 days (configurable)

### Admin Events

Track admin changes:

1. **Navigate to Admin Events**:
   - Go to **Events** → **Admin events**

2. **View Changes**:
   - See all configuration changes
   - Track who made changes and when

### Container Logs

```bash
# View Keycloak logs
nx logs ssom

# Follow logs in real-time
docker logs -f ssom-keycloak
```

---

## Backup and Export

### Export Realm Configuration

1. **Via Admin Console**:
   - Select **Ubivis** realm
   - Go to **Realm settings**
   - Click **Action** → **Partial export**
   - Select what to export:
     ☑ Export groups and roles
     ☑ Export clients
     ☐ Export users (not recommended for large datasets)
   - Click **Export**

2. **Via CLI** (inside container):
   ```bash
   docker exec -it ssom-keycloak /opt/keycloak/bin/kc.sh export \
     --dir /tmp/export \
     --realm ubivis \
     --users realm_file
   ```

### Database Backup

Backup PostgreSQL database:

```bash
# Backup
docker exec ssom-postgres pg_dump -U postgres keycloak > keycloak-backup.sql

# Restore
docker exec -i ssom-postgres psql -U postgres keycloak < keycloak-backup.sql
```

---

## Production Deployment

### Environment Variables for Production

Update `apps/ssom/.env`:

```env
# Admin credentials (change these!)
KC_BOOTSTRAP_ADMIN_USERNAME=your-admin-username
KC_BOOTSTRAP_ADMIN_PASSWORD=your-strong-password

# Database
KC_DB_USERNAME=keycloak_prod
KC_DB_PASSWORD=your-db-password

# Hostname
KC_HOSTNAME=sso.yourdomain.com
KC_HOSTNAME_STRICT=true
KC_HTTP_ENABLED=false  # HTTPS only

# Logging
KC_LOG_LEVEL=INFO
```

### Production Checklist

- [ ] Change default admin password
- [ ] Use strong database password
- [ ] Enable HTTPS only (KC_HTTP_ENABLED=false)
- [ ] Set proper hostname
- [ ] Configure email server (SMTP)
- [ ] Set up LDAP/AD integration
- [ ] Configure password policies
- [ ] Set up regular database backups
- [ ] Enable and review security headers
- [ ] Test all SSO integrations
- [ ] Document client configurations
- [ ] Set up monitoring and alerts

---

## Troubleshooting

### Realm Import Failed

**Problem**: Error importing realm JSON

**Solutions**:
- Ensure JSON is valid (use JSON validator)
- Check Keycloak logs for specific error
- Try creating realm manually first, then import partial config

### Client Cannot Authenticate

**Problem**: "Invalid client credentials" or similar

**Solutions**:
- Verify client ID matches exactly
- Check client secret is correct
- Ensure client authentication is ON for confidential clients
- Verify redirect URIs match exactly
- Check token endpoint URL is correct

### Roles Not Appearing in Token

**Problem**: Roles missing from access token

**Solutions**:
- Check role mappings are correct
- Verify user has roles assigned (directly or via groups)
- Check client scopes include role mappers
- Use "Evaluate" feature in client scopes to test

### LDAP Connection Issues

See detailed troubleshooting in `ldap-setup-guide.md`

---

## Next Steps

1. ✅ Import Ubivis realm
2. ✅ Configure LDAP integration (see `ldap-setup-guide.md`)
3. ✅ Create clients for your apps (Youtrack, Rocket.Chat, etc.)
4. ✅ Test SSO with each app
5. ✅ Configure production settings
6. ✅ Deploy to Coolify

---

## Additional Resources

- **Keycloak Documentation**: https://www.keycloak.org/documentation
- **OIDC Spec**: https://openid.net/specs/openid-connect-core-1_0.html
- **OAuth 2.0**: https://oauth.net/2/
- **JWT.io**: https://jwt.io (for token debugging)

## Support

For issues:
1. Check Keycloak container logs: `nx logs ssom`
2. Review event logs in admin console
3. Check the troubleshooting sections
4. Consult Keycloak documentation