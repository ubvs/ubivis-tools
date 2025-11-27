# Homarr + Keycloak Troubleshooting Guide

## Issue: Groups Not Syncing from Keycloak

### Symptoms:
- Created a group in Keycloak (e.g., `Tech`)
- Created matching group in Homarr (e.g., `Tech`)
- User is member of group in Keycloak
- User logs in to Homarr but is NOT added to the group
- Board permissions don't work for group members

### Root Cause:

**Group name mismatch** between what Keycloak sends in the token and what Homarr expects.

#### The Problem:

1. **Keycloak groups have paths**: `/Tech`, `/Administrators`, `/Users`
2. **Keycloak groups mapper** has a setting called `full.path`
3. **When `full.path=true`**: Token includes the full path → `"/Tech"`, `"/Administrators"`
4. **Homarr groups** are stored without the leading slash → `"Tech"`, `"Administrators"`
5. **Comparison fails**: `"/Tech" !== "Tech"` ❌

### Solution Applied:

✅ **Changed Keycloak groups mapper to `full.path=false`**

This makes Keycloak send group names **without** the leading slash:
- Before: Token sends `["/Tech", "/Administrators"]`
- After: Token sends `["Tech", "Administrators"]` ✅

### Configuration Changes Made:

#### 1. Keycloak Groups Mapper
```bash
# Updated mapper configuration
Mapper ID: e3b6f1c3-fc43-49f2-a856-0401957739eb
Setting: full.path = false ✅
```

#### 2. Homarr Environment Variables
```env
# Updated from:
AUTH_OIDC_ADMIN_ROLE=/Administrators
AUTH_OIDC_OWNER_ROLE=/Administrators

# To:
AUTH_OIDC_ADMIN_ROLE=Administrators ✅
AUTH_OIDC_OWNER_ROLE=Administrators ✅
```

#### 3. Docker Compose Defaults
```yaml
# Updated defaults in docker-compose.yml
- AUTH_OIDC_ADMIN_ROLE=${AUTH_OIDC_ADMIN_ROLE:-Administrators}
- AUTH_OIDC_OWNER_ROLE=${AUTH_OIDC_OWNER_ROLE:-Administrators}
```

### How to Verify the Fix:

#### 1. Check Keycloak Mapper Configuration
```bash
docker exec ssom-keycloak /opt/keycloak/bin/kcadm.sh config credentials \
    --server http://localhost:8080 --realm master --user admin --password admin

docker exec ssom-keycloak /opt/keycloak/bin/kcadm.sh get \
    client-scopes/522c92ac-7c56-4add-8df0-0224b1575670/protocol-mappers/models/e3b6f1c3-fc43-49f2-a856-0401957739eb \
    -r ubivis | grep "full.path"
```

**Expected output**: `"full.path" : "false"`

#### 2. Check Group Names Match
```bash
# Keycloak groups
docker exec ssom-keycloak /opt/keycloak/bin/kcadm.sh get groups -r ubivis --fields name

# Homarr groups
docker exec dashboard-homarr node -e "const Database = require('better-sqlite3'); \
const db = new Database('/appdata/db/db.sqlite'); \
const groups = db.prepare('SELECT name FROM \"group\" ORDER BY name').all(); \
console.log(groups.map(g => g.name).join('\n')); db.close();"
```

**They should match exactly** (without leading slash)

#### 3. Test Group Sync
1. **Logout** from Homarr
2. **Login** again via Keycloak
3. **Check group membership**:
```bash
docker exec dashboard-homarr node -e "const Database = require('better-sqlite3'); \
const db = new Database('/appdata/db/db.sqlite'); \
const members = db.prepare('SELECT gm.user_id, g.name as groupName, u.name as userName \
FROM groupMember gm JOIN \"group\" g ON gm.group_id = g.id JOIN user u ON gm.user_id = u.id \
ORDER BY g.name').all(); \
members.forEach(m => console.log(\`\${m.userName} -> \${m.groupName}\`)); db.close();"
```

**Expected**: User should be in all their Keycloak groups

### Scripts Created:

#### 1. Sync Groups from Keycloak
**File**: `.devcontainer/sync-groups-from-keycloak.sh`

Automatically fetches all groups from Keycloak and creates them in Homarr:
```bash
cd apps/dashboard
./.devcontainer/sync-groups-from-keycloak.sh
```

#### 2. Manual Group Creation
**File**: `.devcontainer/create-groups.cjs`

Creates specific groups manually:
```bash
docker cp .devcontainer/create-groups.cjs dashboard-homarr:/app/create-groups.cjs
docker exec dashboard-homarr node /app/create-groups.cjs
```

### Common Issues:

#### Issue 1: "Some members are from external providers"
**Status**: ✅ **This is CORRECT!**

This message means:
- Users are managed by Keycloak (external provider)
- Group membership syncs automatically
- You cannot manually add/remove users in Homarr UI
- **This is the expected behavior for SSO**

#### Issue 2: User not in group after login
**Checklist**:
1. ✅ Group exists in Homarr with exact same name
2. ✅ User is member of group in Keycloak
3. ✅ Keycloak mapper has `full.path=false`
4. ✅ User has logged out and logged in again
5. ✅ Check Homarr logs for sync messages

#### Issue 3: Admin access not working
**Checklist**:
1. ✅ User is in `/Administrators` group in Keycloak
2. ✅ `Administrators` group exists in Homarr (no leading slash)
3. ✅ `AUTH_OIDC_ADMIN_ROLE=Administrators` (no leading slash)
4. ✅ User has logged out and logged in again

### Debug Commands:

#### View Homarr Logs
```bash
docker logs dashboard-homarr --tail 100 -f
```

Look for:
- `Using profile groups (groups): ["Tech","Administrators"]`
- `Homarr does not have the user in certain groups`
- `Added user to groups successfully`

#### Check User's Groups in Database
```bash
docker exec dashboard-homarr node -e "const Database = require('better-sqlite3'); \
const db = new Database('/appdata/db/db.sqlite'); \
const userId = 'YOUR_USER_ID'; \
const groups = db.prepare('SELECT g.name FROM groupMember gm \
JOIN \"group\" g ON gm.group_id = g.id WHERE gm.user_id = ?').all(userId); \
console.log(groups.map(g => g.name).join(', ')); db.close();"
```

#### Check Keycloak Token (Browser DevTools)
1. Login to Homarr
2. Open DevTools → Network tab
3. Find request to `/api/auth/session`
4. Check response body for `groups` array
5. Should contain: `["Tech", "Administrators"]` (without leading slash)

### Prevention:

#### When Adding New Groups:
1. **Create group in Keycloak** first
2. **Run sync script** to create in Homarr:
   ```bash
   ./.devcontainer/sync-groups-from-keycloak.sh
   ```
3. **Assign users** to group in Keycloak
4. **Users login** → automatic sync ✅

#### When Renaming Groups:
1. **Rename in Keycloak** first
2. **Rename in Homarr** to match exactly
3. **Users logout/login** → membership updates

### Related Documentation:

- **Group Sync Guide**: `GROUP_SYNC.md`
- **Keycloak Setup**: `KEYCLOAK_SETUP.md`
- **Main README**: `README.md`

---

**Status**: ✅ **Issue Resolved**  
**Fix Applied**: Nov 12, 2025  
**Keycloak Mapper**: `full.path=false`  
**Group Format**: Without leading slash
