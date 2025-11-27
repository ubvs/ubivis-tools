# SSOM Quick Start Guide

## 🚀 Get Started in 3 Steps

### 1. Start Keycloak with Nx
```bash
# From workspace root
nx start ssom
```

### 2. Access Admin Console
Open: http://localhost:8080/admin

**Default Credentials**:
- Username: `admin`
- Password: `admin`

### 3. Create Your First Realm
1. Click "Create Realm" in the admin console
2. Name it `ubivis`
3. Click "Create"

---

## 📋 Common Nx Commands

```bash
# Start Keycloak (detached)
nx start ssom

# Start Keycloak (with logs)
nx start ssom --configuration=dev

# View logs
nx logs ssom

# Stop Keycloak
nx stop ssom

# Restart Keycloak
nx restart ssom

# Check health
nx health-check ssom

# Build Docker image
nx build ssom
```

---

## 🔧 Configuration

### Environment Variables

Copy the example file:
```bash
cp apps/ssom/.env.example apps/ssom/.env
```

Edit as needed:
```env
KC_BOOTSTRAP_ADMIN_USERNAME=your-username
KC_BOOTSTRAP_ADMIN_PASSWORD=your-password
```

---

## 🧪 Integration with Other Apps

### Create a Client for Another App

1. **Open Admin Console**: http://localhost:8080/admin
2. **Select Realm**: Choose or create a realm (e.g., "ubivis")
3. **Navigate**: Clients → Create client
4. **Configure**:
   - Client ID: `my-app`
   - Client authentication: ON (for confidential clients)
   - Valid redirect URIs: `http://localhost:3000/*`
5. **Save** and note the client secret

### Configure Your App

Use these endpoints:
```
Authorization: http://localhost:8080/realms/ubivis/protocol/openid-connect/auth
Token: http://localhost:8080/realms/ubivis/protocol/openid-connect/token
Userinfo: http://localhost:8080/realms/ubivis/protocol/openid-connect/userinfo
```

---

## 📚 Next Steps

- **Customize themes**: Add to `apps/ssom/themes/`
- **Add custom providers**: Build JARs and add to `apps/ssom/providers/`
- **Review full docs**: See `apps/ssom/README.md`
- **Deploy to production**: Follow Coolify deployment guide

---

## ❓ Troubleshooting

### Can't access admin console?
```bash
# Check if running
docker ps | grep keycloak

# Check health
nx health-check ssom

# Check logs
nx logs ssom
```

### Port 8080 already in use?
```bash
# Find what's using the port
lsof -i :8080

# Kill the process or change port in docker-compose.yml
```

### Database connection error?
```bash
# Ensure PostgreSQL is running
docker ps | grep postgres

# Check database was created
nx logs ssom | grep "database"
```

---

## 🎯 Key URLs

- **Admin Console**: http://localhost:8080/admin
- **Account Console**: http://localhost:8080/realms/{realm}/account
- **Health Check**: http://localhost:8080/health
- **Metrics**: http://localhost:8080/metrics

---

For detailed documentation, see [README.md](./README.md)
