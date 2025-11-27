# Deployment Guide - Coolify on Hetzner

This guide covers deploying all apps from the NX monorepo to production using Coolify and Hetzner Cloud.

## Architecture Overview

**Deployment Order (CRITICAL):**
1. **Secrets (Infisical)** - Deploy FIRST (no dependencies)
2. **SSOM (Keycloak)** - Deploy SECOND (depends on Infisical)
3. **Dashboard & Chat** - Deploy LAST (depend on both Infisical + Keycloak)

**Infrastructure:**
- Each app runs on its own Hetzner instance with local database
- Apps communicate via Hetzner Private Network (10.0.0.0/24)
- All apps fetch secrets from Infisical at startup
- All apps use Keycloak for SSO authentication

**Private Network IPs (Hetzner Auto-Assigned):**
- `10.0.0.3` - Coolify (Management)
- `10.0.0.2` - Secrets (Infisical)
- TBD - SSOM (Keycloak) - will be assigned by Hetzner
- TBD - Dashboard - will be assigned by Hetzner
- TBD - Chat - will be assigned by Hetzner

---

## Step 1: Create Hetzner Instances

### 1.1 Create Private Network

1. Log into Hetzner Cloud Console
2. Go to **Networks** → **Create Network**
3. Configure:
   - Name: `ubivis-private`
   - IP Range: `10.0.0.0/24`
   - Location: Choose your preferred location

### 1.2 Provision Servers

Create the following instances:

| App | Instance Type | IP | Cost/Month |
|-----|--------------|-----|------------|
| Secrets | CPX11 (2GB RAM, 2 vCPU) | 10.0.0.13 | $5.59 |
| SSOM | CPX21 (4GB RAM, 3 vCPU) | 10.0.0.12 | $10.59 |
| Dashboard | CPX11 (2GB RAM, 2 vCPU) | 10.0.0.10 | $5.59 |
| Chat | CPX21 (4GB RAM, 3 vCPU) | 10.0.0.11 | $10.59 |
| Coolify | CPX21 (4GB RAM, 3 vCPU) | - | $10.59 |

**For each server:**
1. Click **Add Server**
2. Select **Location** (same as network)
3. Select **Image**: Ubuntu 22.04
4. Select **Type**: CPX11 or CPX21 (per table above)
5. Select **Networking**: Attach to `ubivis-private` network
6. Add **SSH Key**
7. Set **Name**: `secrets-prod`, `ssom-prod`, `dashboard-prod`, `chat-prod`, `coolify-mgmt`
8. Click **Create & Buy Now**

### 1.3 Assign Static Private IPs

For each server (except Coolify):
1. Go to **Networking** tab
2. Under **Private Networks**, click on `ubivis-private`
3. Set **Alias IP** according to table above
4. Save

### 1.4 Configure Firewall

Create a firewall for all app servers:

**Inbound Rules:**
- SSH (22) - From your IP only
- HTTP (80) - From anywhere
- HTTPS (443) - From anywhere

**Outbound Rules:**
- Allow all

Apply firewall to all 4 app servers (not Coolify management).

---

## Step 2: Install Coolify

On the `coolify-mgmt` server:

```bash
ssh root@<coolify-server-ip>
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

After installation:
1. Access Coolify at `http://<coolify-server-ip>:8000`
2. Complete initial setup
3. Set admin password

---

## Step 3: Add Servers to Coolify

### 3.1 Add Each Hetzner Server

For each of the 4 app servers:

1. In Coolify: **Settings** → **Servers** → **Add Server**
2. Configure:
   - **Name**: `secrets-prod`, `ssom-prod`, `dashboard-prod`, or `chat-prod`
   - **IP Address**: Public IP of the Hetzner server
   - **Port**: 22
   - **User**: root
   - **Private Key**: Your SSH private key
3. Click **Validate & Save**
4. Coolify will install Docker if needed

### 3.2 Verify Connectivity

Ensure all 4 servers show as "Connected" in Coolify.

---

## Step 4: Deploy Secrets (Infisical) - FIRST

### 4.1 Create Coolify Project

1. **Projects** → **New Project**
2. Name: `ubivis-tools`
3. Save

### 4.2 Deploy Infisical

