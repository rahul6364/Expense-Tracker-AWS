# AWS Manual Deployment Guide

Step-by-step guide for deploying the Expense Tracker **using the AWS Console** (or CLI). This path is ideal for **learning AWS networking and services** before adopting Infrastructure as Code.

> **Production / portfolio deploy:** Use **[terraform-deployment.md](terraform-deployment.md)** for a single `terraform apply` with zero manual steps after image push.

### When to use this guide

| Use manual setup when… | Use Terraform when… |
|------------------------|---------------------|
| Learning VPC, ALB, RDS concepts | You want repeatable, version-controlled infra |
| Following AWS certification labs | You need one-command full stack deploy |
| Comparing Console steps to IaC | CI/CD or team collaboration on infra |

---

## Relationship to prod (Terraform)

| Step in this guide | Terraform equivalent |
|--------------------|----------------------|
| VPC, subnets, IGW, NAT | `main.tf`, `route_table.tf` |
| Security groups | `security_groups.tf` |
| RDS MySQL | `rds.tf` |
| ALB + listener rules | `alb.tf` |
| Launch templates + user data | `launch_template.tf`, `scripts/*.sh` |
| Auto Scaling Groups | `asg.tf` |
| Schema / `transactions` table | Automatic via `backend/bootstrap.js` (no manual SQL required) |

