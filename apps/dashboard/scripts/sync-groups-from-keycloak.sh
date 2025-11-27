#!/bin/bash
# Sync groups from Keycloak to Homarr
# This script fetches all groups from Keycloak and creates matching groups in Homarr

set -e

echo "🔄 Syncing groups from Keycloak to Homarr..."
echo ""

# Configuration
KEYCLOAK_CONTAINER="ssom-keycloak"
HOMARR_CONTAINER="dashboard-homarr"
KEYCLOAK_REALM="ubivis"
KEYCLOAK_ADMIN="admin"
KEYCLOAK_PASSWORD="admin"

# Login to Keycloak
echo "🔐 Logging into Keycloak..."
docker exec $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh config credentials \
    --server http://localhost:8080 \
    --realm master \
    --user $KEYCLOAK_ADMIN \
    --password $KEYCLOAK_PASSWORD > /dev/null 2>&1

# Get all groups from Keycloak
echo "📋 Fetching groups from Keycloak realm: $KEYCLOAK_REALM"
GROUPS_JSON=$(docker exec $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh get groups -r $KEYCLOAK_REALM --fields name 2>/dev/null)

# Parse group names (extract just the names)
GROUP_NAMES=$(echo "$GROUPS_JSON" | grep '"name"' | sed 's/.*"name" : "\(.*\)".*/\1/' | sort)

if [ -z "$GROUP_NAMES" ]; then
    echo "❌ No groups found in Keycloak"
    exit 1
fi

echo "✅ Found $(echo "$GROUP_NAMES" | wc -l | tr -d ' ') groups in Keycloak:"
echo "$GROUP_NAMES" | sed 's/^/  - /'
echo ""

# Create Node.js script to add groups to Homarr
cat > /tmp/sync-groups.cjs << 'EOFSCRIPT'
const Database = require('better-sqlite3');
const { randomUUID } = require('crypto');

const groupNames = process.argv.slice(2);

if (groupNames.length === 0) {
    console.log('No groups provided');
    process.exit(0);
}

try {
    const db = new Database('/appdata/db/db.sqlite');
    
    // Get existing groups
    const existingGroups = db.prepare('SELECT name FROM "group"').all();
    const existingGroupNames = existingGroups.map(g => g.name);
    
    let created = 0;
    let skipped = 0;
    
    // Get max position
    const maxPosResult = db.prepare('SELECT MAX(position) as maxPos FROM "group"').get();
    let position = (maxPosResult.maxPos || 0) + 1;
    
    for (const groupName of groupNames) {
        if (existingGroupNames.includes(groupName)) {
            console.log(`  ⏭️  ${groupName} (already exists)`);
            skipped++;
        } else {
            const stmt = db.prepare('INSERT INTO "group" (id, name, position) VALUES (?, ?, ?)');
            stmt.run(randomUUID(), groupName, position);
            console.log(`  ✅ ${groupName} (created)`);
            created++;
            position++;
        }
    }
    
    db.close();
    
    console.log('');
    console.log(`📊 Summary: ${created} created, ${skipped} skipped`);
    
} catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
}
EOFSCRIPT

# Copy script to container and run it
echo "📝 Creating groups in Homarr..."
docker cp /tmp/sync-groups.cjs $HOMARR_CONTAINER:/tmp/sync-groups.cjs

# Convert group names to command line arguments
GROUP_ARGS=$(echo "$GROUP_NAMES" | tr '\n' ' ')

# Run the sync script
docker exec $HOMARR_CONTAINER node /tmp/sync-groups.cjs $GROUP_ARGS

# Clean up
rm /tmp/sync-groups.cjs
docker exec $HOMARR_CONTAINER rm /tmp/sync-groups.cjs

echo ""
echo "🎉 Group synchronization complete!"
echo ""
echo "📊 Current groups in Homarr:"
docker exec $HOMARR_CONTAINER node -e "const Database = require('better-sqlite3'); const db = new Database('/appdata/db/db.sqlite'); const groups = db.prepare('SELECT name FROM \"group\" ORDER BY position').all(); groups.forEach(g => console.log('  - ' + g.name)); db.close();"

echo ""
echo "💡 Next steps:"
echo "   1. Users need to logout and login again for group membership to sync"
echo "   2. Assign users to groups in Keycloak"
echo "   3. Group membership will automatically sync on next login"
echo ""
echo "⚠️  Important: Group names must match exactly between Keycloak and Homarr"
echo "   Keycloak group: 'Tech' → Homarr group: 'Tech' ✅"
echo "   Keycloak group: '/Tech' → Homarr group: 'Tech' ❌ (use full.path=false)"
