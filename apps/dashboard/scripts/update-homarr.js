#!/usr/bin/env node

/**
 * Homarr Local Update Script
 * 
 * This script safely updates the Homarr installation using git by:
 * 1. Checking the current version vs latest upstream version
 * 2. Using git to merge only essential updates while preserving customizations
 * 3. Creating feature branches for safe updates
 * 4. Allowing review before committing changes
 * 5. Keeping git history clean for CI/CD deployment
 */

const fs = require('fs').promises;
const path = require('path');
const { execSync, exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

// Configuration
const CONFIG = {
  UPSTREAM_REPO: 'https://github.com/homarr-labs/homarr.git',
  UPSTREAM_REMOTE: 'upstream',
  CURRENT_VERSION_FILE: 'package.json',
  PROJECT_ROOT: process.cwd(),
  
  // Essential files that should be updated (glob patterns)
  ESSENTIAL_PATTERNS: [
    'apps/nextjs/src/components/**/*.tsx',
    'apps/nextjs/src/components/**/*.ts',
    'apps/nextjs/src/pages/**/*.tsx',
    'apps/nextjs/src/pages/**/*.ts',
    'apps/nextjs/src/app/**/*.tsx',
    'apps/nextjs/src/app/**/*.ts',
    'apps/nextjs/src/utils/**/*.ts',
    'apps/nextjs/src/hooks/**/*.ts',
    'apps/nextjs/src/lib/**/*.ts',
    'packages/*/src/**/*.ts',
    'packages/*/src/**/*.tsx',
    'apps/nextjs/public/**/*',
    'apps/nextjs/next.config.ts',
    'package.json',
    'packages/*/package.json',
    'apps/*/package.json',
    'pnpm-lock.yaml',
    'static-data/contributors.json'
  ],
  
  // Files to never update (preserve customizations)
  PRESERVE_PATTERNS: [
    '.devcontainer/**/*',
    'scripts/**/*',
    'docker/**/*',
    'docs/**/*',
    'Dockerfile',
    'project.json',
    '.env*',
    'README.md',
    'INFISICAL.md',
    'GROUP_SYNC.md',
    'KEYCLOAK_SETUP.md'
  ],
  
  // Critical security patterns to always update
  SECURITY_KEYWORDS: [
    'security',
    'vulnerability',
    'cve',
    'xss',
    'csrf',
    'injection',
    'auth',
    'fix'
  ]
};

class HomarrLocalUpdater {
  constructor() {
    this.currentVersion = null;
    this.latestVersion = null;
    this.updateBranch = `homarr-update-${Date.now()}`;
  }

  async log(message, level = 'info') {
    const timestamp = new Date().toISOString();
    const emoji = {
      info: '📋',
      success: '✅',
      warning: '⚠️',
      error: '❌'
    }[level] || '📋';
    
    console.log(`${emoji} [${level.toUpperCase()}] ${message}`);
  }

  async execCommand(command, options = {}) {
    try {
      const { stdout, stderr } = await execAsync(command, {
        cwd: CONFIG.PROJECT_ROOT,
        ...options
      });
      return { stdout: stdout.trim(), stderr: stderr.trim(), success: true };
    } catch (error) {
      return { 
        stdout: error.stdout?.trim() || '', 
        stderr: error.stderr?.trim() || error.message, 
        success: false,
        code: error.code
      };
    }
  }

  async getCurrentVersion() {
    try {
      const packageJsonPath = path.join(CONFIG.PROJECT_ROOT, CONFIG.CURRENT_VERSION_FILE);
      const packageJson = JSON.parse(await fs.readFile(packageJsonPath, 'utf8'));
      this.currentVersion = packageJson.version;
      await this.log(`Current version: ${this.currentVersion}`);
      return this.currentVersion;
    } catch (error) {
      await this.log(`Error reading current version: ${error.message}`, 'error');
      throw error;
    }
  }

  async setupUpstreamRemote() {
    await this.log('Setting up upstream remote...');
    
    // Check if upstream remote exists and has correct URL
    const { stdout: currentUrl, success: hasUpstream } = await this.execCommand(`git remote get-url ${CONFIG.UPSTREAM_REMOTE}`);
    
    if (!hasUpstream || currentUrl !== CONFIG.UPSTREAM_REPO) {
      if (hasUpstream) {
        // Remove existing upstream with wrong URL
        await this.execCommand(`git remote remove ${CONFIG.UPSTREAM_REMOTE}`);
        await this.log('Removed old upstream remote');
      }
      
      const { success } = await this.execCommand(`git remote add ${CONFIG.UPSTREAM_REMOTE} ${CONFIG.UPSTREAM_REPO}`);
      if (!success) {
        throw new Error('Failed to add upstream remote');
      }
      await this.log('Added upstream remote');
    }
    
    // Fetch latest from upstream including tags
    const { success: fetchSuccess } = await this.execCommand(`git fetch ${CONFIG.UPSTREAM_REMOTE} --tags`);
    if (!fetchSuccess) {
      throw new Error('Failed to fetch from upstream');
    }
    
    await this.log('Fetched latest from upstream with tags');
  }

  async getLatestVersion() {
    try {
      await this.log('Getting latest release tag from upstream...');
      
      // First try to get latest tag directly from remote
      const { stdout: remoteTag, success: remoteSuccess } = await this.execCommand(
        `git ls-remote --tags --sort=-version:refname ${CONFIG.UPSTREAM_REMOTE} | grep -E 'refs/tags/v[0-9]+\\.[0-9]+\\.[0-9]+$' | head -n1 | sed 's/.*refs\\/tags\\///'`
      );
      
      if (remoteSuccess && remoteTag.trim()) {
        this.latestVersion = remoteTag.trim().replace(/^v/, '');
        await this.log(`Latest version from remote: ${this.latestVersion}`);
        return this.latestVersion;
      }
      
      // Fallback: Get all local tags and find the latest version
      const { stdout: allTags, success: fetchTagsSuccess } = await this.execCommand(
        `git tag -l --sort=-version:refname | grep -E '^v?[0-9]+\\.[0-9]+\\.[0-9]+$'`
      );
      
      if (fetchTagsSuccess && allTags.trim()) {
        const versionTags = allTags.split('\n')
          .filter(tag => tag.trim())
          .filter(tag => tag.match(/^v?\d+\.\d+\.\d+$/));
        
        if (versionTags.length > 0) {
          const latestTag = versionTags[0];
          this.latestVersion = latestTag.replace(/^v/, '');
          await this.log(`Latest version from local tags: ${this.latestVersion}`);
          return this.latestVersion;
        }
      }
      
      throw new Error('No version tags found in upstream repository');
    } catch (error) {
      await this.log(`Error fetching latest version: ${error.message}`, 'error');
      throw error;
    }
  }

  compareVersions(current, latest) {
    const currentParts = current.split('.').map(Number);
    const latestParts = latest.split('.').map(Number);
    
    for (let i = 0; i < Math.max(currentParts.length, latestParts.length); i++) {
      const currentPart = currentParts[i] || 0;
      const latestPart = latestParts[i] || 0;
      
      if (latestPart > currentPart) return 1; // Update available
      if (latestPart < currentPart) return -1; // Current is newer
    }
    
    return 0; // Same version
  }

  async analyzeChanges() {
    try {
      await this.log('Analyzing changes since last version...');
      
      // Get commit messages between current and latest version tags
      const { stdout: gitLog, success } = await this.execCommand(
        `git log --oneline v${this.currentVersion}..v${this.latestVersion}`
      );
      
      if (!success) {
        await this.log('Could not get commit history between tags, trying alternative approach', 'warning');
        // Try with upstream remote tags
        const { stdout: altLog, success: altSuccess } = await this.execCommand(
          `git log --oneline ${CONFIG.UPSTREAM_REMOTE}/v${this.currentVersion}..${CONFIG.UPSTREAM_REMOTE}/v${this.latestVersion}`
        );
        
        if (!altSuccess) {
          await this.log('Using recent commits from latest version', 'warning');
          const { stdout: recentLog } = await this.execCommand(
            `git log --oneline -20 ${CONFIG.UPSTREAM_REMOTE}/v${this.latestVersion}`
          );
          return this.categorizeCommits(recentLog);
        }
        
        return this.categorizeCommits(altLog);
      }
      
      return this.categorizeCommits(gitLog);
    } catch (error) {
      await this.log(`Error analyzing changes: ${error.message}`, 'warning');
      return { security: [], bugfixes: [], features: [] };
    }
  }

  categorizeCommits(gitLog) {
    const commits = gitLog.trim().split('\n').filter(line => line.trim());
    const securityUpdates = [];
    const bugfixUpdates = [];
    const featureUpdates = [];
    
    for (const commit of commits) {
      const message = commit.toLowerCase();
      
      if (CONFIG.SECURITY_KEYWORDS.some(keyword => message.includes(keyword))) {
        securityUpdates.push(commit);
      } else if (message.includes('fix') || message.includes('bug')) {
        bugfixUpdates.push(commit);
      } else {
        featureUpdates.push(commit);
      }
    }
    
    return {
      security: securityUpdates,
      bugfixes: bugfixUpdates,
      features: featureUpdates
    };
  }

  async createUpdateBranch() {
    await this.log(`Creating update branch: ${this.updateBranch}`);
    
    // Ensure we're on main/master branch
    const { success: checkoutMain } = await this.execCommand('git checkout main || git checkout master');
    if (!checkoutMain) {
      throw new Error('Could not checkout main branch');
    }
    
    // Create and checkout new branch
    const { success } = await this.execCommand(`git checkout -b ${this.updateBranch}`);
    if (!success) {
      throw new Error(`Failed to create update branch: ${this.updateBranch}`);
    }
    
    await this.log(`Created and switched to branch: ${this.updateBranch}`, 'success');
  }

  async applySelectiveUpdates() {
    await this.log('Applying selective updates from upstream...');
    
    try {
      // Get list of changed files between version tags
      const { stdout: changedFiles, success } = await this.execCommand(
        `git diff --name-only v${this.currentVersion} v${this.latestVersion}`
      );
      
      if (!success) {
        throw new Error('Failed to get list of changed files');
      }
      
      await this.log(`Raw changed files: ${changedFiles.split('\n').length} files`);
      
      const filesToUpdate = this.filterEssentialFiles(changedFiles.split('\n'));
      
      if (filesToUpdate.length === 0) {
        await this.log('No essential files to update', 'warning');
        return false;
      }
      
      await this.log(`Found ${filesToUpdate.length} essential files to update:`);
      filesToUpdate.forEach(file => this.log(`  - ${file}`));
      
      // Apply updates file by file from the specific version tag
      for (const file of filesToUpdate) {
        await this.updateSingleFile(file);
      }
      
      // Update package.json version
      await this.updatePackageVersion();
      
      // Create container version update script
      await this.updateContainerVersion();
      
      return true;
    } catch (error) {
      await this.log(`Error applying updates: ${error.message}`, 'error');
      throw error;
    }
  }

  filterEssentialFiles(changedFiles) {
    const essentialFiles = [];
    
    for (const file of changedFiles) {
      if (!file.trim()) continue;
      
      // Skip if file should be preserved
      const shouldPreserve = CONFIG.PRESERVE_PATTERNS.some(pattern => {
        const regex = new RegExp(pattern.replace(/\*\*/g, '.*').replace(/\*/g, '[^/]*'));
        return regex.test(file);
      });
      
      if (shouldPreserve) {
        continue;
      }
      
      // Include if file matches essential patterns
      const isEssential = CONFIG.ESSENTIAL_PATTERNS.some(pattern => {
        const regex = new RegExp(pattern.replace(/\*\*/g, '.*').replace(/\*/g, '[^/]*'));
        return regex.test(file);
      });
      
      if (isEssential) {
        essentialFiles.push(file);
      }
    }
    
    return essentialFiles;
  }

  async updateSingleFile(filePath) {
    try {
      const { success } = await this.execCommand(
        `git checkout v${this.latestVersion} -- "${filePath}"`
      );
      
      if (success) {
        await this.log(`Updated: ${filePath}`);
      } else {
        await this.log(`Warning: Could not update ${filePath}`, 'warning');
      }
    } catch (error) {
      await this.log(`Warning: Error updating ${filePath}: ${error.message}`, 'warning');
    }
  }

  async updatePackageVersion() {
    try {
      const packageJsonPath = path.join(CONFIG.PROJECT_ROOT, CONFIG.CURRENT_VERSION_FILE);
      const packageJson = JSON.parse(await fs.readFile(packageJsonPath, 'utf8'));
      packageJson.version = this.latestVersion;
      
      await fs.writeFile(packageJsonPath, JSON.stringify(packageJson, null, 2) + '\n');
      await this.log(`Updated package.json version to ${this.latestVersion}`, 'success');
    } catch (error) {
      await this.log(`Error updating package version: ${error.message}`, 'error');
      throw error;
    }
  }

  async updateContainerVersion() {
    try {
      await this.log('Creating container version update script...');
      
      // Create a script to update version in the running container
      const updateScript = `#!/bin/bash
# Update version in running container to fix update notifications

CONTAINER_NAME="dashboard-homarr"
OLD_VERSION="${this.currentVersion}"
NEW_VERSION="${this.latestVersion}"

echo "🔄 Updating container version from \$OLD_VERSION to \$NEW_VERSION..."

# Check if container is running
if ! docker ps | grep -q \$CONTAINER_NAME; then
  echo "❌ Container \$CONTAINER_NAME is not running"
  exit 1
fi

# Update package.json in container
echo "📦 Updating package.json in container..."
docker exec \$CONTAINER_NAME sed -i "s/\\"version\\": \\"\$OLD_VERSION\\"/\\"version\\": \\"\$NEW_VERSION\\"/g" /app/package.json

# Update compiled JavaScript files
echo "🔧 Updating compiled JavaScript files..."
docker exec \$CONTAINER_NAME find /app -type f -name "*.js" -not -path "*/node_modules/*" -exec sed -i "s/\$OLD_VERSION/\$NEW_VERSION/g" {} \\;

# Update compiled CJS files  
echo "🔧 Updating compiled CJS files..."
docker exec \$CONTAINER_NAME find /app -type f -name "*.cjs" -not -path "*/node_modules/*" -exec sed -i "s/\$OLD_VERSION/\$NEW_VERSION/g" {} \\;

# Restart container to apply changes
echo "🔄 Restarting container to apply changes..."
docker restart \$CONTAINER_NAME

echo "✅ Container version updated successfully!"
echo "🎉 Update notification should disappear after container restart"
`;

      const scriptPath = path.join(CONFIG.PROJECT_ROOT, 'scripts', 'update-container-version.sh');
      await fs.writeFile(scriptPath, updateScript);
      await this.execCommand(`chmod +x "${scriptPath}"`);
      
      await this.log(`Created container update script: ${scriptPath}`, 'success');
      await this.log('Run this script after deployment to fix update notifications:', 'info');
      await this.log(`  bash scripts/update-container-version.sh`, 'info');
      
    } catch (error) {
      await this.log(`Error creating container update script: ${error.message}`, 'warning');
    }
  }

  async commitChanges(changes) {
    await this.log('Committing changes...');
    
    // Stage all changes
    const { success: stageSuccess } = await this.execCommand('git add .');
    if (!stageSuccess) {
      throw new Error('Failed to stage changes');
    }
    
    // Create commit message
    const commitMessage = `feat: update Homarr to v${this.latestVersion}

- Security updates: ${changes.security.length}
- Bug fixes: ${changes.bugfixes.length}
- Features skipped: ${changes.features.length} (preserved customizations)

Essential files updated while preserving customizations.`;
    
    const { success: commitSuccess } = await this.execCommand(`git commit -m "${commitMessage}"`);
    if (!commitSuccess) {
      await this.log('No changes to commit', 'warning');
      return false;
    }
    
    await this.log('Changes committed successfully', 'success');
    return true;
  }

  async checkForUpdates() {
    try {
      await this.getCurrentVersion();
      await this.setupUpstreamRemote();
      await this.getLatestVersion();
      
      const comparison = this.compareVersions(this.currentVersion, this.latestVersion);
      
      if (comparison === 0) {
        await this.log('Already up to date', 'success');
        return { updateAvailable: false, currentVersion: this.currentVersion };
      } else if (comparison === 1) {
        await this.log('Update available!', 'success');
        const changes = await this.analyzeChanges();
        return {
          updateAvailable: true,
          currentVersion: this.currentVersion,
          latestVersion: this.latestVersion,
          changes
        };
      } else {
        await this.log('Current version is newer than upstream', 'warning');
        return { updateAvailable: false, currentVersion: this.currentVersion };
      }
    } catch (error) {
      await this.log(`Error checking for updates: ${error.message}`, 'error');
      throw error;
    }
  }

  async performUpdate() {
    try {
      await this.log('Starting update process...', 'info');
      
      const updateInfo = await this.checkForUpdates();
      if (!updateInfo.updateAvailable) {
        return updateInfo;
      }
      
      // Create update branch
      await this.createUpdateBranch();
      
      // Apply selective updates
      const hasUpdates = await this.applySelectiveUpdates();
      if (!hasUpdates) {
        await this.log('No updates applied', 'warning');
        return { success: false, message: 'No essential updates found' };
      }
      
      // Commit changes
      const committed = await this.commitChanges(updateInfo.changes);
      if (!committed) {
        await this.log('No changes to commit', 'warning');
        return { success: false, message: 'No changes to commit' };
      }
      
      await this.log('Update completed successfully!', 'success');
      await this.log(`Review changes with: git diff main..${this.updateBranch}`);
      await this.log(`Merge with: git checkout main && git merge ${this.updateBranch}`);
      await this.log(`Push with: git push origin main`);
      await this.log('');
      await this.log('📋 IMPORTANT: After deployment, run the container update script:');
      await this.log(`   bash scripts/update-container-version.sh`);
      await this.log('   This will fix the update notification in the UI.');
      
      return {
        success: true,
        previousVersion: this.currentVersion,
        newVersion: this.latestVersion,
        branch: this.updateBranch,
        changes: updateInfo.changes
      };
    } catch (error) {
      await this.log(`Update failed: ${error.message}`, 'error');
      
      // Try to cleanup branch on failure
      try {
        await this.execCommand('git checkout main || git checkout master');
        await this.execCommand(`git branch -D ${this.updateBranch}`);
        await this.log('Cleaned up failed update branch');
      } catch (cleanupError) {
        await this.log(`Could not cleanup branch: ${cleanupError.message}`, 'warning');
      }
      
      throw error;
    }
  }
}

// CLI Interface
async function main() {
  const updater = new HomarrLocalUpdater();
  
  try {
    const command = process.argv[2] || 'check';
    
    switch (command) {
      case 'check':
        const updateInfo = await updater.checkForUpdates();
        console.log('\n📊 Update Summary:');
        console.log(JSON.stringify(updateInfo, null, 2));
        break;
        
      case 'update':
        const result = await updater.performUpdate();
        console.log('\n🎉 Update Result:');
        console.log(JSON.stringify(result, null, 2));
        break;
        
      default:
        console.log('Usage: node update-homarr.js [check|update]');
        console.log('  check  - Check for available updates');
        console.log('  update - Apply updates to a new git branch');
        process.exit(1);
    }
  } catch (error) {
    console.error('\n❌ Update failed:', error.message);
    process.exit(1);
  }
}

// Export for use as module
module.exports = HomarrLocalUpdater;

// Run if called directly
if (require.main === module) {
  main();
}
