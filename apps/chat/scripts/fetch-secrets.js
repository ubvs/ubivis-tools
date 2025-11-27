#!/usr/bin/env node

/**
 * Fetch ALL secrets from Infisical using the Node.js SDK
 * This script outputs secrets in KEY=VALUE format for bash consumption
 */

import { InfisicalSDK } from '@infisical/sdk';

// Configuration from environment variables
const config = {
  siteUrl: process.env.INFISICAL_SITE_URL || 'http://localhost:8081',
  clientId: process.env.INFISICAL_CLIENT_ID,
  clientSecret: process.env.INFISICAL_CLIENT_SECRET,
  projectId: process.env.INFISICAL_PROJECT_ID,
  environment: process.env.INFISICAL_ENVIRONMENT || 'dev'
};

// Required secrets - app won't start without these
const REQUIRED_SECRETS = [
  'KEYCLOAK_CLIENT_SECRET',
  'ADMIN_PASS',
  'ADMIN_EMAIL'
];

// Secrets to exclude (cause crashes or conflicts)
const EXCLUDE_SECRETS = [
  'ROCKETCHAT_LICENSE'  // Causes InvalidLicenseError crash
];

async function fetchSecrets() {
  try {
    if (!config.clientId || !config.clientSecret || !config.projectId) {
      console.error('ERROR: Missing required environment variables');
      console.error('Required: INFISICAL_CLIENT_ID, INFISICAL_CLIENT_SECRET, INFISICAL_PROJECT_ID');
      process.exit(1);
    }

    const infisical = new InfisicalSDK({
      siteUrl: config.siteUrl,
    });

    await infisical.auth().universalAuth.login({
      clientId: config.clientId,
      clientSecret: config.clientSecret,
    });

    const response = await infisical.secrets().listSecrets({
      environment: config.environment,
      projectId: config.projectId,
      viewSecretValue: true,
    });

    const secrets = response.secrets || [];
    const foundSecrets = {};

    // Fetch ALL secrets from Infisical (except excluded ones)
    for (const secret of secrets) {
      if (EXCLUDE_SECRETS.includes(secret.secretKey)) {
        continue; // Skip excluded secrets
      }
      foundSecrets[secret.secretKey] = secret.secretValue;
    }

    // Check required secrets
    const missingSecrets = REQUIRED_SECRETS.filter(key => !foundSecrets[key]);
    
    if (missingSecrets.length > 0) {
      console.error('ERROR: Missing required secrets in Infisical:');
      missingSecrets.forEach(secret => console.error(`  - ${secret}`));
      process.exit(1);
    }

    console.log('SUCCESS: All secrets fetched');
    for (const [key, value] of Object.entries(foundSecrets)) {
      const escapedValue = value.replace(/'/g, "'\"'\"'");
      console.log(`${key}='${escapedValue}'`);
    }

  } catch (error) {
    console.error('ERROR: Failed to fetch secrets from Infisical');
    console.error(`Details: ${error.message}`);
    process.exit(1);
  }
}

fetchSecrets();
