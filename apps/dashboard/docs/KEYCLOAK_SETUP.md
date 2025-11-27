# Homarr Dashboard + Keycloak Integration ✅

## Connection Status

✅ **Dashboard**: Running on http://localhost:7575  
✅ **Keycloak**: Connected to `ssom-keycloak:8080`  
✅ **Realm**: `ubivis`  
✅ **Client**: `dashboard`  
✅ **Network**: Both containers on same Docker network

## Configuration Summary

### Environment Variables
```env
AUTH_PROVIDER=oidc
AUTH_OIDC_URI=http://ssom-keycloak:8080/realms/ubivis
AUTH_OIDC_CLIENT_ID=dashboard
AUTH_OIDC_CLIENT_SECRET=PHGSO07cGxjVouxxtJfqJegMuYMNjwdu
AUTH_OIDC_SCOPE=openid profile email groups
AUTH_OIDC_ADMIN_ROLE=/Administrators
AUTH_OIDC_OWNER_ROLE=/Administrators
AUTH_SECRET=vKB0qBe5we/oy62nIuEuB+p6OurnasZRevYqL831/zc=
SECRET_ENCRYPTION_KEY=841f05381c014bc9fcae27e54494a32f57e0f1d8aaf558376d08dbdb799561af
NEXTAUTH_URL=http://localhost:7575
```

### Keycloak Client Configuration

**Client ID**: `dashboard`  
**Client Secret**: `PHGSO07cGxjVouxxtJfqJegMuYMNjwdu`  
**Valid Redirect URIs**: `http://localhost:7575/*`  
**Web Origins**: `http://localhost:7575`

**Default Client Scopes**:
- ✅ `web-origins`
- ✅ `acr`
- ✅ `roles`
- ✅ `profile`
- ✅ `groups` ← **Important for admin access**
- ✅ `basic`
- ✅ `email`

**Groups Mapper**: ✅ Configured
- **Mapper Name**: `group-membership`
- **Mapper Type**: `oidc-group-membership-mapper`
- **Full Path**: `true` ← **Required for `/Administrators`**
- **Claim Name**: `groups`
- **Token Claims**: ID Token, Access Token, Userinfo

### Groups Structure

```
/Administrators (Admin access)
  └─ paulo.cesar@ubivis.io ✅
  
/Users (Standard users)

/Viewers (Read-only access)
```

### Admin User

**Username**: `paulo.cesar@ubivis.io`  
**Group**: `/Administrators`  
**Admin Access**: ✅ Enabled

## How to Access

### 1. Open Dashboard
```bash
open http://localhost:7575
```

### 2. Click "Sign in with Keycloak"

### 3. Login Credentials
- **Username**: `paulo.cesar@ubivis.io`
- **Password**: Your Keycloak password

### 4. Admin Access
Once logged in, you'll have full admin access because:
- ✅ You're in `/Administrators` group
- ✅ Token includes `groups` claim with full path
- ✅ Homarr recognizes `/Administrators` as admin role

## Troubleshooting

### If login redirects to error page:
1. Check container logs:
   ```bash
   npx nx logs dashboard
   ```

2. Verify Keycloak is accessible from dashboard:
   ```bash
   docker exec dashboard-homarr wget -qO- http://ssom-keycloak:8080/realms/ubivis/.well-known/openid-configuration
   ```

### If admin access is denied:
1. Verify group membership:
   ```bash
   # Check your user is in Administrators group
   docker exec ssom-keycloak /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin
   docker exec ssom-keycloak /opt/keycloak/bin/kcadm.sh get groups/b7f9218c-358c-4ad7-9220-9c84b4f62460/members -r ubivis
   ```

2. Logout and login again to refresh token

3. Check token includes groups:
   - Login to dashboard
   - Check browser DevTools → Network → Look for `/auth/session`
   - Verify response includes `groups: ["/Administrators"]`

### If "Invalid environment variables" error:
1. Verify `.env` file exists:
   ```bash
   cat apps/dashboard/.devcontainer/.env
   ```

2. Recreate if needed:
   ```bash
   cd apps/dashboard/.devcontainer
   ./setup-env.sh
   ```

3. Restart dashboard:
   ```bash
   npx nx restart dashboard
   ```

## Nx Commands

```bash
# Start dashboard
npx nx start dashboard

# Stop dashboard
npx nx stop dashboard

# Restart dashboard
npx nx restart dashboard

# View logs
npx nx logs dashboard

# Rebuild image
npx nx build dashboard
```

## Next Steps

1. **Configure Dashboard**:
   - Create your first board
   - Add widgets
   - Customize appearance

2. **Add More Users**:
   - Add users to Keycloak
   - Assign to appropriate groups:
     - `/Administrators` → Full access
     - `/Users` → Standard access
     - `/Viewers` → Read-only access

3. **Customize Groups**:
   - Update `AUTH_OIDC_ADMIN_ROLE` in `.env` if you want different admin group
   - Update `AUTH_OIDC_OWNER_ROLE` for board ownership permissions

## Success Checklist

- [x] Dashboard built from source (v1.43.2)
- [x] Docker image created successfully
- [x] Container running without errors
- [x] Environment variables configured
- [x] Keycloak connection working
- [x] Groups scope configured
- [x] Groups mapper with full path enabled
- [x] Admin user in `/Administrators` group
- [x] Ready for login! 🎉

## Documentation

- **Homarr Docs**: https://homarr.dev/docs/
- **Keycloak Docs**: https://www.keycloak.org/documentation
- **OIDC Spec**: https://openid.net/specs/openid-connect-core-1_0.html

---

**Status**: ✅ **READY TO USE**  
**Access**: http://localhost:7575  
**Admin**: paulo.cesar@ubivis.io
