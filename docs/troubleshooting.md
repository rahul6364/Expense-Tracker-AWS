# Troubleshooting Guide

Common issues encountered during AWS deployment of the Expense Tracker 3-tier application, with root causes and resolution steps.

---

## Table of Contents

1. [Target Group Unhealthy](#1-target-group-unhealthy)
2. [Docker Permission Denied](#2-docker-permission-denied)
3. [Database Connection Issues](#3-database-connection-issues)
4. [ALB Listener Rule Issues](#4-alb-listener-rule-issues)
5. [RDS Connectivity Issues](#5-rds-connectivity-issues)
6. [Unknown Database Errors](#6-unknown-database-errors)
7. [CORS and API URL Mismatch](#7-cors-and-api-url-mismatch)
8. [Frontend Shows Connection Error](#8-frontend-shows-connection-error)
9. [502 Bad Gateway from ALB](#9-502-bad-gateway-from-alb)
10. [Docker Image Pull Failures on EC2](#10-docker-image-pull-failures-on-ec2)

---

## 1. Target Group Unhealthy

### Symptoms

- ALB target group shows **unhealthy** targets
- Browser returns `503 Service Temporarily Unavailable`
- ASG keeps replacing instances

### Root Causes

| Cause | Tier |
|-------|------|
| Wrong health check path or port | Both |
| Security group blocking ALB → EC2 traffic | Both |
| Container not running or crashed on boot | Both |
| Health check grace period too short | Both |
| Backend not listening on `0.0.0.0` | Backend |

### Resolution

**Step 1 — Verify health check settings**

| Target Group | Port | Path | Expected |
|--------------|------|------|----------|
| Frontend | 80 | `/health` | HTTP 200, body `ok` |
| Backend | 4000 | `/health` | HTTP 200, `{"status":"ok"}` |

**Step 2 — Test locally on the EC2 instance (SSM Session Manager)**

```bash
# Frontend instance
curl -i http://localhost/health

# Backend instance
curl -i http://localhost:4000/health
```

**Step 3 — Check security groups**

- ALB security group must be the **source** for inbound rules on EC2 security groups.
- Do not use `0.0.0.0/0` on EC2 — use the ALB security group ID.

**Step 4 — Inspect container status**

```bash
sudo docker ps -a
sudo docker logs expense-api    # backend
sudo docker logs expense-web    # frontend
```

**Step 5 — Increase health check grace period**

Set ASG **Health check grace period** to `300` seconds to allow Docker pull and container start before marking unhealthy.

---

## 2. Docker Permission Denied

### Symptoms

```
permission denied while trying to connect to the Docker daemon socket
Got permission denied while trying to connect to the Docker daemon
```

### Root Causes

- User running Docker commands is not in the `docker` group
- Docker service not started
- User data script runs before Docker is fully installed

### Resolution

**On EC2 (interactive):**

```bash
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
# Log out and back in, or:
newgrp docker
```

**In user data scripts:**

```bash
#!/bin/bash
set -e
dnf install -y docker
systemctl enable docker
systemctl start docker

# Always use sudo in user data if not switching users
sudo docker pull your-dockerhub-user/expense-tracker-api:latest
sudo docker run -d ...
```

**Verify:**

```bash
sudo docker info
sudo docker ps
```

---

## 3. Database Connection Issues

### Symptoms

```
Error: connect ECONNREFUSED
Error: Access denied for user
Missing required environment variable: DB_HOST
Failed to fetch transactions (500 from API)
```

### Root Causes

| Cause | Fix |
|-------|-----|
| Missing env vars in container | Pass all `DB_*` vars to `docker run` |
| Wrong RDS endpoint | Copy endpoint from RDS console (not proxy unless configured) |
| Security group not allowing 3306 | Add backend SG as source on RDS SG |
| Backend in wrong subnet | Must reach RDS via VPC routing |
| Incorrect username/password | Verify RDS master credentials |

### Resolution

**Step 1 — Verify environment inside container**

```bash
sudo docker exec expense-api env | grep DB_
```

Expected output:

```
DB_HOST=expense-tracker-db.xxxxx.us-east-1.rds.amazonaws.com
DB_USER=admin
DB_PASS=****
DB_NAME=expense_tracker
DB_PORT=3306
```

**Step 2 — Test MySQL from backend EC2**

```bash
# Install mysql client if needed
sudo dnf install -y mariadb105
mysql -h YOUR_RDS_ENDPOINT -u admin -p -e "SHOW DATABASES;"
```

**Step 3 — Check security groups**

- RDS SG inbound: port `3306` from `sg-backend-ec2` only.

**Step 4 — Restart container with correct env**

```bash
sudo docker stop expense-api && sudo docker rm expense-api
sudo docker run -d \
  --name expense-api \
  --restart unless-stopped \
  -p 4000:4000 \
  -e DB_HOST="..." \
  -e DB_USER="..." \
  -e DB_PASS="..." \
  -e DB_NAME="expense_tracker" \
  -e DB_PORT="3306" \
  your-dockerhub-user/expense-tracker-api:latest
```

---

## 4. ALB Listener Rule Issues

### Symptoms

- UI loads but API returns HTML (index.html) instead of JSON
- `/api/transactions` returns 404 from nginx
- API works on direct EC2 IP but not through ALB

### Root Causes

- Path rule priority incorrect — default rule catches `/api/*` first
- API requests hitting frontend target group
- Missing `/api/*` rule entirely

### Resolution

**Correct rule priority:**

| Priority | Condition | Target |
|----------|-----------|--------|
| 1 | Path `/api/*` | Backend target group |
| Default | `/*` | Frontend target group |

**Verify with curl:**

```bash
# Should return JSON
curl -i http://YOUR-ALB-DNS/api/transactions

# Should return HTML
curl -i http://YOUR-ALB-DNS/
```

**Common mistake:** Creating a rule for `/api` without the wildcard — use `/api/*`.

---

## 5. RDS Connectivity Issues

### Symptoms

- Backend health check passes but API returns 500
- `ETIMEDOUT` connecting to RDS
- Works from bastion but not from backend EC2

### Root Causes

| Cause | Details |
|-------|---------|
| RDS in different VPC | VPC peering or wrong subnet group |
| Backend SG not authorized | RDS SG missing inbound rule |
| Wrong subnet routing | DB subnet has IGW/NAT route by mistake |
| RDS still provisioning | Status must be **Available** |

### Resolution

1. Confirm RDS **VPC** matches backend EC2 VPC.
2. Confirm RDS subnet group uses **private-db** subnets only.
3. Verify RDS **Connectivity & security** → Publicly accessible = **No**.
4. Test from backend instance:

```bash
nc -zv YOUR_RDS_ENDPOINT 3306
# or
telnet YOUR_RDS_ENDPOINT 3306
```

5. Check **VPC Flow Logs** (optional) for rejected traffic on port 3306.

---

## 6. Unknown Database Errors

### Symptoms

```
Error: Unknown database 'expense_tracker'
ER_BAD_DB_ERROR: Unknown database
```

### Root Causes

- Database name not created during RDS setup
- `DB_NAME` env var typo (case-sensitive on Linux)
- Schema applied to wrong instance or cluster

### Resolution

**Step 1 — Connect to RDS and list databases**

```sql
SHOW DATABASES;
```

**Step 2 — Create database if missing**

```sql
CREATE DATABASE IF NOT EXISTS expense_tracker;
USE expense_tracker;
```

**Step 3 — Apply schema**

Run `backend/schema.sql`:

```sql
CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  type ENUM('income','expense') NOT NULL,
  category VARCHAR(100),
  date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Step 4 — Match `DB_NAME` env var exactly**

```bash
-e DB_NAME="expense_tracker"
```

---

## 7. CORS and API URL Mismatch

### Symptoms

- Browser console: `blocked by CORS policy`
- API works in curl but fails in browser
- Requests go to wrong host

### Root Causes

- `VITE_API_URL` does not match the origin users access
- `CORS_ORIGINS` on backend does not include frontend URL
- Frontend image built with wrong `VITE_API_URL`

### Resolution

```bash
# Rebuild frontend with correct ALB URL
docker build \
  --build-arg VITE_API_URL=http://YOUR-ALB-DNS \
  -t your-dockerhub-user/expense-tracker-web:latest .
docker push your-dockerhub-user/expense-tracker-web:latest
```

Backend container:

```bash
-e CORS_ORIGINS="http://YOUR-ALB-DNS"
```

Or leave `CORS_ORIGINS` unset to allow all origins during testing (not recommended for production).

---

## 8. Frontend Shows Connection Error

### Symptoms

- Dashboard displays: _"Could not connect to the server"_
- Network tab shows failed requests to wrong URL

### Root Causes

- `VITE_API_URL` empty or pointing to `localhost` in production build
- ALB not reachable
- Mixed content (HTTPS page calling HTTP API)

### Resolution

1. Inspect built JS — search for API URL in browser dev tools → Sources.
2. Rebuild with correct `--build-arg VITE_API_URL=...`.
3. Refresh frontend ASG instances after push.
4. Ensure ALB security group allows inbound 80/443.

---

## 9. 502 Bad Gateway from ALB

### Symptoms

- ALB returns `502 Bad Gateway`
- Target group shows healthy intermittently

### Root Causes

- Container exited after health check passed
- App listening on `127.0.0.1` only (not `0.0.0.0`)
- Port mapping mismatch (container 4000 vs target group 4000)

### Resolution

```bash
# Confirm app binds to 0.0.0.0
sudo docker logs expense-api | head -20
# Expected: API server listening on 0.0.0.0:4000

# Confirm port mapping
sudo docker port expense-api
# Expected: 4000/tcp -> 0.0.0.0:4000
```

Backend `server.js` must use:

```javascript
app.listen(PORT, '0.0.0.0', () => { ... });
```

---

## 10. Docker Image Pull Failures on EC2

### Symptoms

```
Error response from daemon: pull access denied
net/http: TLS handshake timeout
```

### Root Causes

| Environment | Cause |
|-------------|-------|
| Private subnet backend | No NAT Gateway route |
| Private Docker Hub repo | Missing credentials |
| Typo in image name | Wrong repository path |

### Resolution

**Private subnet instances:**

1. Verify NAT Gateway exists in public subnet.
2. Verify private route table has `0.0.0.0/0` → NAT Gateway.
3. Test outbound connectivity:

```bash
curl -I https://hub.docker.com
```

**Private repos:**

```bash
sudo docker login -u YOUR_USER -p YOUR_TOKEN
sudo docker pull your-dockerhub-user/expense-tracker-api:latest
```

---

## Quick Diagnostic Checklist

```
□  External ALB DNS resolves
□  Target groups healthy (frontend :80, backend :4000)
□  Security groups: ALB → EC2, backend → RDS
□  docker ps shows running containers on EC2
□  curl localhost/health and localhost:4000/health succeed on instances
□  curl ALB-DNS/api/transactions returns JSON
□  RDS database and table exist
□  DB_* env vars set in backend container
□  VITE_API_URL matches ALB DNS in frontend build
□  NAT Gateway route exists for private app subnets
```

---

## Related Documentation

- [aws-setup.md](aws-setup.md) — Full deployment steps
- [security-architecture.md](security-architecture.md) — Network and SG design
- [../README.md](../README.md) — Project overview
