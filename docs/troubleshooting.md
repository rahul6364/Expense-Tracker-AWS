# Troubleshooting Guide

Common issues for the Expense Tracker AWS deployment (Terraform or manual). Each section lists **symptoms**, **root causes**, and **resolution steps**.

---

## Table of Contents

1. [Quick diagnostic checklist](#quick-diagnostic-checklist)
2. [Unknown database error](#unknown-database-error)
3. [Missing table error](#missing-table-error)
4. [ALB 502 errors](#alb-502-errors)
5. [Unhealthy target groups](#unhealthy-target-groups)
6. [Docker image pull failures](#docker-image-pull-failures)
7. [RDS connectivity issues](#rds-connectivity-issues)
8. [CORS and API URL mismatch](#cors-and-api-url-mismatch)
9. [Terraform-specific checks](#terraform-specific-checks)

---

## Quick diagnostic checklist

```
□  terraform output application_url resolves (or ALB DNS in Console)
□  Target groups frontend-tg (:80) and backend-tg (:4000) show healthy
□  Security groups: alb-sg → frontend/backend; backend-sg → rds-sg :3306
□  sudo docker ps shows frontend and backend containers on EC2
□  curl http://<ALB>/api/transactions returns JSON (not 502/HTML error)
□  RDS database expense_tracker exists
□  docker logs backend shows bootstrap success
□  Private app subnets route 0.0.0.0/0 → NAT Gateway
□  Docker images exist on Docker Hub with correct tags
```

![ALB healthy targets](images/alb-healthy.png)

---

## Unknown database error

### Symptoms

```
Error: Unknown database 'expense_tracker'
ER_BAD_DB_ERROR: Unknown database
```

API returns 500; `docker logs backend` shows MySQL errors.

### Root causes

| Cause | Details |
|-------|---------|
| Wrong `DB_NAME` | Typo in user data or env (case-sensitive) |
| RDS `db_name` not set | Terraform/manual RDS must create `expense_tracker` |
| Wrong RDS endpoint | Stale `DB_HOST` after rebuild |

### Resolution

**Step 1 — Confirm RDS database name**

Terraform sets `db_name = "expense_tracker"` in `rds.tf`. In RDS Console → Configuration → DB name should be `expense_tracker`.

**Step 2 — Match backend environment**

On backend instance:

```bash
sudo docker inspect backend --format '{{range .Config.Env}}{{println .}}{{end}}' | grep DB_
```

Expected:

```
DB_HOST=<rds-endpoint>.region.rds.amazonaws.com
DB_NAME=expense_tracker
DB_PORT=3306
```

**Step 3 — Recreate backend with correct vars**

If wrong, fix `terraform/scripts/backend.sh` / user data and refresh ASG:

```bash
aws autoscaling start-instance-refresh --auto-scaling-group-name backend-asg
```

**Step 4 — Optional manual create (debug only)**

```sql
CREATE DATABASE IF NOT EXISTS expense_tracker;
```

---

## Missing table error

### Symptoms

```
Table 'expense_tracker.transactions' doesn't exist
ER_NO_SUCH_TABLE
```

`GET /api/transactions` returns 500.

### Root causes

| Cause | Details |
|-------|---------|
| Old backend image | Image without `bootstrap.js` |
| Bootstrap failed | RDS not ready on first container start |
| Bootstrap never ran | Container crashed before `start()` |

### Resolution

**Step 1 — Check backend logs**

```bash
sudo docker logs backend
```

**Success looks like:**

```
Database connected successfully.
Transactions table verified.
```
or
```
Transactions table created.
```

**Step 2 — Rebuild and push API image with bootstrap**

```bash
cd backend
docker build -t rahul6364/expense-tracker-api:latest .
docker push rahul6364/expense-tracker-api:latest
```

**Step 3 — Replace backend instance**

```bash
aws autoscaling start-instance-refresh --auto-scaling-group-name backend-asg
```

**Step 4 — Manual fallback (debug only)**

Run `backend/schema.sql` in RDS Query Editor or mysql client.

---

## ALB 502 errors

### Symptoms

- Browser shows `502 Bad Gateway`
- ALB returns 502 for `/api/*` or entire site

### Root causes

| Cause | Tier |
|-------|------|
| No healthy targets | Both |
| Backend crashed (DB error, missing env) | Backend |
| Container not listening on `0.0.0.0` | Backend |
| Wrong target group port | Backend (must be 4000) |
| Security group blocks ALB → EC2 | Both |

### Resolution

**Step 1 — Check target health**

EC2 → Target Groups → Targets. If **unhealthy**, see [Unhealthy target groups](#unhealthy-target-groups).

**Step 2 — Test on instance**

SSM into backend instance:

```bash
curl -i http://localhost:4000/health
# Expect HTTP 200 {"status":"ok"}

sudo docker ps
sudo docker logs backend --tail 100
```

**Step 3 — Verify listener rule**

ALB → Listeners → Rules: `/api/*` → `backend-tg`.

**Step 4 — Security groups**

`backend-sg` must allow inbound **4000** from `alb-sg`.

---

## Unhealthy target groups

### Symptoms

- Target state **unhealthy**
- `503 Service Temporarily Unavailable`
- ASG keeps replacing instances

### Root causes

| Cause | Target group |
|-------|----------------|
| User data still running (Docker install/pull) | Both |
| Wrong health check path | frontend `/`, backend `/health` |
| Container not started | Both |
| Health check grace period too short | Both |
| SG blocks ALB traffic | Both |

### Resolution

**Step 1 — Confirm health check settings**

| Target group | Port | Path | Matcher |
|--------------|------|------|---------|
| frontend-tg | 80 | `/` | 200 |
| backend-tg | 4000 | `/health` | 200 |

**Step 2 — Test locally on instance**

```bash
# Frontend
curl -i http://localhost/
curl -i http://localhost/health

# Backend
curl -i http://localhost:4000/health
```

**Step 3 — Inspect user data progress**

```bash
sudo tail -f /var/log/cloud-init-output.log
sudo docker ps -a
```

**Step 4 — Wait on first deploy**

First boot: apt + Docker install + image pull can take **5–10 minutes**. Wait before marking failure.

**Step 5 — Security groups**

- `frontend-sg`: port 80 from `alb-sg`
- `backend-sg`: port 4000 from `alb-sg`

![ALB overview](images/alb-overview.png)

---

## Docker image pull failures

### Symptoms

```
Error response from daemon: pull access denied
manifest unknown
```

`docker ps` empty; cloud-init log shows pull errors.

### Root causes

| Cause | Fix |
|-------|-----|
| Image not pushed to Docker Hub | Build and push before `terraform apply` |
| Wrong image name in user data | Match `scripts/frontend.sh` / `backend.sh` |
| Private repo without login | `docker login` in user data (not in current scripts) |
| Rate limit (Docker Hub) | Retry or use authenticated pull |

### Resolution

**Step 1 — Verify images exist**

```bash
docker pull rahul6364/expense-tracker-api:latest
docker pull rahul6364/expense-tracker-web:latest
```

**Step 2 — On instance**

```bash
sudo docker pull rahul6364/expense-tracker-api:latest
sudo docker run -d --name backend -p 4000:4000 \
  -e DB_HOST=... -e DB_USER=... -e DB_PASS=... \
  -e DB_NAME=expense_tracker -e DB_PORT=3306 \
  rahul6364/expense-tracker-api:latest
```

**Step 3 — NAT / internet**

Private subnets need NAT route for Docker Hub egress:

```bash
# From instance
curl -I https://hub.docker.com
```

If fails, check private route table → NAT Gateway in public subnet.

---

## RDS connectivity issues

### Symptoms

```
ECONNREFUSED
ETIMEDOUT
Access denied for user
```

Backend logs show database connection errors at startup.

### Root causes

| Cause | Details |
|-------|---------|
| RDS still creating | 10+ minutes on first apply |
| Wrong SG | `rds-sg` must allow 3306 from `backend-sg` |
| Wrong endpoint | `DB_HOST` must be RDS address, not localhost |
| Wrong password | Mismatch vs `terraform.tfvars` |
| Backend in wrong subnet | Must reach RDS in VPC (same VPC) |

### Resolution

**Step 1 — RDS status**

RDS Console → `expense-tracker-db` → **Available**.

**Step 2 — Endpoint**

```bash
terraform output rds_endpoint
```

Compare to `DB_HOST` in container env.

**Step 3 — Security group**

RDS SG inbound: MySQL 3306, source = backend security group.

**Step 4 — Test from backend instance**

```bash
sudo apt install mysql-client -y
mysql -h <rds-endpoint> -u admin -p expense_tracker
```

**Step 5 — Boot order**

If API started before RDS was available, restart container or refresh ASG instance.

---

## CORS and API URL mismatch

### Symptoms

- Browser console: CORS blocked
- Network tab shows API calls to wrong host
- Frontend loads but transactions fail

### Root causes

| Cause | Fix |
|-------|-----|
| `VITE_API_URL` points to wrong host | Rebuild frontend with empty or ALB URL |
| `CORS_ORIGINS` blocks ALB origin | Set `CORS_ORIGINS` or leave unset (allows all when empty) |

### Resolution

**Recommended for ALB path routing:**

```bash
docker build --build-arg VITE_API_URL= -t rahul6364/expense-tracker-web:latest .
```

Browser calls `http://<alb>/api/...` on same origin.

**Optional explicit URL:**

```bash
docker build --build-arg VITE_API_URL=http://YOUR-ALB-DNS -t ...
```

Set backend `CORS_ORIGINS=http://YOUR-ALB-DNS` in user data if restricting CORS.

---

## Terraform-specific checks

| Check | Command |
|-------|---------|
| Valid config | `terraform validate` |
| Outputs | `terraform output application_url` |
| State drift | `terraform plan` (no unexpected changes) |
| User data vars | `db_password` in tfvars matches RDS |
| ASG names | `frontend-asg`, `backend-asg` |

**First deploy:** Wait 15 minutes before deep debugging.

Full deploy guide: [terraform-deployment.md](terraform-deployment.md)

---

## Related documentation

- [terraform-deployment.md](terraform-deployment.md)
- [architecture.md](architecture.md)
- [aws-setup.md](aws-setup.md)
- [README.md](README.md) — Screenshot checklist
