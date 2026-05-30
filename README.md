# Expense Tracker — AWS 3-Tier Architecture

[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react)](https://react.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18-339933?logo=node.js)](https://nodejs.org/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Docker](https://img.shields.io/badge/Docker-Hub-2496ED?logo=docker)](https://www.docker.com/)

**Production-style 3-tier AWS architecture provisioned using Terraform** — one `terraform apply` deploys **VPC**, **Multi-AZ** networking, **Application Load Balancer**, **Auto Scaling Groups**, **RDS MySQL**, and containerized frontend/backend workloads with **zero manual steps** after Docker images are pushed.

Full-stack expense tracker: React + nginx (web tier), Node.js + Express (app tier), Amazon **RDS MySQL** (database tier). **Docker** images run on EC2 in **Private Subnets**; the ALB is the only public entry. **Infrastructure as Code** end-to-end.

**Quick deploy:** [docs/terraform-deployment.md](docs/terraform-deployment.md) · `cd terraform && terraform apply`

---

## Key Achievements

- Provisioned complete AWS infrastructure using Terraform
- Implemented Multi-AZ VPC architecture
- Configured Application Load Balancer with path-based routing
- Deployed frontend and backend using Auto Scaling Groups
- Automated database schema initialization during application startup
- Achieved zero-touch deployment using a single terraform apply

---

## Key features

### Application

- Dashboard with balance, income, and expense summaries
- CRUD transactions (title, amount, type, category, date)
- 6-month spending chart (Recharts)
- Dark UI with Tailwind CSS and responsive layout

### Infrastructure & DevOps

- **3-tier separation** — Web, App, and Database tiers with independent ASGs
- **Path-based ALB routing** — `/api/*` → backend, `/*` → frontend
- **Private compute** — EC2 in private app subnets; ALB is the only public entry
- **Terraform IaC** — VPC, NAT, ALB, RDS, ASG, security groups in one apply
- **EC2 user data** — Installs Docker, pulls images, starts containers automatically
- **Database bootstrap** — No manual schema setup on RDS
- **SSM-ready EC2** — Session Manager access without SSH keys
- **Multi-AZ** — Subnets and NAT Gateways span two Availability Zones for resilient networking
- **Private Subnets** — App and database tiers isolated from direct internet access

---

## Architecture overview

```
Internet
    │
    ▼
┌───────────────────────────────────────┐
│  Application Load Balancer (public)   │
│  /api/*  → Backend ASG :4000          │
│  /*      → Frontend ASG :80           │
└───────────────┬───────────────────────┘
                │
    ┌───────────┴───────────┐
    ▼                       ▼
┌─────────────┐     ┌─────────────┐
│ Frontend    │     │ Backend     │     Private app subnets
│ Docker/nginx│     │ Docker/API  │     (NAT for egress)
└─────────────┘     └──────┬──────┘
                           │ MySQL :3306
                           ▼
                    ┌─────────────┐
                    │ RDS MySQL   │     Private DB subnets
                    └─────────────┘
```

**Note:** API requests go **Browser → ALB → Backend**, not through the frontend EC2. The frontend instance only serves static assets.

Detailed diagrams and Mermaid flows: **[docs/architecture.md](docs/architecture.md)**

![Architecture diagram](docs/images/architecture-diagram.png)

---

## AWS services used

| Service | Role in this project |
|---------|----------------------|
| **VPC** | Isolated network `10.0.0.0/16` |
| **Subnets** | 2 public (ALB, NAT) + 2 private app (EC2) + 2 private DB (RDS) |
| **Internet Gateway** | Public subnet internet access |
| **NAT Gateway** | Outbound internet for private app subnets (2 AZs) |
| **Route Tables** | Public, per-AZ private app, isolated DB |
| **Security Groups** | Least-privilege: ALB → EC2 → RDS |
| **Application Load Balancer** | `expenses-alb`, path-based routing |
| **Target Groups** | `frontend-tg` (:80), `backend-tg` (:4000) |
| **Auto Scaling Groups** | `frontend-sg`, `backend-sg` — frontend and backend tiers |
| **Launch Templates** | Ubuntu 22.04 + user data |
| **RDS MySQL** | `expense-tracker-db`, `expense_tracker` database |
| **IAM** | EC2 instance profile for SSM |
| **Docker Hub** | Container image registry |

---

## Repository structure

```
threeTier/
├── frontend/                 # React + Vite + Tailwind + nginx
│   ├── Dockerfile
│   ├── nginx.conf
│   └── src/
├── backend/                  # Express REST API
│   ├── server.js
│   ├── db.js
│   ├── bootstrap.js          # Auto schema on startup
│   └── schema.sql            # Reference DDL
├── terraform/                # AWS Infrastructure as Code
│   ├── main.tf               # VPC, subnets, IGW, NAT
│   ├── route_table.tf
│   ├── security_groups.tf
│   ├── alb.tf
│   ├── asg.tf
│   ├── launch_template.tf
│   ├── rds.tf
│   ├── iam.tf
│   ├── data.tf
│   ├── output.tf
│   ├── varible.tf
│   ├── scripts/
│   │   ├── frontend.sh       # EC2 user data
│   │   └── backend.sh
│   └── terraform.tfvars.example
└── docs/
    ├── README.md             # Documentation index
    ├── architecture.md
    ├── terraform-deployment.md
    ├── aws-setup.md          # Manual Console guide
    ├── troubleshooting.md
    └── images/               # Your screenshots go here
```

---

## Terraform folder structure

| File | Creates / configures |
|------|----------------------|
| `provider.tf` | AWS provider, region from variable |
| `varible.tf` | VPC CIDRs, AZs, RDS credentials |
| `main.tf` | VPC, 6 subnets, IGW, 2× NAT + EIP |
| `route_table.tf` | Public, private app (per AZ), private DB routes |
| `security_groups.tf` | `alb-sg`, `frontend-sg`, `backend-sg`, `rds-sg` |
| `data.tf` | Ubuntu 22.04 AMI |
| `iam.tf` | EC2 role + SSM policy |
| `rds.tf` | DB subnet group + MySQL instance |
| `alb.tf` | ALB, target groups, `/api/*` listener rule |
| `launch_template.tf` | Launch templates + user data |
| `asg.tf` | Frontend and backend Auto Scaling Groups |
| `output.tf` | `application_url`, `alb_dns_name`, `rds_endpoint` |

---

## Deployment workflow (Terraform)

Primary path — infrastructure and application runtime in one apply (after Docker images are on Docker Hub):

```bash
# 1. Push images to Docker Hub
cd backend && docker build -t rahul6364/expense-tracker-api:latest . && docker push rahul6364/expense-tracker-api:latest
cd ../frontend && docker build --build-arg VITE_API_URL= -t rahul6364/expense-tracker-web:latest . && docker push rahul6364/expense-tracker-web:latest

# 2. Configure Terraform
cd ../terraform
cp terraform.tfvars.example terraform.tfvars   # edit db_password

# 3. Deploy
terraform init
terraform validate
terraform plan
terraform apply

# 4. Open app
terraform output application_url
```

**Full guide:** [docs/terraform-deployment.md](docs/terraform-deployment.md)

### Local development

```bash
cd backend && npm install && npm run dev    # :4000
cd frontend && npm install && npm run dev  # :5173
```

---

## Screenshots

> Replace placeholders below with your own captures. See **[Screenshot Placement Checklist](#screenshot-placement-checklist)** for exact filenames and locations.

### Infrastructure

| Description | Placeholder |
|-------------|-------------|
| VPC and subnets | ![VPC subnets](docs/images/vpc-subnets.png) |
| Application Load Balancer | ![ALB overview](docs/images/alb-overview.png) |
| Healthy target groups | ![ALB healthy](docs/images/alb-healthy.png) |
| Listener rules | ![ALB rules](docs/images/alb-listener-rules.png) |
| RDS instance | ![RDS](docs/images/rds-instance.png) |
| Auto Scaling Groups | ![ASG](docs/images/asg-instances.png) |
| Terraform apply success | ![Terraform apply](docs/images/terraform-apply-success.png) |

### Application

| Description | Placeholder |
|-------------|-------------|
| Dashboard | ![Dashboard](docs/images/app-dashboard.png) |
| Transactions | ![Transactions](docs/images/app-transactions.png) |
| Spending chart | ![Chart](docs/images/app-chart.png) |

---

## Cost considerations

This project is intended for **learning and portfolio** use. Running it 24/7 in AWS incurs real charges.

**Approximate monthly cost (us-east-1, always on):**

| Resource | Est. cost |
|----------|-----------|
| 2× NAT Gateways | ~$65/month (+ data processing) |
| Application Load Balancer | ~$16/month (+ LCU) |
| RDS `db.t3.micro` | ~$12/month |
| 2× EC2 `t3.micro` (ASGs) | ~$17/month |
| **Total (rough)** | **~$110+/month** |

**Always run `terraform destroy` when you finish testing** to avoid ongoing NAT, ALB, RDS, and EC2 charges.

---

## Lessons learned

- **Public vs private subnet design** — ALB and NAT live in public subnets; app and DB tiers stay private with controlled egress
- **ALB health checks and troubleshooting** — Target groups must match container ports and paths (`/` for frontend, `/health` for backend)
- **RDS connectivity via Security Groups** — Only the backend SG should reach MySQL on port 3306; no public RDS access
- **Terraform dependency management** — RDS endpoint injected into backend user data via `templatefile`; apply order matters for first boot
- **Automated database bootstrap patterns** — Application-owned schema (`bootstrap.js`) vs manual SQL or migration tools
- **Infrastructure provisioning vs application provisioning** — Terraform builds the platform; user data + Docker deliver the app; images must exist before EC2 boots

---

## Historical / learning path (manual AWS)

Before Terraform automation, this architecture was built **step-by-step in the AWS Console** to learn VPC, ALB, RDS, and ASG fundamentals. That walkthrough is preserved for education only — **not the recommended deploy path**.

| Phase | Description |
|-------|-------------|
| **Manual AWS (learning)** | Console-based VPC, ALB, RDS, ASG, Docker — [docs/aws-setup.md](docs/aws-setup.md) |
| **Terraform (current)** | Full stack in `terraform/` + EC2 user data — [docs/terraform-deployment.md](docs/terraform-deployment.md) |
| **Schema automation** | `backend/bootstrap.js` — `CREATE TABLE IF NOT EXISTS` on API startup |

---

## API reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | `{ "status": "ok" }` |
| `GET` | `/api/transactions` | List transactions |
| `POST` | `/api/transactions` | Create transaction |
| `DELETE` | `/api/transactions/:id` | Delete transaction |

---

## Documentation

| Document | Description |
|----------|-------------|
| [docs/README.md](docs/README.md) | Documentation index + screenshot checklist |
| [docs/architecture.md](docs/architecture.md) | VPC, NAT, SGs, Mermaid diagrams |
| [docs/terraform-deployment.md](docs/terraform-deployment.md) | `init` → `destroy` |
| [docs/aws-setup.md](docs/aws-setup.md) | Historical manual Console guide (learning) |
| [docs/troubleshooting.md](docs/troubleshooting.md) | ALB, RDS, Docker, DB errors |
| [docs/security-architecture.md](docs/security-architecture.md) | Security deep dive |
| [terraform/README.md](terraform/README.md) | Terraform quick reference |

---

## Future improvements

- GitHub Actions CI/CD — build images, `terraform plan`, deploy on merge
- HTTPS with ACM certificate on ALB
- AWS Secrets Manager for RDS credentials
- Flyway/Liquibase for versioned schema migrations
- CloudWatch logs, metrics, and alarms
- AWS WAF on ALB
- Multi-AZ RDS and larger ASG capacity
- Amazon ECR instead of Docker Hub

---

## Screenshot Placement Checklist

Capture these from your AWS account and app after a successful deploy. Save files under **`docs/images/`** using **exact filenames**.

| # | Filename | What to capture | Used in |
|---|----------|-----------------|---------|
| 1 | `architecture-diagram.png` | Your draw.io/Lucidchart 3-tier diagram (optional if using repo Mermaid only) | README, architecture.md |
| 2 | `vpc-subnets.png` | VPC → Subnets — 6 subnets (2 public, 4 private) | README, architecture.md |
| 3 | `alb-overview.png` | EC2 → Load Balancers → `expenses-alb` | README, terraform-deployment.md, troubleshooting.md |
| 4 | `alb-healthy.png` | Target Groups → both groups → **healthy** targets | README, terraform-deployment.md, troubleshooting.md |
| 5 | `alb-listener-rules.png` | ALB listener rules: `/api/*` + default | README, architecture.md |
| 6 | `rds-instance.png` | RDS → `expense-tracker-db` → private, endpoint visible | README, terraform-deployment.md, architecture.md |
| 7 | `asg-instances.png` | Auto Scaling → `frontend-sg` / `backend-sg` instances | README |
| 8 | `ec2-docker-ps.png` | SSM on backend → `sudo docker ps` | terraform-deployment.md |
| 9 | `app-dashboard.png` | Browser → ALB URL → dashboard | README |
| 10 | `app-transactions.png` | Transaction list with data | README |
| 11 | `app-chart.png` | Spending chart visible | README |
| 12 | `terraform-apply-success.png` | Terminal showing successful `terraform apply` + outputs | README, terraform-deployment.md |

**Steps:** Deploy → wait for healthy targets → capture PNGs → place in `docs/images/` → commit.

Duplicate checklist: [docs/README.md](docs/README.md#screenshot-placement-checklist)

---

## License

Open source for portfolio and educational use. Add MIT or your preferred license.

---

## Author

- GitHub: [@rahul6364](https://github.com/rahul6364)
