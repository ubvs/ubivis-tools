# Homarr Local Update System

This document describes the local update system that allows developers to safely update Homarr while preserving customizations using git workflow.

## 🔄 Overview

The local update system provides:
- **Version checking** against the upstream Homarr repository
- **Git-based updates** - uses git branches for safe updates
- **Selective updates** - only essential files are updated
- **Customization preservation** - your configurations remain intact
- **Review workflow** - allows inspection before merging changes
- **CI/CD integration** - push to trigger automated deployment

## 🎯 What Gets Updated

### ✅ Essential Updates (Applied)
- **Security fixes** - Critical security patches
- **Bug fixes** - Core functionality improvements
- **Core components** - React components and utilities
- **API endpoints** - Backend functionality
- **Dependencies** - Package version updates

### ❌ Preserved (Never Updated)
- **Configuration files** - `.env`, `docker-compose.yml`
- **Custom scripts** - All files in `/scripts`
- **Documentation** - Custom docs in `/docs`
- **Docker configuration** - Dockerfile, nginx.conf
- **Nx configuration** - project.json, workspace settings
- **Infisical integration** - Secrets management setup

## 🚀 Usage

### Local Development Workflow (Recommended)

1. **Check for Updates**
   ```bash
   nx run dashboard:check-updates
   ```

2. **Review Available Updates**
   - See version differences
   - Review security fixes and bug fixes
   - Understand what will be updated

3. **Apply Updates**
   ```bash
   nx run dashboard:apply-updates
   ```

4. **Review Changes**
   ```bash
   # Review the changes made
   git diff main..homarr-update-[timestamp]
   
   # Check what files were modified
   git show --name-only
   ```

5. **Merge and Deploy**
   ```bash
   # Switch to main branch
   git checkout main
   
   # Merge the update branch
   git merge homarr-update-[timestamp]
   
   # Push to trigger CI/CD
   git push origin main
   ```

6. **Fix Update Notification (Important!)**
   ```bash
   # After deployment, fix the update notification in the UI
   nx run dashboard:fix-update-notification
   
   # Or run the script directly
   bash scripts/update-container-version.sh
   ```
   
   **Why is this needed?** The version information gets compiled into JavaScript files during the Docker build process. Even though we update the source code, the running container still has the old version compiled in. This script updates the version in the running container to match the source code, which removes the update notification from the UI.

### Direct Script Usage

```bash
# Check for updates
node scripts/update-homarr.js check

# Apply updates
node scripts/update-homarr.js update
```

## 🔧 Technical Details

### Update Process

1. **Setup Upstream Remote** - Configure git remote for Homarr upstream
2. **Version Comparison** - Compare current vs latest upstream version
3. **Change Analysis** - Categorize commits (security, bugfix, feature)
4. **Branch Creation** - Create feature branch for updates
5. **Selective Update** - Apply only essential files using git
6. **Version Update** - Update package.json version
7. **Commit Changes** - Commit updates with detailed message

### File Structure

```
scripts/
├── update-homarr.js           # Local update script
└── ...

.git/
├── remotes/upstream           # Upstream Homarr repository
└── ...
```

### Configuration

The update system is configured in `scripts/update-homarr.js`:

```javascript
const CONFIG = {
  UPSTREAM_REPO: 'https://github.com/homarr-labs/homarr.git',
  
  // Files that will be updated
  ESSENTIAL_FILES: [
    'apps/nextjs/src/components/**/*.tsx',
    'apps/nextjs/src/pages/**/*.tsx',
    // ... more patterns
  ],
  
  // Files that will never be updated
  PRESERVE_FILES: [
    '.devcontainer/**/*',
    'scripts/**/*',
    'docker/**/*',
    // ... more patterns
  ]
};
```

## 🔒 Security

### Admin-Only Access
- Updates can only be triggered by users with admin privileges
- API endpoint validates user permissions
- UI component only shows for admin users

### Backup System
- Automatic backup creation before updates
- Backups stored in `/app/backups/`
- Includes timestamp for easy identification

### Safe Update Strategy
- Only essential security and bug fixes are applied
- Feature updates are skipped to avoid breaking customizations
- Rollback capability through backup system

## 📋 API Reference

### GET `/api/admin/update`
Check for available updates.

**Response:**
```json
{
  "success": true,
  "data": {
    "updateAvailable": true,
    "currentVersion": "1.43.2",
    "latestVersion": "1.43.3",
    "changes": {
      "security": ["fix: XSS vulnerability in dashboard"],
      "bugfixes": ["fix: widget loading issue"],
      "features": ["feat: new dashboard layout"]
    }
  }
}
```

### POST `/api/admin/update`
Apply available updates.

**Response:**
```json
{
  "success": true,
  "data": {
    "previousVersion": "1.43.2",
    "newVersion": "1.43.3",
    "backupPath": "/app/backups/update-1234567890"
  },
  "message": "Update completed successfully"
}
```

## 🛠️ Troubleshooting

### Update Fails
1. Check container logs: `nx run dashboard:logs`
2. Verify internet connectivity for GitHub access
3. Ensure sufficient disk space for backups
4. Check file permissions in `/app/backups/`

### Rollback Process
1. Stop the container: `nx run dashboard:stop`
2. Restore from backup manually
3. Restart the container: `nx run dashboard:start`

### Network Issues
- Ensure container can access `github.com`
- Check firewall settings
- Verify DNS resolution

## 📊 Monitoring

### Update Logs
All update activities are logged to:
- Console output (visible in container logs)
- `/app/backups/update.log` (persistent log file)

### Health Checks
After updates, verify system health:
```bash
nx run dashboard:health-check
```

## 🔄 Nx Integration

The update system integrates with Nx for easy management:

```bash
# Available targets
nx run dashboard:check-updates    # Check for updates
nx run dashboard:apply-updates    # Apply updates
nx run dashboard:health-check     # Verify system health
```

## ⚠️ Important Notes

1. **Customizations**: Any custom code in preserved directories will remain unchanged
2. **Dependencies**: Package updates may require container rebuild
3. **Database**: Database migrations are handled by the existing Homarr startup process
4. **Downtime**: Updates require brief service interruption
5. **Testing**: Test updates in development environment first

---

**Last Updated**: November 2025  
**Version**: 1.0.0
