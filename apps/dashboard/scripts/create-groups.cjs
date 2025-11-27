#!/usr/bin/env node
// Create Homarr groups to match Keycloak groups

const Database = require('better-sqlite3');
const { randomUUID } = require('crypto');

// Groups that exist in Keycloak
const GROUPS = [
    { name: 'Administrators', position: 1 },
    { name: 'Users', position: 2 },
    { name: 'Viewers', position: 3 }
];

console.log('🔧 Setting up Homarr groups to match Keycloak...');

try {
    // Open database
    const db = new Database('/appdata/db/db.sqlite', { verbose: console.log });
    
    // Create groups
    for (const group of GROUPS) {
        console.log(`Creating group: ${group.name}`);
        
        const stmt = db.prepare(`
            INSERT OR IGNORE INTO "group" (id, name, position)
            VALUES (?, ?, ?)
        `);
        
        const result = stmt.run(
            randomUUID(),
            group.name,
            group.position
        );
        
        if (result.changes > 0) {
            console.log(`✅ Group '${group.name}' created successfully`);
        } else {
            console.log(`ℹ️  Group '${group.name}' already exists`);
        }
    }
    
    // Show current groups
    console.log('\n📊 Current groups in Homarr:');
    const groups = db.prepare('SELECT name FROM "group" ORDER BY position').all();
    groups.forEach(group => {
        console.log(`  - ${group.name}`);
    });
    
    db.close();
    
    console.log('\n🎉 Group setup complete!');
    console.log('🔄 Next time users log in via Keycloak, they will be automatically added to their groups!');
    console.log('💡 Users in "/Administrators" will get admin access');
    
} catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
}
