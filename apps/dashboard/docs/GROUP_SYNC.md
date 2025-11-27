# Homarr + Keycloak Group Synchronization

## How It Works

Homarr **automatically synchronizes group membership** from Keycloak when users log in via OIDC. However, **the groups must already exist in Homarr's database** before synchronization can occur.

### Synchronization Flow:

```
1. User logs in via Keycloak
2. Keycloak returns token with groups claim: ["Administrators", "Users"]
3. Homarr checks which groups exist in its database
4. Homarr adds user to matching groups
5. Homarr removes user from groups they're no longer in (except "everyone")
```

## ✅ Groups Created

The following groups have been created in Homarr to match Keycloak:

| Homarr Group | Keycloak Group | Purpose |
|--------------|----------------|---------|
| `Administrators` | `/Administrators` | Full admin access |
| `Users` | `/Users` | Standard user access |
| `Viewers` | `/Viewers` | Read-only access |

## 🔄 Automatic Synchronization

**No manual management needed!** When users log in:

1. ✅ **User added to Keycloak group** → Automatically added to Homarr group on next login
2. ✅ **User removed from Keycloak group** → Automatically removed from Homarr group on next login
3. ✅ **User changes groups** → Changes reflected in Homarr on next login

## 📝 Group Naming

**Important**: The group names must match **exactly** between Keycloak and Homarr:

- ❌ Keycloak: `/Administrators` → Homarr: `Admin` (Won't sync)
- ✅ Keycloak: `/Administrators` → Homarr: `Administrators` (Will sync)

### Keycloak Groups Mapper Configuration

**CRITICAL**: The Keycloak groups mapper must have `full.path=false` to send group names without the leading slash:

```
Mapper: group-membership
Type: oidc-group-membership-mapper
Full Path: false ✅ (MUST be false)
Claim Name: groups
```

**Why?**
- Keycloak group path: `/Administrators`
- With `full.path=true`: Token sends `/Administrators` ❌ (won't match Homarr group `Administrators`)
- With `full.path=false`: Token sends `Administrators` ✅ (matches Homarr group `Administrators`)

**Current Configuration**: ✅ Already set to `false`

## 🔧 Adding New Groups

If you add a new group in Keycloak, you need to create it in Homarr too:

### Option 1: Via Homarr UI (Recommended)
1. Login as admin
2. Go to **Settings** → **Users** → **Groups**
3. Click **Create Group**
4. Enter the **exact same name** as in Keycloak (without leading slash)
5. Save

### Option 2: Auto-Sync from Keycloak (Recommended for bulk)
Run the sync script to automatically fetch all groups from Keycloak and create them in Homarr:

\`\`\`bash
cd apps/dashboard
./.devcontainer/sync-groups-from-keycloak.sh
\`\`\`

This script will:
- ✅ Fetch all groups from Keycloak
- ✅ Create missing groups in Homarr
- ✅ Skip groups that already exist
- ✅ Show a summary of changes

### Option 3: Manual Script
For specific groups only:

\`\`\`bash
cd apps/dashboard
docker cp .devcontainer/create-groups.cjs dashboard-homarr:/app/create-groups.cjs
docker exec dashboard-homarr node /app/create-groups.cjs
\`\`\`

## 🎯 Admin Access

Admin access is controlled by the `AUTH_OIDC_ADMIN_ROLE` environment variable:

\`\`\`env
AUTH_OIDC_ADMIN_ROLE=/Administrators
\`\`\`

Users in the `/Administrators` Keycloak group will:
1. Be automatically added to the `Administrators` Homarr group
2. Receive full admin permissions in Homarr

## 📊 Current Groups in Homarr

To see all groups:

\`\`\`bash
docker exec dashboard-homarr node -e "const Database = require('better-sqlite3'); const db = new Database('/appdata/db/db.sqlite'); const groups = db.prepare('SELECT name FROM \"group\" ORDER BY position').all(); console.log(groups.map(g => g.name).join('\\n')); db.close();"
\`\`\`

## 🔍 Troubleshooting

### User not in correct group after login

1. **Check Keycloak token includes groups**:
   - Login to Homarr
   - Open browser DevTools → Network
   - Find request to `/api/auth/session`
   - Check response includes `groups` array

2. **Verify group exists in Homarr**:
   \`\`\`bash
   docker exec dashboard-homarr node -e "const Database = require('better-sqlite3'); const db = new Database('/appdata/db/db.sqlite'); const groups = db.prepare('SELECT name FROM \"group\"').all(); console.log(groups.map(g => g.name).join('\\n')); db.close();"
   \`\`\`

3. **Check group names match exactly**:
   - Keycloak group: `/Users` → Token: `Users` → Homarr: `Users` ✅
   - Case-sensitive!

4. **Force re-sync**:
   - Logout from Homarr
   - Login again
   - Group membership will be updated

### "Some members are from external providers" message

This is **normal and expected**! It means:
- ✅ Users are managed by Keycloak (external provider)
- ✅ Group membership is synchronized automatically
- ℹ️  You cannot manually add/remove users in Homarr UI
- ℹ️  Manage users in Keycloak instead

**This is the correct behavior for SSO integration!**

## 🎓 Best Practices

1. **Create groups in Keycloak first**
   - Define your organizational structure
   - Assign users to groups

2. **Mirror groups in Homarr**
   - Create matching groups (exact names)
   - Let synchronization handle membership

3. **Use Keycloak for user management**
   - Add/remove users in Keycloak
   - Changes sync automatically on next login

4. **Don't manually manage in Homarr**
   - Homarr UI will show "external provider" warning
   - Manual changes will be overwritten on next login

## 📚 Related Documentation

- **Keycloak Setup**: `KEYCLOAK_SETUP.md`
- **Main README**: `README.md`
- **Docker Build**: `DOCKER_BUILD.md`

## 🔗 Source Code Reference

Group synchronization logic:
- `/packages/auth/events.ts` → `synchronizeGroupsWithExternalForUserAsync()`
- Lines 103-176

---

**Status**: ✅ **Fully Configured**  
**Groups**: Administrators, Users, Viewers  
**Sync**: Automatic on login
