# Expense Tracker — Production 3-Tier AWS Deployment

[React](https://react.dev/)
[Node.js](https://nodejs.org/)
[Express](https://expressjs.com/)
[MySQL](https://aws.amazon.com/rds/)
[Docker](https://hub.docker.com/)
[AWS](https://aws.amazon.com/)
[Nginx](https://nginx.org/)
[Tailwind CSS](https://tailwindcss.com/)

A production-style, full-stack expense tracker engineered for **high availability**, **network isolation**, and **cost-aware** AWS infrastructure. The application is split into independently scalable Web, App, and Database tiers, each deployed with Docker on EC2 Auto Scaling Groups behind Application Load Balancers.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [AWS Services Used](#aws-services-used)
- [Features](#features)
- [Security Architecture](#security-architecture)
- [FinOps Decisions](#finops-decisions)
- [Deployment Architecture](#deployment-architecture)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Quick Start (Local)](#quick-start-local)
- [Documentation](#documentation)
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


Users access the React frontend through an **External Application Load Balancer**. API traffic is routed via **path-based listener rules** (`/api/`*) to backend instances in private subnets. The backend connects exclusively to **RDS MySQL** using environment-based credentials — no embedded database, no localhost fallbacks.

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
                                                         └──────────────────────────┘

     Private subnets reach Docker Hub / updates via NAT Gateway (per AZ)
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
| **Route Tables**              | AZ-specific routing for public vs private traffic               |
| **Security Groups**           | Stateful, least-privilege tier-to-tier communication            |
| **Application Load Balancer** | External ALB with path-based routing and health checks          |
| **Target Groups**             | Separate groups for frontend (`:80`) and backend (`:4000`)      |
| **EC2 Auto Scaling Groups**   | Independent scaling for web and app tiers                       |
| **Launch Templates**          | Standardized AMI + user data for Docker deployment              |
| **Amazon RDS (MySQL)**        | Managed, Multi-AZ-ready database in private DB subnets          |
| **Docker Hub**                | Container image registry for frontend and backend images        |


---

## Features

### Application

- Dashboard with total balance, income, and expense summary cards
- Add transactions (title, amount, type, category, date)
- Filterable transaction list with income/expense color coding
- 6-month spending bar chart (Recharts)
- Dark-themed UI with glassmorphism and responsive layout

### Infrastructure

- **Decoupled tiers** — separate Docker images, ASGs, and security groups
- **Path-based ALB routing** — single entry point for UI and API
- **Health checks** — `GET /health` on both frontend and backend
- **Environment-driven config** — `VITE_API_URL`, RDS credentials via env vars
- **Multi-AZ resilience** — subnets and ASGs span two Availability Zones
- **Private backend and database** — no direct internet exposure

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
| **Single NAT Gateway (optional)** | One NAT per AZ is HA-standard; one NAT saves ~$32/mo for labs |
| **RDS db.t3.micro**               | Managed MySQL without self-hosting DB on EC2                  |
| **Docker Hub (free tier)**        | Simple image hosting without ECR storage/transfer costs       |
| **ALB over NLB**                  | Path-based HTTP routing; NLB unnecessary for this HTTP app    |
| **Separate ASGs**                 | Scale frontend and backend independently under real load      |
| **No ECS/Fargate (initially)**    | EC2 + Docker teaches launch templates and ASG fundamentals    |


> **Tip:** Stop non-production RDS instances and scale ASGs to zero during idle periods to reduce monthly spend.

---

## Deployment Architecture


| Component        | Subnet Type   | Port     | Image Source                         |
| ---------------- | ------------- | -------- | ------------------------------------ |
| External ALB     | Public        | 80 / 443 | —                                    |
| Frontend EC2 ASG | Public        | 80       | `dockerhub-user/expense-tracker-web` |
| Backend EC2 ASG  | Private (app) | 4000     | `dockerhub-user/expense-tracker-api` |
| RDS MySQL        | Private (db)  | 3306     | —                                    |


### ALB Listener Rules (Path-Based Routing)


| Priority | Condition               | Target Group                                   |
| -------- | ----------------------- | ---------------------------------------------- |
| 1        | Path is `/api/`*        | `backend-tg` (port 4000)                       |
| 2        | Path is `/health` (API) | `backend-tg` (optional — or handled by rule 1) |
| Default  | `/*`                    | `frontend-tg` (port 80)                        |


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

Step-by-step AWS setup: [docs/aws-setup.md](docs/aws-setup.md)

---

## Tech Stack


| Layer          | Technologies                                                   |
| -------------- | -------------------------------------------------------------- |
| **Frontend**   | React 18, Vite, Tailwind CSS, Recharts, Lucide Icons, nginx    |
| **Backend**    | Node.js 18, Express, mysql2, CORS                              |
| **Database**   | Amazon RDS for MySQL 8.x                                       |
| **Containers** | Docker, Docker Hub, multi-stage builds                         |
| **Cloud**      | VPC, ALB, EC2 ASG, NAT Gateway, Security Groups, RDS           |
| **IaC-ready**  | Manual console setup documented (Terraform/CDK as future work) |


---

## Repository Structure

```
threeTier/
├── frontend/                 # Web tier
│   ├── Dockerfile            # Multi-stage: Node build → nginx:alpine
│   ├── nginx.conf            # SPA + /health for ALB
│   ├── src/
│   └── .env.example
├── backend/                  # App tier
│   ├── Dockerfile            # Node 18 Alpine, non-root
│   ├── server.js
│   ├── db.js
│   ├── schema.sql
│   └── .env.example
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
- MySQL (local) or RDS endpoint for remote testing

### Backend

```bash
cd backend
cp .env.example .env
# Edit .env with database credentials
npm install
npm run dev
```

Health check: [http://localhost:4000/health](http://localhost:4000/health)

### Frontend

```bash
cd frontend
cp .env.example .env
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
- Refactored a monolithic Docker container into **independently scalable frontend and backend services**, published to **Docker Hub** and deployed on EC2
- Implemented **VPC network segmentation** with public and private subnets, **NAT Gateways**, and **least-privilege Security Groups** restricting tier-to-tier communication
- Provisioned **Amazon RDS MySQL** in isolated DB subnets with application connectivity limited to the backend security group
- Configured **ALB health checks**, launch templates, and **environment-driven** application configuration (`VITE_API_URL`, RDS credentials)
- Built a responsive **React + Tailwind** dashboard with REST API integration, health endpoints, and containerized **nginx** static delivery
- Applied **FinOps** practices including right-sized instance types and documented cost trade-offs for NAT Gateway and RDS sizing

---

## Future Improvements

- **Infrastructure as Code** — Terraform or AWS CDK for reproducible deployments
- **CI/CD pipeline** — GitHub Actions to build, test, and push Docker images
- **HTTPS / ACM** — TLS certificate on External ALB
- **AWS Secrets Manager** — rotate RDS credentials without redeploying EC2
- **CloudWatch** — centralized logs, metrics, and alarms for ASG / ALB / RDS
- **WAF** — rate limiting and OWASP rule sets on External ALB
- **ElastiCache** — optional caching layer for read-heavy API paths
- **Multi-AZ RDS** — enable automatic failover for database HA
- **Private Docker registry** — migrate from Docker Hub to ECR with IAM-scoped pulls

---

## API Reference


| Method   | Endpoint                | Description                                 |
| -------- | ----------------------- | ------------------------------------------- |
| `GET`    | `/health`               | Backend health check — `{ "status": "ok" }` |
| `GET`    | `/api/transactions`     | List all transactions                       |
| `POST`   | `/api/transactions`     | Create a transaction                        |
| `DELETE` | `/api/transactions/:id` | Delete a transaction                        |


---

## License

This project is open source and available for portfolio and educational use. Add your preferred license (e.g., MIT) here.

---

## Author

- GitHub: [@rahul6364](https://github.com/your-username)