See [architecture.md](architecture.md) for a side-by-side comparison.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Summary](#architecture-summary)
3. [VPC Setup](#vpc-setup)
4. [Subnet Creation](#subnet-creation)
5. [Route Tables](#route-tables)
6. [NAT Gateway Setup](#nat-gateway-setup)
7. [Security Group Configuration](#security-group-configuration)
8. [RDS Setup](#rds-setup)
9. [Docker Build and Docker Hub Push](#docker-build-and-docker-hub-push)
10. [Launch Template Creation](#launch-template-creation)
11. [Auto Scaling Group Setup](#auto-scaling-group-setup)
12. [ALB and Target Group Configuration](#alb-and-target-group-configuration)
13. [Listener Rules](#listener-rules)
14. [Post-Deployment Verification](#post-deployment-verification)
15. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- AWS account with appropriate IAM permissions
- AWS CLI configured locally (optional but recommended)
- Docker installed locally
- Docker Hub account and repositories created:
  - `your-dockerhub-user/expense-tracker-web`
  - `your-dockerhub-user/expense-tracker-api`
- Domain name (optional — ALB DNS works for demos)

---

## Architecture Summary

| Resource | AZ Coverage | Subnet Type |
|----------|-------------|-------------|
| External ALB | 2 AZs | Public |
| Frontend EC2 ASG | 2 AZs | Public |
| Backend EC2 ASG | 2 AZs | Private (app) |
| RDS MySQL | 2 AZs | Private (db) |
| NAT Gateway | 1 per AZ (recommended) or 1 shared | Public subnet |

Example CIDR layout (`10.0.0.0/16` VPC):

| Subnet | CIDR | AZ | Type |
|--------|------|-----|------|
| public-1a | 10.0.1.0/24 | us-east-1a | Public |
| public-1b | 10.0.2.0/24 | us-east-1b | Public |
| private-app-1a | 10.0.11.0/24 | us-east-1a | Private |
| private-app-1b | 10.0.12.0/24 | us-east-1b | Private |
| private-db-1a | 10.0.21.0/24 | us-east-1a | Private |
| private-db-1b | 10.0.22.0/24 | us-east-1b | Private |

---

## VPC Setup

1. Open **VPC** → **Create VPC**.
2. Choose **VPC and more** (or create manually for learning).
3. Settings:
   - **Name:** `expense-tracker-vpc`
   - **IPv4 CIDR:** `10.0.0.0/16`
   - **AZs:** 2
   - **Public subnets:** 2
   - **Private subnets:** 4 (2 app + 2 db) — or create db subnets manually after
4. If using the wizard, verify an **Internet Gateway** is attached.

### Manual VPC (alternative)

1. Create VPC `10.0.0.0/16`
2. Create and attach Internet Gateway
3. Create subnets per table above

---

## Subnet Creation

Ensure each subnet type is correctly tagged:

| Tag Name | Purpose |
|----------|---------|
| `tier=public` | ALB, frontend EC2, NAT Gateway |
| `tier=private-app` | Backend EC2 ASG |
| `tier=private-db` | RDS only |

**RDS requirement:** Create a **DB subnet group** including both `private-db` subnets before launching RDS.

```
RDS → Subnet groups → Create DB subnet group
  Name: expense-tracker-db-subnet-group
  VPC: expense-tracker-vpc
  Subnets: private-db-1a, private-db-1b
```

---

## Route Tables

### Public Route Table

| Destination | Target |
|-------------|--------|
| `10.0.0.0/16` | local |
| `0.0.0.0/0` | Internet Gateway |

Associate with: `public-1a`, `public-1b`

### Private App Route Table (per AZ recommended)

| Destination | Target |
|-------------|--------|
| `10.0.0.0/16` | local |
| `0.0.0.0/0` | NAT Gateway (in same AZ) |

Associate with: `private-app-1a`, `private-app-1b`

### Private DB Route Table

| Destination | Target |
|-------------|--------|
| `10.0.0.0/16` | local |

No `0.0.0.0/0` route — DB tier has **no internet access**.

Associate with: `private-db-1a`, `private-db-1b`

---

## NAT Gateway Setup

Backend instances in private subnets need outbound internet to pull Docker images from Docker Hub.

1. Allocate **Elastic IP** (one per NAT Gateway).
2. Create **NAT Gateway** in `public-1a` → attach EIP.
3. Repeat for `public-1b` (HA best practice).
4. Update **private app route tables** — each AZ's private subnet routes `0.0.0.0/0` to its local NAT.

> **FinOps note:** A single NAT Gateway reduces cost but creates cross-AZ traffic charges if backends in AZ-b use NAT in AZ-a.

---

## Security Group Configuration

Create four security groups in the VPC.

### 1. `sg-alb-external`

| Type | Port | Source | Description |
|------|------|--------|-------------|
| Inbound HTTP | 80 | `0.0.0.0/0` | Public web traffic |
| Inbound HTTPS | 443 | `0.0.0.0/0` | TLS (when ACM added) |
| Outbound | All | `0.0.0.0/0` | To frontend/backend targets |

### 2. `sg-frontend-ec2`

| Type | Port | Source | Description |
|------|------|--------|-------------|
| Inbound HTTP | 80 | `sg-alb-external` | ALB to nginx only |
| Outbound | All | `0.0.0.0/0` | Updates, Docker Hub |

### 3. `sg-backend-ec2`

| Type | Port | Source | Description |
|------|------|--------|-------------|
| Inbound Custom TCP | 4000 | `sg-alb-external` | ALB path rule to API |
| Outbound Custom TCP | 3306 | `sg-rds` | MySQL to RDS only |
| Outbound HTTPS | 443 | `0.0.0.0/0` | Docker Hub pulls via NAT |

### 4. `sg-rds`

| Type | Port | Source | Description |
|------|------|--------|-------------|
| Inbound MySQL | 3306 | `sg-backend-ec2` | App tier only |
| Outbound | None required | — | — |

> **Important:** Do not allow `0.0.0.0/0` on backend or RDS security groups.

---

## RDS Setup

1. **RDS** → **Create database**
2. Engine: **MySQL 8.0**
3. Template: Free tier (or Dev/Test)
4. Settings:
   - DB identifier: `expense-tracker-db`
   - Master username / password: store securely
5. Instance: `db.t3.micro` (adjust for production)
6. Storage: default gp3
7. Connectivity:
   - VPC: `expense-tracker-vpc`
   - Subnet group: `expense-tracker-db-subnet-group`
   - **Public access: No**
   - Security group: `sg-rds`
8. Initial database name: `expense_tracker`

### Apply Schema

**Recommended:** Use the backend image that includes `bootstrap.js`. On first container start, the API connects to RDS and creates the `transactions` table if it does not exist. No manual SQL is required for normal deployments.

**Optional (manual / debugging):** Connect from a bastion, Cloud9, or RDS Query Editor and run `backend/schema.sql`, or execute:

```sql
USE expense_tracker;
-- See backend/schema.sql for full DDL
```

Record the **RDS endpoint** — required for backend environment variables (or passed via Terraform user data on prod).

---

## Docker Build and Docker Hub Push

### 1. Build Images Locally

```bash
# Backend
cd backend
docker build -t your-dockerhub-user/expense-tracker-api:latest .

# Frontend — set VITE_API_URL to your External ALB DNS (update after ALB creation if needed)
cd ../frontend
docker build \
  --build-arg VITE_API_URL=http://YOUR-EXTERNAL-ALB-DNS \
  -t your-dockerhub-user/expense-tracker-web:latest .
```

### 2. Push to Docker Hub

```bash
docker login
docker push your-dockerhub-user/expense-tracker-api:latest
docker push your-dockerhub-user/expense-tracker-web:latest
```

### 3. EC2 Pull Authentication

For private Docker Hub repos, store credentials in **AWS Systems Manager Parameter Store** and reference them in user data. Public repos can pull without auth.

---

## Launch Template Creation

Use Amazon Linux 2023 with Docker pre-installed, or install Docker via user data.

### Backend Launch Template

| Setting | Value |
|---------|-------|
| Name | `lt-expense-tracker-backend` |
| AMI | Amazon Linux 2023 |
| Instance type | t3.micro |
| Subnet | Private app (via ASG) |
| Security group | `sg-backend-ec2` |
| IAM role | Optional — SSM access for debugging |

**User data script (example):**

```bash
#!/bin/bash
set -e

# Install Docker
dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Pull and run backend container
docker pull your-dockerhub-user/expense-tracker-api:latest
docker run -d \
  --name expense-api \
  --restart unless-stopped \
  -p 4000:4000 \
  -e DB_HOST="YOUR_RDS_ENDPOINT" \
  -e DB_USER="admin" \
  -e DB_PASS="YOUR_PASSWORD" \
  -e DB_NAME="expense_tracker" \
  -e DB_PORT="3306" \
  -e PORT="4000" \
  -e CORS_ORIGINS="http://YOUR-EXTERNAL-ALB-DNS" \
  your-dockerhub-user/expense-tracker-api:latest
```

> Store secrets in **Parameter Store** or **Secrets Manager** and fetch in user data for production.

### Frontend Launch Template

| Setting | Value |
|---------|-------|
| Name | `lt-expense-tracker-frontend` |
| Instance type | t3.micro |
| Security group | `sg-frontend-ec2` |

**User data script (example):**

```bash
#!/bin/bash
set -e

dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker

docker pull your-dockerhub-user/expense-tracker-web:latest
docker run -d \
  --name expense-web \
  --restart unless-stopped \
  -p 80:80 \
  your-dockerhub-user/expense-tracker-web:latest
```

---

## Auto Scaling Group Setup

### Frontend ASG

| Setting | Value |
|---------|-------|
| Name | `asg-expense-tracker-frontend` |
| Launch template | `lt-expense-tracker-frontend` |
| VPC zones | public-1a, public-1b |
| Load balancing | Attach to frontend target group |
| Health check type | ELB |
| Desired / Min / Max | 2 / 1 / 4 |

### Backend ASG

| Setting | Value |
|---------|-------|
| Name | `asg-expense-tracker-backend` |
| Launch template | `lt-expense-tracker-backend` |
| VPC zones | private-app-1a, private-app-1b |
| Load balancing | Attach to backend target group |
| Health check type | ELB |
| Desired / Min / Max | 2 / 1 / 4 |

---

## ALB and Target Group Configuration

### Create External Application Load Balancer

| Setting | Value |
|---------|-------|
| Name | `alb-expense-tracker-external` |
| Scheme | Internet-facing |
| IP address type | IPv4 |
| VPC | expense-tracker-vpc |
| Subnets | public-1a, public-1b |
| Security group | sg-alb-external |

### Target Group: Frontend

| Setting | Value |
|---------|-------|
| Name | `tg-expense-tracker-frontend` |
| Target type | Instances |
| Protocol / Port | HTTP / 80 |
| VPC | expense-tracker-vpc |
| Health check path | `/health` |
| Healthy threshold | 2 |
| Interval | 30s |
| Success codes | 200 |

Register **frontend ASG** with this target group.

### Target Group: Backend

| Setting | Value |
|---------|-------|
| Name | `tg-expense-tracker-backend` |
| Protocol / Port | HTTP / 4000 |
| Health check path | `/health` |
| Success codes | 200 |

Register **backend ASG** with this target group.

---

## Listener Rules

### HTTP Listener (Port 80)

| Priority | Condition | Action |
|----------|-----------|--------|
| 1 | Path pattern `/api/*` | Forward to `tg-expense-tracker-backend` |
| 2 | Path pattern `/health` | Forward to `tg-expense-tracker-backend` _(if API health used at root)_ |
| Default | No rule match | Forward to `tg-expense-tracker-frontend` |

### HTTPS Listener (Optional — Recommended)

1. Request certificate in **ACM** for your domain.
2. Add HTTPS listener on port 443 with ACM certificate.
3. Redirect HTTP → HTTPS.

### Rebuild Frontend with Correct API URL

After ALB DNS is known:

```bash
cd frontend
docker build \
  --build-arg VITE_API_URL=http://alb-expense-tracker-xxxxx.us-east-1.elb.amazonaws.com \
  -t your-dockerhub-user/expense-tracker-web:latest .
docker push your-dockerhub-user/expense-tracker-web:latest
```

Trigger an **instance refresh** on the frontend ASG to pull the new image.

---

## Post-Deployment Verification

```bash
# Frontend health (via ALB)
curl http://YOUR-ALB-DNS/health
# Expected: ok

# Backend health (via ALB path)
curl http://YOUR-ALB-DNS/health
# Expected: {"status":"ok"}  (if routed to backend)

# API
curl http://YOUR-ALB-DNS/api/transactions
# Expected: [] or JSON array
```

Open `http://YOUR-ALB-DNS` in a browser and verify the dashboard loads and transactions can be created.

---

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for detailed issue resolution.

| Symptom | Quick Check |
|---------|-------------|
| Target group unhealthy | Security groups, health path, container running |
| 502 Bad Gateway | Backend container not listening on 4000 |
| Empty API / CORS error | `VITE_API_URL` and `CORS_ORIGINS` mismatch |
| DB connection refused | RDS SG, endpoint, credentials in user data |

---

## Next Steps

- Migrate to IaC: [terraform-deployment.md](terraform-deployment.md)
- Enable HTTPS with ACM on the ALB
- Move secrets to AWS Secrets Manager
- Add CloudWatch alarms for unhealthy hosts
- See [README.md](README.md) for screenshot checklist and portfolio tips
