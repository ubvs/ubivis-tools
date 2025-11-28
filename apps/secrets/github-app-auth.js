#!/usr/bin/env node
/**
 * GitHub App Authentication Script
 * Generates JWT and obtains installation access token
 * Returns only the access token on success
 */

const crypto = require('crypto');
const https = require('https');

// Get environment variables
const appId = process.env.GITHUB_APP_ID;
const privateKeyB64 = process.env.GITHUB_APP_PRIVATE_KEY;

if (!appId || !privateKeyB64) {
  console.error('ERROR: Missing GITHUB_APP_ID or GITHUB_APP_PRIVATE_KEY');
  process.exit(1);
}

// Decode the base64 private key
const privateKey = Buffer.from(privateKeyB64, 'base64').toString('utf8');

// Generate JWT
const now = Math.floor(Date.now() / 1000);
const payload = {
  iat: now - 60,
  exp: now + (10 * 60),
  iss: appId
};

// base64url encoding helper
function base64url(str) {
  return Buffer.from(str)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

// Create JWT
const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
const payloadB64 = base64url(JSON.stringify(payload));
const unsignedToken = `${header}.${payloadB64}`;

// Sign the JWT
const sign = crypto.createSign('RSA-SHA256');
sign.update(unsignedToken);
const signature = sign.sign(privateKey, 'base64')
  .replace(/\+/g, '-')
  .replace(/\//g, '_')
  .replace(/=/g, '');

const jwt = `${unsignedToken}.${signature}`;

// HTTPS request helper
function httpsRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            resolve(data);
          }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    if (postData) req.write(postData);
    req.end();
  });
}

// Main execution
(async () => {
  try {
    // Get installations
    const installations = await httpsRequest({
      hostname: 'api.github.com',
      path: '/app/installations',
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Coolify-Deployment'
      }
    });

    if (!installations || !installations[0]) {
      console.error('ERROR: No installations found');
      process.exit(1);
    }

    const installationId = installations[0].id;

    // Get access token
    const tokenResponse = await httpsRequest({
      hostname: 'api.github.com',
      path: `/app/installations/${installationId}/access_tokens`,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Coolify-Deployment'
      }
    });

    if (!tokenResponse || !tokenResponse.token) {
      console.error('ERROR: No token in response');
      process.exit(1);
    }

    // Output only the token (for easy capture in bash)
    console.log(tokenResponse.token);
    process.exit(0);

  } catch (error) {
    console.error('ERROR:', error.message);
    process.exit(1);
  }
})();
