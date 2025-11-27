#!/usr/bin/env node

/**
 * Fetch secrets from Infisical using the Node.js SDK
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

// Required secrets for Homarr dashboard
const REQUIRED_SECRETS = [
  'AUTH_SECRET',
  'SECRET_ENCRYPTION_KEY',
  'AUTH_OIDC_CLIENT_SECRET',
  'AUTH_OIDC_CLIENT_ID',
  'AUTH_OIDC_ISSUER'
];

async function fetchSecrets() {
  try {
    // Validate required config
    if (!config.clientId || !config.clientSecret || !config.projectId) {
      console.error('ERROR: Missing required environment variables');
      console.error('Required: INFISICAL_CLIENT_ID, INFISICAL_CLIENT_SECRET, INFISICAL_PROJECT_ID');
      process.exit(1);
    }

    // Initialize Infisical SDK
    const infisical = new InfisicalSDK({
      siteUrl: config.siteUrl,
    });

    // Authenticate with universal auth
    await infisical.auth().universalAuth.login({
      clientId: config.clientId,
      clientSecret: config.clientSecret,
    });

    // Fetch all secrets
    const response = await infisical.secrets().listSecrets({
      environment: config.environment,
      projectId: config.projectId,
      viewSecretValue: true,
    });

    const secrets = response.secrets || [];
    const foundSecrets = {};

    // Extract the secrets we need
    for (const secret of secrets) {
      if (REQUIRED_SECRETS.includes(secret.secretKey)) {
        foundSecrets[secret.secretKey] = secret.secretValue;
      }
    }

    // Check if all required secrets are found
    const missingSecrets = REQUIRED_SECRETS.filter(key => !foundSecrets[key]);
    
    if (missingSecrets.length > 0) {
      console.error('ERROR: Missing required secrets in Infisical:');
      missingSecrets.forEach(secret => console.error(`  - ${secret}`));
      process.exit(1);
    }

    // Output secrets in KEY=VALUE format for bash
    console.log('SUCCESS: All secrets fetched');
    for (const [key, value] of Object.entries(foundSecrets)) {
      // Escape any special characters in the value for bash
      const escapedValue = value.replace(/'/g, "'\"'\"'");
      console.log(`${key}='${escapedValue}'`);
    }

  } catch (error) {
    console.error('ERROR: Failed to fetch secrets from Infisical');
    console.error(`Details: ${error.message}`);
    process.exit(1);
  }
}

// Run the script
fetchSecrets();
