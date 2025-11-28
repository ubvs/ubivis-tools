# Infisical (Secrets Management) - Production Deployment

Self-hosted secrets management platform for storing and managing sensitive credentials.

## 🚨 CRITICAL: Encryption Key Management

### ⚠️ Security Trade-off: Key Rotation vs Data Persistence

Infisical has a **fundamental limitation**: it does not support encryption key rotation without data loss. This creates a security vs. operational trade-off:

**The Dilemma:**
- **Security Best Practice**: Rotate encryption keys regularly (quarterly/annually)
- **Infisical Reality**: Rotating keys makes all existing data permanently inaccessible

**The following environment variables encrypt all data in the database:**

- `ENCRYPTION_KEY` - Master encryption key for all secrets
- `AUTH_SECRET` - Authentication encryption key  
- `JWT_AUTH_SECRET` - JWT token signing key
- `JWT_REFRESH_SECRET` - JWT refresh token key
- `JWT_SERVICE_SECRET` - Service token key

**⚠️ WARNING**: If you rotate these keys after initial deployment, Infisical **CANNOT DECRYPT EXISTING DATA** and will crash with:

```
Error: Unsupported state or unable to authenticate data
DatabaseError: password authentication failed
```

### What Happens If Keys Are Rotated

1. The database contains data encrypted with the **old** keys
2. The application tries to decrypt using the **new** keys
3. Decryption fails → application crashes on startup
4. **All existing secrets become permanently inaccessible**

### Recovery Options If Keys Are Rotated

If you accidentally rotate encryption keys, you have **only two options**:

#### Option 1: Restore Old Keys (Preferred)
If you have the old keys backed up, restore them:
1. Update environment variables in Coolify with the old keys
2. Redeploy the application
3. Verify it starts successfully

#### Option 2: Complete Data Wipe (Last Resort)
If old keys are lost, you must wipe all data and start fresh:

```bash
# SSH into the server
ssh root@your-server

# Stop all containers
docker stop $(docker ps -q --filter name=secrets)

# Remove containers
docker rm $(docker ps -aq --filter name=secrets)

# Remove volumes (THIS DELETES ALL DATA)
docker volume rm $(docker volume ls -q | grep secrets)

# Redeploy through Coolify UI
```

This will:
- ✅ Allow the app to start with new keys
- ❌ **Permanently delete all existing secrets**
- ❌ Require recreating all projects and secrets from scratch

### Mitigation Strategies

Since Infisical doesn't support key rotation, you must implement compensating controls:

#### 1. **Treat This as a "Break Glass" System**
- Use Infisical to **bootstrap** other secrets management systems
- Don't store long-lived production secrets directly in Infisical
- Use it to store keys that access proper KMS systems (AWS KMS, Azure Key Vault, GCP KMS)

#### 2. **Implement Periodic Data Migration**
Instead of rotating keys, periodically "rotate" the entire Infisical instance:

```bash
# Every 90 days (or per your security policy):
1. Deploy NEW Infisical instance with new encryption keys
2. Export all secrets from OLD instance (via UI or API)
3. Import secrets into NEW instance  
4. Update all applications to use NEW instance
5. Destroy OLD instance after verification period
```

#### 3. **Key Security Best Practices**

**Generate Strong Keys Once:**
```bash
openssl rand -hex 32  # For ENCRYPTION_KEY
openssl rand -hex 64  # For AUTH_SECRET and JWT secrets
```

**Secure Key Storage:**
- Store in an **external** secrets manager (ironic, but necessary)
- Hardware Security Module (HSM) for critical environments
- Encrypted vault (HashiCorp Vault, AWS Secrets Manager)
- Password manager with emergency access (1Password, Bitwarden)
- **NEVER** commit to Git
- **NEVER** store in Infisical itself (chicken-and-egg problem)

**Emergency Access:**
- Document key storage location in runbooks
- Implement "break glass" procedures for key recovery
- Test recovery procedures quarterly

