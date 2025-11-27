#!/bin/bash
# Patch Infisical to enable OIDC/SAML SSO without enterprise license

set -e

echo "🔧 Applying OIDC/SAML SSO patch to Infisical..."
echo ""

# Check if we're in the right directory
if [ ! -f "backend/src/ee/services/license/license-fns.ts" ]; then
    echo "❌ Error: Must run from apps/secrets directory"
    echo "   cd apps/secrets && ./patch-oidc.sh"
    exit 1
fi

# Skip backup to avoid build errors with .original files
# Backup is in git history if needed

# Apply patch
echo "🔐 Enabling enterprise features..."

# Enable OIDC SSO
sed -i.bak 's/oidcSSO: false,/oidcSSO: true,/g' \
    backend/src/ee/services/license/license-fns.ts

# Enable SAML SSO
sed -i.bak 's/samlSSO: false,/samlSSO: true,/g' \
    backend/src/ee/services/license/license-fns.ts

# Enable LDAP (useful for future)
sed -i.bak 's/ldap: false,/ldap: true,/g' \
    backend/src/ee/services/license/license-fns.ts

# Enable Groups (useful with SSO)
sed -i.bak 's/groups: false,/groups: true,/g' \
    backend/src/ee/services/license/license-fns.ts

# Enable RBAC (useful with groups)
sed -i.bak 's/rbac: false,/rbac: true,/g' \
    backend/src/ee/services/license/license-fns.ts

# Enable Audit Logs (security best practice)
sed -i.bak 's/auditLogs: false,/auditLogs: true,/g' \
    backend/src/ee/services/license/license-fns.ts

# Clean up backup file
rm -f backend/src/ee/services/license/license-fns.ts.bak

echo "✅ Patch applied successfully!"
echo ""
echo "📊 Enabled features:"
echo "   - OIDC SSO"
echo "   - SAML SSO"
echo "   - LDAP"
echo "   - Groups"
echo "   - RBAC"
echo "   - Audit Logs"
echo ""
echo "🚀 Next steps:"
echo "   1. Build custom image: npx nx run secrets:build-local"
echo "   2. Update docker-compose to use infisical:local image"
echo "   3. Start services: npx nx run secrets:start"
echo "   4. Configure Keycloak OIDC in Infisical UI"
echo ""
echo "📖 See ENABLE_OIDC_PATCH.md for detailed instructions"
