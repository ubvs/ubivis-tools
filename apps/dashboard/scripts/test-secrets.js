#!/usr/bin/env node

/**
 * Infisical Connection Test Script
 * 
 * This script tests the connection to Infisical and attempts to fetch secrets
 * before implementing the full integration in the dashboard.
 */

const { InfisicalSDK } = require('@infisical/sdk');

// Configuration from environment variables
const config = {
  siteUrl: process.env.INFISICAL_SITE_URL || 'http://localhost:8081',
  clientId: process.env.INFISICAL_CLIENT_ID,
  clientSecret: process.env.INFISICAL_CLIENT_SECRET,
  projectId: process.env.INFISICAL_PROJECT_ID,
  projectSlug: process.env.INFISICAL_PROJECT_SLUG,
  environment: process.env.INFISICAL_ENVIRONMENT || 'Development'
};

async function testInfisicalConnection() {
  console.log('🔐 Testing Infisical Connection...\n');
  
  // Validate required environment variables
  const requiredVars = ['INFISICAL_CLIENT_ID', 'INFISICAL_CLIENT_SECRET', 'INFISICAL_PROJECT_ID'];
  const missingVars = requiredVars.filter(varName => !process.env[varName]);
  
  if (missingVars.length > 0) {
    console.error('❌ Missing required environment variables:');
    missingVars.forEach(varName => console.error(`   - ${varName}`));
    console.error('\nPlease set these in your .env file or environment.\n');
    process.exit(1);
  }

  console.log('📋 Configuration:');
  console.log(`   Site URL: ${config.siteUrl}`);
  console.log(`   Project ID: ${config.projectId}`);
  console.log(`   Project Slug: ${config.projectSlug}`);
  console.log(`   Environment: ${config.environment}`);
  console.log(`   Client ID: ${config.clientId?.substring(0, 8)}...`);
  console.log('');

  try {
    // Initialize Infisical SDK
    console.log('🔌 Initializing Infisical SDK...');
    const client = new InfisicalSDK({
      siteUrl: config.siteUrl
    });

    // Authenticate
    console.log('🔑 Authenticating with Universal Auth...');
    await client.auth().universalAuth.login({
      clientId: config.clientId,
      clientSecret: config.clientSecret
    });
    console.log('✅ Authentication successful!\n');

    // Test listing projects first
    console.log('📋 Listing available projects...');
    try {
      const projects = await client.projects().listProjects();
      console.log('   Available projects:', projects.map(p => ({ id: p.id, name: p.name })));
    } catch (error) {
      console.log('   Could not list projects:', error.message);
    }

    // Test fetching all secrets
    console.log('📦 Fetching all secrets...');
    console.log('   Request params:', {
      environment: config.environment,
      projectId: config.projectId,
      viewSecretValue: true
    });
    
    const response = await client.secrets().listSecrets({
      environment: config.environment,
      projectId: config.projectId,
      viewSecretValue: true
    });
    
    console.log('   Raw API response:', JSON.stringify(response, null, 2));

    // Extract secrets from response
    const secrets = response.secrets || response || [];
    console.log(`✅ Found ${secrets.length} secrets:\n`);
    
    // Check if secrets is an array
    if (!Array.isArray(secrets)) {
      console.log('⚠️  Secrets response is not an array:', typeof secrets);
      console.log('Raw response:', JSON.stringify(response, null, 2));
      return;
    }
    
    // Display secrets (masked values for security)
    secrets.forEach(secret => {
      const maskedValue = secret.secretValue ? 
        secret.secretValue.substring(0, 4) + '*'.repeat(Math.max(0, secret.secretValue.length - 4)) : 
        '<empty>';
      console.log(`   🔐 ${secret.secretKey}: ${maskedValue}`);
    });

    console.log('\n🎯 Testing specific dashboard secrets...');
    
    // Test specific secrets that the dashboard needs
    const requiredSecrets = [
      'AUTH_SECRET',
      'SECRET_ENCRYPTION_KEY', 
      'AUTH_OIDC_CLIENT_SECRET',
      'AUTH_OIDC_CLIENT_ID',
      'AUTH_OIDC_ISSUER'
    ];

    const secretsMap = {};
    for (const secretName of requiredSecrets) {
      try {
        const secret = secrets.find(s => s.secretKey === secretName);
        if (secret?.secretValue) {
          secretsMap[secretName] = secret.secretValue;
          console.log(`   ✅ ${secretName}: Available`);
        } else {
          console.log(`   ⚠️  ${secretName}: Not found`);
        }
      } catch (error) {
        console.log(`   ❌ ${secretName}: Error - ${error.message}`);
      }
    }

    console.log('\n🧪 Test Results:');
    console.log(`   ✅ Connection: Working`);
    console.log(`   ✅ Authentication: Working`);
    console.log(`   ✅ Secret Retrieval: Working`);
    console.log(`   📊 Secrets Found: ${Object.keys(secretsMap).length}/${requiredSecrets.length}`);
    
    if (Object.keys(secretsMap).length === requiredSecrets.length) {
      console.log('\n🎉 All tests passed! Ready to integrate with dashboard.');
    } else {
      console.log('\n⚠️  Some secrets are missing. Please add them to Infisical before proceeding.');
    }

  } catch (error) {
    console.error('\n❌ Test failed:');
    console.error(`   Error: ${error.message}`);
    
    if (error.message.includes('401') || error.message.includes('unauthorized')) {
      console.error('   💡 Check your INFISICAL_CLIENT_ID and INFISICAL_CLIENT_SECRET');
    } else if (error.message.includes('404') || error.message.includes('not found')) {
      console.error('   💡 Check your INFISICAL_PROJECT_ID and INFISICAL_ENVIRONMENT');
    } else if (error.message.includes('ECONNREFUSED')) {
      console.error('   💡 Check if Infisical is running at', config.siteUrl);
    }
    
    console.error('\n🔧 Troubleshooting:');
    console.error('   1. Verify Infisical is running: curl http://localhost:8081/api/status');
    console.error('   2. Check machine identity credentials in Infisical UI');
    console.error('   3. Verify project ID and environment name');
    
    process.exit(1);
  }
}

// Run the test
if (require.main === module) {
  testInfisicalConnection().catch(console.error);
}

module.exports = { testInfisicalConnection };