#### 4. **Use Short-Lived Credentials Everywhere**
Minimize the impact of non-rotatable keys:
- Use dynamic secrets feature for databases
- Implement short-lived API tokens (hours, not days)
- Rotate **secrets stored in** Infisical frequently (even if keys can't rotate)

#### 5. **Consider Alternatives for High-Security Environments**
If key rotation is a hard requirement (compliance, policy), consider:
- **Cloud-native KMS**: AWS Secrets Manager, Azure Key Vault, GCP Secret Manager
- **HashiCorp Vault**: Supports key rotation with re-encryption
- **CyberArk**: Enterprise solution with key rotation
- **Infisical Cloud**: Managed service where they handle key rotation

#### 6. **Monitoring & Audit**
- Monitor for unauthorized access attempts
- Audit secret access logs weekly
- Alert on bulk secret exports
- Track failed authentication attempts

## Environment Variables

### Required Keys (Set Once, Never Change)
```bash
ENCRYPTION_KEY=<32-byte-hex>          # Master encryption key
AUTH_SECRET=<64-byte-hex>             # Auth encryption
JWT_AUTH_SECRET=<64-byte-hex>         # JWT signing
JWT_REFRESH_SECRET=<64-byte-hex>      # JWT refresh
JWT_SERVICE_SECRET=<64-byte-hex>      # Service tokens
```

### Database (Safe to Rotate)
```bash
POSTGRES_PASSWORD=<strong-password>   # Can be changed with proper procedure
```

### Application Settings (Safe to Change)
```bash
SITE_URL=https://secrets.yourdomain.com
INVITE_ONLY=false
TELEMETRY_ENABLED=false
```

### Optional: SMTP Configuration (Safe to Change)
```bash
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=noreply@example.com
SMTP_PASSWORD=<smtp-password>
SMTP_FROM_ADDRESS=noreply@yourdomain.com
```

## How to Safely Rotate Database Password

Unlike encryption keys, you **can** rotate the database password:

```bash
# 1. SSH into server
ssh root@your-server

# 2. Find database container
DB_CONTAINER=$(docker ps --format '{{.Names}}' | grep 'db-.*secrets')

# 3. Connect and change password
docker exec $DB_CONTAINER psql -U infisical -d infisical -c \
  "ALTER USER infisical WITH PASSWORD 'new_password';"

# 4. Update POSTGRES_PASSWORD in Coolify environment variables

# 5. Restart the backend container
docker restart $(docker ps --format '{{.Names}}' | grep 'backend-.*secrets')
```

## Deployment

This app is deployed to a self-contained Hetzner instance via Coolify.

### Infrastructure
- **Instance**: Hetzner CPX11 (2GB RAM, 2 vCPU, 40GB SSD)
- **Cost**: ~$5.59/month
- **Network**: Bridge network (no cross-server dependencies)

### Components
- **Backend**: Infisical server (Node.js on port 8080)
- **Database**: PostgreSQL 14 (local, port 5432)
- **Cache**: Redis 7 (local, port 6379)

### Deploy via Coolify

1. Create new "Docker Compose" resource in Coolify
2. Point to this repository
3. Set Docker Compose path: `apps/secrets/docker-compose.coolify.yml`
4. Configure environment variables (see above)
5. Deploy

### Health Checks

Backend health endpoint: `http://localhost:8080/api/status`

Expected response:
```json
{
  "date": "2025-11-28T21:26:31.552Z",
  "message": "Ok",
  "emailConfigured": false,
  "inviteOnlySignup": true,
  "redisConfigured": true,
  "secretScanningConfigured": false
}
```

## Troubleshooting

### Issue: "Unsupported state or unable to authenticate data"

**Cause**: Encryption keys were rotated after data was encrypted

**Solution**: See "Recovery Options If Keys Are Rotated" above

### Issue: "password authentication failed for user 'infisical'"

**Cause**: Database password mismatch between container env and actual DB

**Solution**: Follow "How to Safely Rotate Database Password" above

### Issue: Backend won't start / keeps restarting

Check logs:
```bash
docker logs $(docker ps --format '{{.Names}}' | grep 'backend-.*secrets') --tail 50
```

Common causes:
1. Database not ready → Wait for health check
2. Redis not available → Check Redis container
3. Encryption key issue → See above
4. Missing required env vars → Check Coolify configuration

## Security Considerations

1. **Never expose database ports**: Keep PostgreSQL on localhost only
2. **Use strong passwords**: Generate with `openssl rand -base64 32`
3. **Enable HTTPS**: Coolify handles SSL automatically
4. **Regular backups**: Backup PostgreSQL volume daily
5. **Monitor logs**: Watch for unauthorized access attempts
6. **Rotate database password**: Do this quarterly (not encryption keys!)

## Backup & Restore

### Backup Database
```bash
docker exec <db-container> pg_dump -U infisical infisical > backup.sql
```

### Restore Database
```bash
docker exec -i <db-container> psql -U infisical infisical < backup.sql
```

⚠️ **Remember**: Backups are useless if you lose the encryption keys!

## Additional Resources

- [Infisical Documentation](https://infisical.com/docs)
- [Infisical GitHub](https://github.com/Infisical/infisical)
- [Coolify Documentation](https://coolify.io/docs)
