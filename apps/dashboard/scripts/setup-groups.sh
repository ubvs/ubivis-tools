#!/bin/bash
# Setup Homarr groups to match Keycloak groups

echo "🔧 Setting up Homarr groups to match Keycloak..."

# Groups that exist in Keycloak
GROUPS=(
    "Administrators"
    "Users"
    "Viewers"
)

echo "📝 Groups to create: ${GROUPS[*]}"

# Create groups using Docker exec (running SQL commands)
for group in "${GROUPS[@]}"; do
    echo "Creating group: $group"
    
    # Insert group into database
    docker exec dashboard-homarr sqlite3 /appdata/db/db.sqlite "
        INSERT OR IGNORE INTO groups (id, name, description, icon, color, isEveryoneGroup, isDefaultGroup, isInitialAdminGroup, createdBy, createdAt, updatedBy, updatedAt)
        VALUES (
            lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-' || hex(randomblob(2)) || '-' || hex(randomblob(2)) || '-' || hex(randomblob(6))),
            '$group',
            'Group synchronized from Keycloak',
            'shield',
            '#3b82f6',
            0,
            0,
            0,
            'system',
            datetime('now'),
            'system',
            datetime('now')
        );
    "
    
    if [ $? -eq 0 ]; then
        echo "✅ Group '$group' created successfully"
    else
        echo "❌ Failed to create group '$group'"
    fi
done

echo ""
echo "🎉 Group setup complete!"
echo ""
echo "📊 Current groups in Homarr:"
docker exec dashboard-homarr sqlite3 /appdata/db/db.sqlite "SELECT name, description FROM groups ORDER BY name;"
echo ""
echo "🔄 Next time users log in via Keycloak, they will be automatically added to their groups!"
echo "💡 Users in '/Administrators' will get admin access"
