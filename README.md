# Expense Tracker — Production 3-Tier AWS Deployment

[React](https://react.dev/)
[Node.js](https://nodejs.org/)
[Express](https://expressjs.com/)
[MySQL](https://aws.amazon.com/rds/)
[Docker](https://hub.docker.com/)
[AWS](https://aws.amazon.com/)
[Terraform](https://www.terraform.io/)
[Nginx](https://nginx.org/)
[Tailwind CSS](https://tailwindcss.com/)

A production-style, full-stack expense tracker engineered for **high availability**, **network isolation**, and **cost-aware** AWS infrastructure. The application is split into independently scalable Web, App, and Database tiers, each deployed with Docker on EC2 Auto Scaling Groups behind an Application Load Balancer. Infrastructure is provisioned with **Terraform**; the backend **bootstraps the database schema on startup** — no manual `CREATE TABLE` on RDS.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [AWS Services Used](#aws-services-used)
- [Features](#features)
- [Database Bootstrap](#database-bootstrap)
- [Security Architecture](#security-architecture)
- [FinOps Decisions](#finops-decisions)
- [Deployment Architecture](#deployment-architecture)
- [Deploy with Terraform](#deploy-with-terraform)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Quick Start (Local)](#quick-start-local)
- [Documentation](#documentation)
- [API Reference](#api-reference)
- [Screenshots & Diagrams](#screenshots--diagrams)
- [Resume-Ready Highlights](#resume-ready-highlights)
- [Future Improvements](#future-improvements)
- [License](#license)

---

## Project Overview

This project demonstrates end-to-end **DevOps and cloud engineering** skills by taking a monolithic container and refactoring it into a **true 3-tier architecture** suitable for AWS production workloads.

| Tier         | Component                       | Hosting                                |
| ------------ | ------------------------------- | -------------------------------------- |
| **Web**      | React + Vite + Tailwind + nginx | Public subnets, External ALB           |
| **App**      | Node.js + Express REST API      | Private app subnets, no public IP      |
| **Database** | Amazon RDS for MySQL            | Private DB subnets, no internet access |

Users access the React frontend through an **External Application Load Balancer**. API traffic is routed via **path-based listener rules** (`/api/*`) to backend instances in private subnets. The backend connects exclusively to **RDS MySQL** using environment-based credentials — no embedded database, no localhost fallbacks.

---

## Architecture

### High-Level Flow

```
                         ┌─────────────────────────────────────────┐
                         │              Internet                   │
                         └────────────────────┬────────────────────┘
                                              │
                                              ▼
                         ┌─────────────────────────────────────────┐
                         │     External ALB (Public Subnets)       │
                         │  Listener Rules:                        │
                         │    /api/*  → Backend Target Group       │
                         │    /*      → Frontend Target Group      │
                         └──────────────┬──────────────┬───────────┘
                                        │              │
                    ┌───────────────────┘              └───────────────────┐
                    ▼                                                        ▼
     ┌──────────────────────────┐                         ┌──────────────────────────┐
     │  Frontend EC2 ASG        │                         │  Backend EC2 ASG         │
     │  (Public Subnets)        │                         │  (Private App Subnets)   │
     │  Docker: nginx + React   │                         │  Docker: Express API     │
     │  Port 80                 │                         │  Port 4000               │
     └──────────────────────────┘                         └────────────┬─────────────┘
                                                                         │
                                                                         ▼
                                                         ┌──────────────────────────┐
                                                         │  Amazon RDS MySQL        │
                                                         │  (Private DB Subnets)    │
                                                         │  Port 3306               │
                                                         │  Schema auto-created     │
                                                         │  on backend startup      │
                                                         └──────────────────────────┘

     Private subnets reach Docker Hub / updates via NAT Gateway
```

### Architecture Diagram (Placeholder)

> *Add your exported architecture diagram here.*

```
docs/images/architecture-diagram.png
```

Recommended tools: draw.io, Lucidchart, or AWS Architecture Icons.

---

## AWS Services Used

| Service                       | Purpose                                                         |
| ----------------------------- | --------------------------------------------------------------- |
| **Amazon VPC**                | Isolated network with public and private subnets across 2 AZs   |
| **Subnets**                   | Public (ALB, frontend), private app (backend), private DB (RDS) |
| **Internet Gateway**          | Inbound/outbound traffic for public subnets                     |
| **NAT Gateway**               | Outbound internet for private subnets (Docker pulls, updates)   |
| **Route Tables**              | Public vs private routing (IGW / NAT)                           |
| **Security Groups**           | Stateful, least-privilege tier-to-tier communication            |
| **Application Load Balancer** | External ALB with path-based routing and health checks          |
| **Target Groups**             | Separate groups for frontend (`:80`) and backend (`:4000`)      |
| **EC2 Auto Scaling Groups**   | Independent scaling for web and app tiers                       |
| **Launch Templates**          | AMI + user data for Docker deployment                           |
| **Amazon RDS (MySQL)**        | Managed database in private DB subnets                          |
| **Docker Hub**                | Container images for frontend and backend                       |

---

## Features

### Application

- Dashboard with total balance, income, and expense summary cards
- Add transactions (title, amount, type, category, date)
- Filterable transaction list with income/expense color coding
- 6-month spending bar chart (Recharts)
- Dark-themed UI with glassmorphism and responsive layout

### Infrastructure

- **Terraform IaC** — VPC, subnets, NAT, ALB, ASGs, RDS, security groups
- **Decoupled tiers** — separate Docker images, ASGs, and security groups
- **Path-based ALB routing** — single entry point for UI and API
- **Health checks** — `GET /health` on both frontend and backend
- **Environment-driven config** — `VITE_API_URL`, RDS credentials via env vars
- **Multi-AZ resilience** — subnets and ASGs span two Availability Zones
- **Private backend and database** — no direct internet exposure

### Operations

- **Automatic database bootstrap** — `transactions` table created on first backend startup if missing
- **Fail-fast startup** — API does not listen until DB connectivity and schema check succeed

---

## Database Bootstrap

On every backend startup, `bootstrap.js` runs **before** the HTTP server accepts traffic:

1. Connect to MySQL (RDS) and ping the pool.
2. Check `information_schema` for the `transactions` table.
3. If missing, run `CREATE TABLE IF NOT EXISTS` with the application schema.
4. Start Express normally.

**Expected startup logs:**

```
Database connected successfully.
Transactions table verified.          # existing deployments
API server listening on 0.0.0.0:4000
```

Or on a fresh RDS instance:

```
Database connected successfully.
Transactions table created.
API server listening on 0.0.0.0:4000
```

`backend/schema.sql` remains as a reference for local MySQL or manual troubleshooting; production deploys do not require running it by hand.

For versioned schema evolution (columns, indexes, rollbacks), consider Flyway or Liquibase in a future iteration — app bootstrap is ideal for initial table creation only.

---

## Security Architecture

Defense-in-depth is applied at every layer. See [docs/security-architecture.md](docs/security-architecture.md) for the full breakdown.

| Layer               | Control                                                            |
| ------------------- | ------------------------------------------------------------------ |
| **Network**         | Backend and RDS in private subnets; no public IPs on app/DB tier   |
| **Security Groups** | ALB → EC2 only on required ports; backend → RDS on `3306` only     |
| **Database**        | RDS not publicly accessible; credentials via environment variables |
| **Application**     | CORS restricted via `CORS_ORIGINS`; no hardcoded secrets in images |
| **Containers**      | Backend runs as non-root `node` user inside Alpine image           |

---

## FinOps Decisions

Cost optimization was considered alongside reliability for a portfolio / learning environment.

| Decision                          | Rationale                                                     |
| --------------------------------- | ------------------------------------------------------------- |
| **t3.micro / t3.small EC2**       | Sufficient for demo workloads; easy to right-size later       |
| **Single NAT Gateway**            | One NAT saves ~$32/mo vs one per AZ; acceptable for labs      |
| **RDS db.t3.micro**               | Managed MySQL without self-hosting DB on EC2                  |
| **Docker Hub (free tier)**        | Simple image hosting without ECR storage/transfer costs       |
| **ALB over NLB**                  | Path-based HTTP routing; NLB unnecessary for this HTTP app    |
| **Separate ASGs**                 | Scale frontend and backend independently under real load      |
| **No ECS/Fargate (initially)**    | EC2 + Docker teaches launch templates and ASG fundamentals    |

> **Tip:** Stop non-production RDS instances and scale ASGs to zero during idle periods to reduce monthly spend.

---

## Deployment Architecture

| Component        | Subnet Type   | Port     | Image Source                              |
| ---------------- | ------------- | -------- | ----------------------------------------- |
| External ALB     | Public        | 80 / 443 | —                                         |
| Frontend EC2 ASG | Public        | 80       | `rahul6364/expense-tracker-web:latest`    |
| Backend EC2 ASG  | Private (app) | 4000     | `rahul6364/expense-tracker-api:latest`    |
| RDS MySQL        | Private (db)  | 3306     | —                                         |

### ALB Listener Rules (Path-Based Routing)

| Priority | Condition        | Target Group             |
| -------- | ---------------- | ------------------------ |
| 1        | Path is `/api/*` | `backend-tg` (port 4000) |
| Default  | `/*`             | `frontend-tg` (port 80)  |

### Environment Variables

**Frontend** (build-time):

```bash
VITE_API_URL=https://your-external-alb-dns.amazonaws.com
```

**Backend** (runtime on EC2):

```bash
DB_HOST=<rds-endpoint>
DB_USER=<username>
DB_PASS=<password>
DB_NAME=expense_tracker
DB_PORT=3306
PORT=4000
CORS_ORIGINS=https://your-external-alb-dns.amazonaws.com
```

Console-based walkthrough: [docs/aws-setup.md](docs/aws-setup.md)

---

## Deploy with Terraform

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) 1.x
- AWS CLI configured (`aws configure`) with permissions for VPC, EC2, ALB, RDS, IAM
- Docker images pushed to Docker Hub (or update image names in launch templates / user data)

### Configure variables

Create `terraform/terraform.tfvars` (gitignored — never commit secrets):

```hcl
project_name = "expense-tracker"
vpc_cidr     = "10.0.0.0/16"

web_public_subnet_az1_cidr  = "10.0.1.0/24"
web_public_subnet_az2_cidr  = "10.0.2.0/24"
app_private_subnet_az1_cidr = "10.0.3.0/24"
app_private_subnet_az2_cidr = "10.0.4.0/24"
db_private_subnet_az1_cidr  = "10.0.5.0/24"
db_private_subnet_az2_cidr  = "10.0.6.0/24"

region              = "us-east-1"
availability_zone_1 = "us-east-1a"
availability_zone_2 = "us-east-1b"

db_user     = "admin"
db_password = "CHANGE_ME_STRONG_PASSWORD"
```

### Apply infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Useful output after apply:

```bash
terraform output rds_endpoint
```

### Deploy application code changes

After changing the backend (e.g. bootstrap logic):

```bash
cd backend
docker build -t rahul6364/expense-tracker-api:latest .
docker push rahul6364/expense-tracker-api:latest
```

Refresh backend instances (replace with your ASG name from Terraform):

```bash
aws autoscaling start-instance-refresh --auto-scaling-group-name <backend-asg-name>
```

Or terminate backend instances so the ASG launches new ones with the updated image.

---

## Tech Stack

| Layer          | Technologies                                                   |
| -------------- | -------------------------------------------------------------- |
| **Frontend**   | React 18, Vite, Tailwind CSS, Recharts, Lucide Icons, nginx    |
| **Backend**    | Node.js 18, Express, mysql2, CORS, startup schema bootstrap    |
| **Database**   | Amazon RDS for MySQL 8.x                                       |
| **Containers** | Docker, Docker Hub, multi-stage builds                         |
| **Cloud**      | VPC, ALB, EC2 ASG, NAT Gateway, Security Groups, RDS           |
| **IaC**        | Terraform (AWS provider ~> 6.0)                                |

---

## Repository Structure

```
threeTier/
├── frontend/                 # Web tier
│   ├── Dockerfile            # Multi-stage: Node build → nginx:alpine
│   ├── nginx.conf            # SPA + /health for ALB
│   └── src/
├── backend/                  # App tier
│   ├── Dockerfile            # Node 18 Alpine, non-root
│   ├── server.js             # Express API + startup orchestration
│   ├── db.js                 # MySQL connection pool
│   ├── bootstrap.js          # RDS schema bootstrap on startup
│   └── schema.sql            # Reference DDL (optional for local dev)
├── terraform/                # AWS infrastructure
│   ├── main.tf               # VPC, subnets
│   ├── route_table.tf        # IGW, NAT, route tables
│   ├── security_groups.tf
│   ├── alb.tf
│   ├── asg.tf
│   ├── launch_template.tf
│   ├── rds.tf
│   ├── iam.tf
│   ├── scripts/              # EC2 user data (Docker pull/run)
│   └── terraform.tfvars      # Local only (gitignored)
├── docs/
│   ├── aws-setup.md
│   ├── security-architecture.md
│   └── troubleshooting.md
└── README.md
```

---

## Quick Start (Local)

### Prerequisites

- Node.js 18+
- npm
- MySQL 8.x (local instance with database `expense_tracker` created)

### Backend

```bash
cd backend
# Create .env with DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT
npm install
npm run dev
```

The API bootstraps the `transactions` table automatically — you do not need to run `schema.sql` unless you prefer manual setup.

Health check: [http://localhost:4000/health](http://localhost:4000/health)

### Frontend

```bash
cd frontend
# VITE_API_URL=http://localhost:4000
npm install
npm run dev
```

App: [http://localhost:5173](http://localhost:5173)

### Build Docker Images Locally

```bash
# Backend
cd backend && docker build -t expense-tracker-api .

# Frontend
cd frontend && docker build \
  --build-arg VITE_API_URL=http://localhost:4000 \
  -t expense-tracker-web .
```

---

## Documentation

| Document                                                       | Description                                 |
| -------------------------------------------------------------- | ------------------------------------------- |
| [docs/aws-setup.md](docs/aws-setup.md)                         | Full AWS deployment guide — VPC through ALB |
| [docs/security-architecture.md](docs/security-architecture.md) | Traffic flow, SG rules, subnet isolation    |
| [docs/troubleshooting.md](docs/troubleshooting.md)             | Common deployment issues and fixes          |

---

## API Reference

| Method   | Endpoint                | Description                                 |
| -------- | ----------------------- | ------------------------------------------- |
| `GET`    | `/health`               | Backend health check — `{ "status": "ok" }` |
| `GET`    | `/api/transactions`     | List all transactions                       |
| `POST`   | `/api/transactions`     | Create a transaction                        |
| `DELETE` | `/api/transactions/:id` | Delete a transaction                        |

---

## Screenshots & Diagrams

> *Replace placeholders with your own assets before publishing to GitHub.*

### Application UI

| Dashboard                         | Transaction List                     | Spending Chart                |
| --------------------------------- | ------------------------------------ | ----------------------------- |
| *Add `docs/images/dashboard.png`* | *Add `docs/images/transactions.png`* | *Add `docs/images/chart.png`* |

### AWS Console

| VPC & Subnets               | ALB Target Groups              | RDS Instance                |
| --------------------------- | ------------------------------ | --------------------------- |
| *Add `docs/images/vpc.png`* | *Add `docs/images/alb-tg.png`* | *Add `docs/images/rds.png`* |

### Network Diagram

```
docs/images/architecture-diagram.png   ← Full 3-tier diagram
docs/images/security-groups.png        ← SG rule matrix (optional)
```

---

## Resume-Ready Highlights

Use these bullet points on your resume or in interviews:

- Designed and deployed a **production-style 3-tier architecture** on AWS (Web / App / Database) with **path-based ALB routing** and **Auto Scaling Groups** across **2 Availability Zones**
- Provisioned infrastructure with **Terraform** (VPC, NAT, ALB, ASG, RDS, security groups) for repeatable environments
- Implemented **automatic database bootstrap** on backend startup so RDS requires zero manual schema setup
- Refactored a monolithic Docker container into **independently scalable frontend and backend services**, published to **Docker Hub** and deployed on EC2
- Implemented **VPC network segmentation** with public and private subnets, **NAT Gateway**, and **least-privilege Security Groups**
- Configured **ALB health checks**, launch templates, and **environment-driven** configuration (`VITE_API_URL`, RDS credentials)
- Built a responsive **React + Tailwind** dashboard with REST API integration and containerized **nginx** static delivery

---

## Future Improvements

- **CI/CD pipeline** — GitHub Actions to build, test, push Docker images, and run `terraform plan`
- **Schema migrations** — Flyway or Liquibase for versioned DDL beyond initial bootstrap
- **HTTPS / ACM** — TLS certificate on External ALB
- **AWS Secrets Manager** — rotate RDS credentials without redeploying EC2
- **CloudWatch** — centralized logs, metrics, and alarms for ASG / ALB / RDS
- **WAF** — rate limiting and OWASP rule sets on External ALB
- **Multi-AZ RDS** — enable automatic failover for database HA
- **Private Docker registry** — migrate from Docker Hub to ECR with IAM-scoped pulls

---

## License

This project is open source and available for portfolio and educational use. Add your preferred license (e.g., MIT) here.

---

## Author

- GitHub: [@rahul6364](https://github.com/rahul6364)