1. **Add Resource** → **Docker Compose**
2. Configure:
   - **Name**: `secrets`
   - **Server**: `secrets-prod`
   - **Source**: Git Repository
   - **Repository**: `https://github.com/ubvs/ubivis-tools.git`
   - **Branch**: `main`
   - **Docker Compose Location**: `apps/secrets/docker-compose.coolify.yml`
   - **Base Directory**: `/`

3. **Environment Variables** (in Coolify):
   ```bash
   # PostgreSQL
   POSTGRES_PASSWORD=<generate-strong-password>
   
   # Encryption Keys (generate with: openssl rand -hex 32)
   ENCRYPTION_KEY=<64-char-hex-string>
   AUTH_SECRET=<64-char-hex-string>
   JWT_AUTH_SECRET=<random-string>
   JWT_REFRESH_SECRET=<random-string>
   JWT_SERVICE_SECRET=<random-string>
   
   # Site URL
   SITE_URL=https://secrets.yourdomain.com
   
   # SMTP (optional)
   SMTP_HOST=smtp.yourprovider.com
   SMTP_PORT=587
   SMTP_USERNAME=your-username
   SMTP_PASSWORD=your-password
   SMTP_FROM_ADDRESS=noreply@yourdomain.com
   ```

4. **Domain Settings**:
   - Add domain: `secrets.yourdomain.com`
   - Enable SSL (Let's Encrypt)

5. **Deploy**

6. **Verify**: Visit `https://secrets.yourdomain.com` and complete Infisical setup

### 4.3 Setup Infisical Projects

1. Log into Infisical
2. Create projects for each app:
   - `dashboard-prod`
   - `chat-prod`
   - `ssom-prod`
3. For each project, create a **Machine Identity** (Universal Auth):
   - Go to Project → Settings → Machine Identities
   - Create new identity
   - Save `CLIENT_ID` and `CLIENT_SECRET`

---

## Step 5: Deploy SSOM (Keycloak) - SECOND

### 5.1 Deploy Keycloak

1. **Add Resource** → **Docker Compose**
2. Configure:
   - **Name**: `ssom`
   - **Server**: `ssom-prod`
   - **Source**: Git Repository
   - **Repository**: `https://github.com/ubvs/ubivis-tools.git`
   - **Branch**: `main`
   - **Docker Compose Location**: `apps/ssom/docker-compose.coolify.yml`
   - **Base Directory**: `/`

3. **Environment Variables**:
   ```bash
   # Admin Credentials
   KC_BOOTSTRAP_ADMIN_USERNAME=admin
   KC_BOOTSTRAP_ADMIN_PASSWORD=<generate-strong-password>
   
   # Database
   KC_DB_USERNAME=keycloak
   KC_DB_PASSWORD=<generate-strong-password>
   
   # Domain
   KC_HOSTNAME=ssom.yourdomain.com
   
   # Infisical Integration
   INFISICAL_URL=http://10.0.0.2:8080
   INFISICAL_PROJECT_ID=<ssom-project-id-from-infisical>
   INFISICAL_CLIENT_ID=<machine-identity-client-id>
   INFISICAL_CLIENT_SECRET=<machine-identity-client-secret>
   INFISICAL_ENVIRONMENT=production
   ```

4. **Domain Settings**:
   - Add domain: `ssom.yourdomain.com`
   - Enable SSL

5. **Deploy**

6. **Verify**: Visit `https://ssom.yourdomain.com` and log in

### 5.2 Configure Keycloak for Apps

1. Log into Keycloak admin console
2. Create realm: `ubivis`
3. Create clients for each app:
   
   **Dashboard Client:**
   - Client ID: `dashboard`
   - Client Protocol: `openid-connect`
   - Access Type: `confidential`
   - Valid Redirect URIs: `https://dashboard.yourdomain.com/*`
   - Save and get **Client Secret**
   
   **Chat Client:**
   - Client ID: `chat`
   - Client Protocol: `openid-connect`
   - Access Type: `confidential`
   - Valid Redirect URIs: `https://chat.yourdomain.com/*`
   - Save and get **Client Secret**

4. Create groups/roles:
   - `Administrators`
   - `Users`

5. Store client secrets in Infisical:
   - In dashboard-prod project: Add `AUTH_OIDC_CLIENT_SECRET`
   - In chat-prod project: Add `KEYCLOAK_CLIENT_SECRET`

---

## Step 6: Deploy Dashboard - THIRD

### 6.1 Add Secrets to Infisical

In the `dashboard-prod` project in Infisical, add:

```bash
AUTH_SECRET=<openssl-rand-base64-32>
SECRET_ENCRYPTION_KEY=<openssl-rand-base64-32>
AUTH_OIDC_CLIENT_ID=dashboard
AUTH_OIDC_CLIENT_SECRET=<from-keycloak-client-secret>
AUTH_OIDC_ISSUER=http://10.0.0.12:8080/realms/ubivis
```

### 6.2 Deploy Dashboard

1. **Add Resource** → **Docker Compose**
2. Configure:
   - **Name**: `dashboard`
   - **Server**: `dashboard-prod`
   - **Source**: Git Repository
   - **Repository**: `https://github.com/ubvs/ubivis-tools.git`
   - **Branch**: `main`
   - **Docker Compose Location**: `apps/dashboard/docker-compose.coolify.yml`
   - **Base Directory**: `/`
   - **Build Pack**: `nixpacks` (for building the app)

3. **Environment Variables**:
   ```bash
   # Application
   BASE_URL=https://dashboard.yourdomain.com
   LOG_LEVEL=info
   
   # Keycloak SSO
   AUTH_OIDC_URI=http://10.0.0.12:8080/realms/ubivis
   AUTH_OIDC_ADMIN_ROLE=Administrators
   AUTH_OIDC_OWNER_ROLE=Administrators
   
   # Infisical Integration
   INFISICAL_SITE_URL=http://10.0.0.2:8080
   INFISICAL_PROJECT_ID=<dashboard-project-id>
   INFISICAL_CLIENT_ID=<machine-identity-client-id>
   INFISICAL_CLIENT_SECRET=<machine-identity-client-secret>
   INFISICAL_ENVIRONMENT=production
   ```

4. **Domain Settings**:
   - Add domain: `dashboard.yourdomain.com`
   - Enable SSL

5. **Deploy**

**Note**: Dashboard will run `start-with-secrets.sh` on startup, which fetches all secrets from Infisical.

---

## Step 7: Deploy Chat - FOURTH

### 7.1 Add Secrets to Infisical

In the `chat-prod` project in Infisical, add ALL Rocket.Chat secrets including:

```bash
# Admin
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASS=<strong-password>

# Keycloak OAuth
KEYCLOAK_CLIENT_ID=chat
KEYCLOAK_CLIENT_SECRET=<from-keycloak-client-secret>
KEYCLOAK_URL=http://10.0.0.12:8080
KEYCLOAK_TOKEN_PATH=/realms/ubivis/protocol/openid-connect/token
KEYCLOAK_IDENTITY_PATH=/realms/ubivis/protocol/openid-connect/userinfo
KEYCLOAK_AUTHORIZE_PATH=/realms/ubivis/protocol/openid-connect/auth
KEYCLOAK_SCOPE=openid profile email
KEYCLOAK_BUTTON_LABEL_TEXT=Login with Keycloak
KEYCLOAK_BUTTON_LABEL_COLOR=#FFFFFF
KEYCLOAK_BUTTON_COLOR=#1d74f5
KEYCLOAK_LOGIN_STYLE=redirect
KEYCLOAK_USERNAME_FIELD=preferred_username
KEYCLOAK_MERGE_USERS=false

# Add any other Rocket.Chat specific secrets here
```

### 7.2 Deploy Chat

1. **Add Resource** → **Docker Compose**
2. Configure:
   - **Name**: `chat`
   - **Server**: `chat-prod`
   - **Source**: Git Repository
   - **Repository**: `https://github.com/ubvs/ubivis-tools.git`
   - **Branch**: `main`
   - **Docker Compose Location**: `apps/chat/docker-compose.coolify.yml`
   - **Base Directory**: `/`

3. **Environment Variables**:
   ```bash
   # Application
   ROOT_URL=https://chat.yourdomain.com
   
   # Infisical Integration
   INFISICAL_SITE_URL=http://10.0.0.2:8080
   INFISICAL_PROJECT_ID=<chat-project-id>
   INFISICAL_CLIENT_ID=<machine-identity-client-id>
   INFISICAL_CLIENT_SECRET=<machine-identity-client-secret>
   INFISICAL_ENVIRONMENT=production
   ```

4. **Domain Settings**:
   - Add domain: `chat.yourdomain.com`
   - Enable SSL

5. **Deploy**

**Note**: Chat will run `start-with-secrets.sh` on startup, which fetches ALL secrets from Infisical and configures Keycloak OAuth.

---

## Deployment Behavior

### On Redeploy (Coolify Rebuild):
- Pulls latest code from Git
- Rebuilds Docker images
- Runs `start-with-secrets.sh` scripts
- Fetches fresh secrets from Infisical
- **Use this when code changes**

### On Restart:
- Restarts containers without rebuilding
- Does NOT fetch new secrets
- **Use this for quick restarts**

---

## Monitoring & Logs

### View Logs
In Coolify for each app:
- Click on app → **Logs** tab
- Real-time logs streaming

### Health Checks
All apps have health checks configured:
- Coolify shows status indicators
- Auto-restart on health check failures

### Metrics
Access via Coolify dashboard:
- CPU usage
- Memory usage
- Network traffic

---

## Troubleshooting

### App won't start after deployment

**Check logs for Infisical connection errors:**
```bash
# In Coolify logs, look for:
"Failed to fetch secrets from Infisical"
```

**Solution:**
1. Verify Infisical is accessible at `http://10.0.0.13:8080` from the app server
2. Check `INFISICAL_CLIENT_ID` and `INFISICAL_CLIENT_SECRET` are correct
3. Verify secrets exist in Infisical project

### Private network communication not working

**Test connectivity:**
```bash
ssh root@<app-server>
ping 10.0.0.13  # Should reach Infisical
curl http://10.0.0.13:8080/api/status  # Should return OK
```

**Solution:**
- Ensure all servers are attached to the same private network
- Verify alias IPs are configured correctly

### Secrets not updating

**Solution:**
- Update secrets in Infisical
- Trigger a **Redeploy** (not Restart) in Coolify
- The `start-with-secrets.sh` script will fetch fresh secrets

---

## Backup Strategy

### Databases (Automated)
Configure Coolify backups for each app:
1. Go to app → **Backups** tab
2. Configure S3/Backblaze/local backup
3. Set schedule (daily recommended)

### Manual Database Backup

**Infisical (PostgreSQL):**
```bash
docker exec infisical-db pg_dump -U infisical infisical > backup.sql
```

**Keycloak (PostgreSQL):**
```bash
docker exec ssom-postgres pg_dump -U keycloak keycloak > backup.sql
```

**Dashboard (SQLite):**
```bash
docker exec dashboard-homarr cp /appdata/db/db.sqlite /tmp/backup.db
docker cp dashboard-homarr:/tmp/backup.db ./dashboard-backup.db
```

**Chat (MongoDB):**
```bash
docker exec chat-mongodb mongodump --archive=/tmp/backup.archive
docker cp chat-mongodb:/tmp/backup.archive ./chat-backup.archive
```

---

## Cost Summary

| Resource | Monthly Cost |
|----------|-------------|
| Secrets (CPX11) | $5.59 |
| SSOM (CPX21) | $10.59 |
| Dashboard (CPX11) | $5.59 |
| Chat (CPX21) | $10.59 |
| Coolify (CPX21) | $10.59 |
| **Total** | **$42.36** |

---

## Security Checklist

- [ ] All secrets stored in Infisical (never in Git)
- [ ] Firewall configured on all servers
- [ ] SSH key authentication only (no password)
- [ ] SSL/HTTPS enabled for all domains
- [ ] Database ports not exposed to internet
- [ ] Private network used for inter-service communication
- [ ] Regular backups configured
- [ ] Strong passwords for all admin accounts
- [ ] Keycloak admin access restricted

---

## Next Steps

1. Set up DNS records for your domains
2. Configure custom SMTP for email notifications
3. Set up monitoring/alerting (Uptime Robot, Better Stack, etc.)
4. Configure CI/CD webhooks for automatic deployments
5. Test SSO login flow across all apps
6. Create regular backup schedule
