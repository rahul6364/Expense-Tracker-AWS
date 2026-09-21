# Expense Tracker AWS — DevOps & Cloud Engineering

[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react)](https://react.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18-339933?logo=node.js)](https://nodejs.org/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Docker](https://img.shields.io/badge/Docker-Hub-2496ED?logo=docker)](https://www.docker.com/)
[![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub%20Actions-2088FF?logo=githubactions)](https://github.com/features/actions)
[![No Long-Lived AWS Keys](https://img.shields.io/badge/AWS-No%20Static%20Keys-success)](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)

**Production-style 3-tier AWS architecture** — provisioned with **Terraform**, deployed through **GitHub Actions CI/CD**, and running live behind an **Application Load Balancer** in `us-east-1`.

This is a portfolio-grade **DevOps** and **Cloud Engineering** project: **Infrastructure as Code**, **OIDC** authentication, shift-left security (**TFLint**, **Checkov**, **GitLeaks**), **Infracost** cost visibility, **S3 remote state**, and a full **Plan → Apply** delivery pipeline with production environment approval.

**Repository:** [rahul6364/Expense-Tracker-AWS](https://github.com/rahul6364/Expense-Tracker-AWS)

## Project Overview Diagram

<!-- SCREENSHOT PLACEHOLDER
What to capture:
Overall AWS Expense Tracker architecture showing the VPC, public and private subnets, ALB, frontend/backend ASGs, private RDS MySQL, GitHub Actions with OIDC, CloudWatch monitoring and logs, alarms, and SNS notifications.

Save as:
docs/screenshots/project-overview.png
-->

![AWS Expense Tracker project overview](docs/screenshots/project-overview.png)

---

## Project Status

| Area | Status |
|------|--------|
| AWS infrastructure (live) | ✅ Deployed |
| Application behind ALB | ✅ Running |
| Terraform remote S3 backend | ✅ Implemented & state migrated |
| CI pipeline (`terraform-pr.yml`) | ✅ Complete |
| CD pipeline (`deploy.yml`) | ✅ Complete |
| Production environment approval | ✅ Configured |
| OIDC authentication | ✅ Active |
| Infracost integration | ✅ Active in PR pipeline |
| CloudWatch dashboard | ✅ Implemented / Active |
| CloudWatch Logs | ✅ Implemented / Active |
| CloudWatch alarms | ✅ Implemented / Active |
| SNS alerting | ✅ Implemented / Active |

**Future enhancements:** ACM / HTTPS · WAF · VPC Flow Logs · ALB access logs · Multi-AZ RDS · ECR · database migration tooling

---

## Key Achievements

- Deployed complete **AWS** infrastructure using **Terraform** with live validation
- Implemented a **multi-subnet architecture across two Availability Zones**
- Configured **Application Load Balancer** with path-based routing (`/api/*` → backend)
- Deployed frontend and backend via **Auto Scaling Groups** with **Docker** on **Private Subnets**
- Automated **RDS MySQL** schema initialization at application startup (`bootstrap.js`)
- Bootstrapped and migrated **Terraform state** to **S3** with native lock files (`use_lockfile`)
- Built end-to-end **CI/CD** with **GitHub Actions** — PR validation and production deployment
- Implemented **OIDC** passwordless AWS authentication — no long-lived access keys
- Integrated **TFLint**, **Checkov**, **GitLeaks**, and **Infracost** into the delivery pipeline
- Enabled **IMDSv2** on EC2 and **RDS storage encryption**
- Implemented CloudWatch dashboard, application logs, alarms, and SNS email alerting
- Achieved gated production deployments via GitHub **Environment** approval

---

## Project Overview

| Area | Implementation |
|------|----------------|
| **Infrastructure as Code** | Full AWS stack in `terraform/` — **Terraform** ~> 6.0 |
| **CI** | `.github/workflows/terraform-pr.yml` — validate, scan, plan, cost |
| **CD** | `.github/workflows/deploy.yml` — plan, approve, apply, outputs |
| **State management** | S3 bucket `rahul-expense-tracker123` + `use_lockfile` |
| **Security** | Security groups, IMDSv2, RDS encryption, OIDC, secret scanning |
| **Application** | React + Express + **RDS MySQL** with auto schema bootstrap |
| **Observability** | CloudWatch dashboard, CloudWatch Logs, alarms, and SNS email alerts |

---

## Architecture Overview

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
│ React/nginx │     │ Express API │     (NAT for egress)
│ Docker      │     │ Docker      │
└─────────────┘     └──────┬──────┘
                           │ MySQL :3306
                           ▼
                    ┌─────────────┐
                    │ RDS MySQL   │     Private DB subnets
                    └─────────────┘
```

| Tier | Stack | Placement |
|------|-------|-----------|
| **Web** | React.js + nginx in **Docker** | `frontend-asg`, private app subnets, behind **ALB** |
| **App** | Node.js / Express in **Docker** | `backend-asg`, private app subnets |
| **Database** | Amazon **RDS MySQL** | Private DB subnets |

**Traffic flow:** API requests go **Browser → ALB → Backend** — not through frontend EC2.

**Observability flow:**

```
Frontend Docker logs ──→ CloudWatch Logs (/expense-tracker/frontend)
Backend Docker logs  ──→ CloudWatch Logs (/expense-tracker/backend)
Metrics ──────────────→ CloudWatch Dashboard (expense-tracker-monitoring)
Alarms ───────────────→ SNS (expense-tracker-alerts) ──→ Email
```

The primary application path remains Internet → ALB → frontend/backend ASGs → RDS. Containers use Docker's `awslogs` driver, while Terraform manages both log groups with seven-day retention.

Detailed Mermaid diagrams: **[docs/architecture.md](docs/architecture.md)**

![Architecture diagram](docs/images/architecture-diagram.png)

<!-- SCREENSHOT PLACEHOLDER
What to capture:
AWS architecture showing the VPC, public subnets, ALB, private frontend/backend ASGs, and private RDS subnets.

Save as:
docs/screenshots/aws-architecture.png
-->

![AWS architecture](docs/screenshots/aws-architecture.png)

---

## AWS Services Used

| Service | Role |
|---------|------|
| **Subnets** | Public (ALB, NAT) + private app (EC2) + private DB (RDS) |
| **Internet Gateway** | Public subnet ingress/egress |
| **NAT Gateway** | Private subnet outbound (2 AZs) |
| **Route Tables** | Public, per-AZ private app, isolated DB |
| **Security Groups** | `alb-sg`, `frontend-sg`, `backend-sg`, `rds-sg` |
| **Application Load Balancer** | `expenses-alb`, path-based routing |
| **Auto Scaling Groups** | `frontend-asg`, `backend-asg` |
| **Launch Templates** | Ubuntu 22.04, IMDSv2, user data |
| **RDS MySQL** | Encrypted storage, private subnets (single-AZ) |
| **IAM** | EC2 instance profile (SSM), GitHub Actions OIDC role |
| **S3** | Remote Terraform state backend |
| **CloudWatch** | Dashboard, ASG/ALB/RDS metrics, and alarms |
| **CloudWatch Logs** | Frontend and backend container logs |
| **SNS** | `expense-tracker-alerts` email notifications |
| **Docker Hub** | Container images |

<!-- SCREENSHOT PLACEHOLDER
What to capture:
AWS VPC console showing the six project subnets, their Availability Zones, and public/private placement.

Save as:
-->

<!-- ![AWS VPC and subnets](docs/screenshots/aws-vpc.png) -->
Save as:
-->

<!-- ![Auto Scaling Groups](docs/screenshots/autoscaling-groups.png) -->

<!-- SCREENSHOT PLACEHOLDER
Private `expense-tracker-db` RDS MySQL instance, showing encrypted storage and non-public accessibility.

Save as:
docs/screenshots/rds-mysql.png
-->

<!-- ![Private RDS MySQL](docs/screenshots/rds-mysql.png) -->

<!-- SCREENSHOT PLACEHOLDER
What to capture:
EC2 console showing the two running application instances, one frontend and one backend, in private subnets.

Save as:
docs/screenshots/ec2-instances.png
-->

<!-- ![Running EC2 instances](docs/screenshots/ec2-instances.png) -->

What to capture:
Elastic IP allocations associated with the two NAT gateways.

<!-- SCREENSHOT PLACEHOLDER
Security groups showing ALB ingress and restricted frontend, backend, and RDS security-group references.
Save as:
docs/screenshots/security-groups.png
-->

<!-- ![Security groups](docs/screenshots/security-groups.png) -->

<!-- SCREENSHOT PLACEHOLDER
What to capture:
Frontend and backend EC2 launch templates showing the Ubuntu image, instance type, IMDSv2, and user data configuration.

docs/screenshots/launch-templates.png
-->

<!-- ![EC2 launch templates](docs/screenshots/launch-templates.png) -->

<!-- SCREENSHOT PLACEHOLDER
What to capture:
NAT gateways in both public subnets with available status and their Elastic IP associations.

Save as:
docs/screenshots/nat-gateways.png
-->

<!-- ![NAT gateways](docs/screenshots/nat-gateways.png) -->
<!-- SCREENSHOT PLACEHOLDER
The project Internet Gateway attached to the VPC.

Save as:
docs/screenshots/internet-gateway.png
-->
<!-- ![Internet Gateway](docs/screenshots/internet-gateway.png) -->

<!-- SCREENSHOT PLACEHOLDER
Public, private application, and isolated database route tables with their subnet associations.

Save as:
docs/screenshots/route-tables.png
-->

<!-- ![Route tables](docs/screenshots/route-tables.png) -->

---

## CI/CD Pipelines

Two **GitHub Actions** workflows implement the full delivery lifecycle.

### 1. PR Pipeline — `terraform-pr.yml`

**Trigger:** Pull requests modifying `terraform/**`

| Step | Tool / Action |
|------|---------------|
| Checkout | `actions/checkout@v4` |
| AWS credentials | **OIDC** via `aws-actions/configure-aws-credentials@v4` |
| Format check | `terraform fmt -check -recursive` |
| Init | `terraform init` (remote **S3 backend**) |
| Validate | `terraform validate` |
| TFLint init + scan | `terraform-linters/setup-tflint` |
| Security scan | **Checkov** (`soft_fail: true`) |
| Plan | `terraform plan -out=tfplan` |
| Cost breakdown | **Infracost** on plan artifact |
| Artifacts | Upload `terraform-plan` + `infracost-report` |

**Secrets injected:** `TF_VAR_db_user`, `TF_VAR_db_password` from GitHub Secrets

### 2. CD Pipeline — `deploy.yml`

**Trigger:** Push to `main` · **Environment:** `production` (manual approval gate)

| Step | Tool / Action |
|------|---------------|
| Checkout | `actions/checkout@v4` |
| AWS credentials | **OIDC** via `aws-actions/configure-aws-credentials@v4` |
| Format check | `terraform fmt -check -recursive` |
| Init | `terraform init -input=false` |
| Validate | `terraform validate` |
| Plan | `terraform plan -out=tfplan -input=false` |
| Plan review | `terraform show tfplan` |
| **Production approval** | GitHub Environment protection on `production` |
| Apply | `terraform apply --auto-approve tfplan` |
| Outputs | `terraform output -json` |

**Concurrency:** `terraform-production` group — no concurrent production deploys

<!-- SCREENSHOT PLACEHOLDER
What to capture:
Successful GitHub Actions PR validation and production deployment, including the production approval gate.

Save as:
docs/screenshots/github-actions.png
-->

<!-- ![GitHub Actions CI/CD](docs/screenshots/github-actions.png) -->

---

## CI Pipeline Architecture

```mermaid
flowchart LR
  PR[Pull Request] --> Checkout
  Checkout --> OIDC[OIDC → IAM Role]
  OIDC --> Fmt[terraform fmt]
  Fmt --> Init[terraform init]
  Init --> Validate[terraform validate]
  Validate --> TFLint[TFLint]
  TFLint --> Checkov[Checkov]
  Checkov --> Plan[terraform plan]
  Plan --> Infracost[Infracost]
  Infracost --> Artifacts[Upload Artifacts]
```

**Purpose:** Catch formatting, validation, lint, security, and cost issues **before merge** — no changes reach `main` without passing quality gates.

---

## CD Pipeline Architecture

```mermaid
flowchart LR
  Push[Push to main] --> Checkout
  Checkout --> OIDC[OIDC → IAM Role]
  OIDC --> Plan[terraform plan]
  Plan --> Show[terraform show]
  Show --> Approval{Production\nApproval}
  Approval -->|Approved| Apply[terraform apply]
  Apply --> Outputs[terraform output]
```

**Purpose:** Controlled, auditable infrastructure changes to the live **AWS** environment with human approval before apply.

---

## Deployment Lifecycle

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│ Local dev   │───▶│ Pull Request │───▶│ Merge main  │───▶│ Production   │
│ pre-commit  │    │ CI pipeline  │    │ CD pipeline │    │ AWS live     │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
     │                    │                   │                  │
  fmt/validate        plan + cost          plan + approve       apply
  tflint/gitleaks     tflint/checkov       apply + outputs      ALB + ASG
```

| Phase | What happens |
|-------|--------------|
| **1. Local** | Pre-commit: `terraform_fmt`, `terraform_validate`, `terraform_tflint`, `gitleaks` |
| **2. PR** | CI runs fmt → init → validate → TFLint → Checkov → plan → Infracost → artifacts |
| **3. Review** | Engineer reviews plan diff and Infracost cost report in PR artifacts |
| **4. Merge** | Approved changes merge to `main` |
| **5. CD** | Deploy workflow plans, waits for **production** approval, applies, outputs URLs |
| **6. Runtime** | EC2 user data pulls **Docker** images; backend bootstraps **RDS** schema |

---

## OIDC Authentication

No `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` stored in GitHub.

```
GitHub Actions → OIDC token → sts:AssumeRoleWithWebIdentity → IAM Role → temporary credentials
```

| AWS Component | Purpose |
|---------------|---------|
| **GitHub OIDC provider** | Trust `token.actions.githubusercontent.com` |
| **IAM role** | Assumed via `secrets.AWS_ROLE_ARN` |
| **Trust policy** | Scoped to repository and branch |
| **Permission policy** | Least-privilege for Terraform operations |

<!-- SCREENSHOT PLACEHOLDER
What to capture:
GitHub Actions OIDC provider and IAM role trust relationship scoped to this repository and branch.

Save as:
docs/screenshots/github-oidc.png
-->

<!-- ![GitHub OIDC IAM role](docs/screenshots/github-oidc.png) -->

---

## Terraform Remote State (S3 Backend)

**Status:** ✅ Implemented and state migrated

| Setting | Value |
|---------|-------|
| Bucket | `rahul-expense-tracker123` |
| State key | `terraform/terraform.tfstate` |
| Region | `us-east-1` |
| Encryption | AES256 (`encrypt = true`) |
| Versioning | Enabled (bootstrap config) |
| Locking | S3 native — `use_lockfile = true` (no DynamoDB) |

Bootstrap stack lives in `terraform-backend/` (creates the S3 bucket). The main stack in `terraform/provider.tf` consumes that S3 backend.

```hcl
backend "s3" {
  bucket       = "rahul-expense-tracker123"
  key          = "terraform/terraform.tfstate"
  region       = "us-east-1"
  encrypt      = true
  use_lockfile = true
}
```

The backend uses `key = "terraform/terraform.tfstate"`, `region = "us-east-1"`, `encrypt = true`, and `use_lockfile = true`. The bootstrap stack also enables bucket versioning and AES256 server-side encryption.

<!-- SCREENSHOT PLACEHOLDER
What to capture:
Successful `terraform plan` or `terraform apply` output showing the infrastructure deployment and outputs.

Save as:
docs/screenshots/terraform-plan.png
-->

<!-- ![Terraform plan or apply](docs/screenshots/terraform-plan.png) -->

---

## Observability

### CloudWatch Dashboard

The Terraform-managed dashboard is named `expense-tracker-monitoring`. Its widgets cover:

- ALB `RequestCount` and `TargetResponseTime`
- Frontend and backend target-group `UnHealthyHostCount`
- Frontend and backend ASG `GroupInServiceInstances` and `GroupDesiredCapacity`
- RDS `CPUUtilization`, `DatabaseConnections`, `FreeStorageSpace`, and `FreeableMemory`

Both Auto Scaling Groups publish group metrics at `metrics_granularity = "1Minute"`, including `GroupDesiredCapacity`, `GroupInServiceInstances`, `GroupMinSize`, and `GroupMaxSize`.

<!-- SCREENSHOT PLACEHOLDER
What to capture:
CloudWatch dashboard `expense-tracker-monitoring` showing ALB, frontend/backend ASG, target health, and RDS metrics.

Save as:
docs/screenshots/cloudwatch-dashboard.png
-->

<!-- ![CloudWatch dashboard](docs/screenshots/cloudwatch-dashboard.png) -->

<!-- SCREENSHOT PLACEHOLDER
What to capture:
A second CloudWatch dashboard view showing the remaining ALB, target health, ASG, or RDS widgets at a useful time range.

Save as:
docs/screenshots/cloudwatch-dashboard-2.png
-->

<!-- ![CloudWatch dashboard additional view](docs/screenshots/cloudwatch-dashboard-2.png) -->

### Alarms and SNS

The `expense-tracker-alerts` SNS topic receives these CloudWatch alarms:

| Alarm | Metric and threshold | Evaluation |
|-------|----------------------|------------|
| Backend ASG high CPU | EC2 `CPUUtilization` > 80% | 2 periods of 300 seconds |
| Frontend ASG high CPU | EC2 `CPUUtilization` > 80% | 2 periods of 300 seconds |
| ALB HTTP 5XX | `HTTPCode_ELB_5XX_Count` > 10 | 1 period of 300 seconds |
| RDS high CPU | RDS `CPUUtilization` > 80% | 2 periods of 300 seconds |

The ALB 5XX alarm uses `treat_missing_data = "notBreaching"`: during healthy operation, no 5XX datapoints is expected and should not place the alarm into `INSUFFICIENT_DATA`. Email subscription is controlled by `var.alert_email`, supplied in GitHub Actions through the `ALERT_EMAIL` secret as `TF_VAR_alert_email`. The recipient must confirm the SNS subscription by email.

<!-- SCREENSHOT PLACEHOLDER
What to capture:
CloudWatch alarms showing the backend/frontend CPU, ALB HTTP 5XX, and RDS CPU alarms with their configured states.

Save as:
docs/screenshots/cloudwatch-alarms.png
-->

<!-- ![CloudWatch alarms](docs/screenshots/cloudwatch-alarms.png) -->

<!-- SCREENSHOT PLACEHOLDER
What to capture:
Confirmed email subscription for the `expense-tracker-alerts` SNS topic.

Save as:
docs/screenshots/sns-alert.png
-->

<!-- ![SNS confirmed subscription](docs/screenshots/sns-alert.png) -->

### Application Logging

Terraform creates these log groups with seven-day retention:

- `/expense-tracker/frontend`
- `/expense-tracker/backend`

The frontend and backend containers send stdout/stderr directly with Docker's `awslogs` logging driver. Both use `awslogs-region=us-east-1` and `awslogs-create-group=false`; the frontend uses `awslogs-group=/expense-tracker/frontend` and `awslogs-stream=frontend-${HOSTNAME}`, while the backend uses `awslogs-group=/expense-tracker/backend` and `awslogs-stream=backend-${HOSTNAME}`. Streams include the EC2 hostname so logs from replacement or parallel ASG instances remain distinguishable. The EC2 role grants `logs:CreateLogStream` and `logs:PutLogEvents` for these groups, alongside SSM access. No CloudWatch Agent is required or deployed.

<!-- SCREENSHOT PLACEHOLDER
What to capture:
CloudWatch Logs frontend log group `/expense-tracker/frontend` with a recent container log stream.

Save as:
docs/screenshots/frontend-logs.png
-->

<!-- ![Frontend CloudWatch logs](docs/screenshots/frontend-logs.png) -->

<!-- SCREENSHOT PLACEHOLDER
What to capture:
CloudWatch Logs backend log group `/expense-tracker/backend` with a recent container log stream.

Save as:
docs/screenshots/backend-logs.png
-->

<!-- ![Backend CloudWatch logs](docs/screenshots/backend-logs.png) -->

The backend user-data is rendered with Terraform `templatefile()`, so its source uses `$${HOSTNAME}` to produce `${HOSTNAME}` for the shell at runtime. The frontend user-data is loaded with `file()`, so it uses `${HOSTNAME}` directly.

## Observability Debugging & Problems Solved

- **ASG dashboard showed no data:** group metrics were not enabled; the ASGs now publish the required metrics every minute.
- **ALB 5XX alarm showed `INSUFFICIENT_DATA`:** healthy operation produced no 5XX datapoints; `treat_missing_data = "notBreaching"` now handles that state correctly.
- **CloudWatch Agent vs Docker `awslogs`:** the final design uses Docker's logging driver, avoiding agent installation and extra configuration while sending stdout/stderr directly to Terraform-managed log groups.
- **Terraform `templatefile()` and `HOSTNAME`:** backend user-data uses `$${HOSTNAME}` in the Terraform source so the generated shell script contains `${HOSTNAME}`.
- **Frontend `HOSTNAME`:** frontend user-data uses `file()`, so `${HOSTNAME}` is passed directly; the temporary `$${HOSTNAME}` stream-name issue was corrected.
- **Windows CRLF/LF normalization:** `.gitattributes` enforces LF for Terraform, shell, and workflow files; normalization was handled without losing the observability changes.

---

## Security Architecture

### Network Security Groups

| Tier | Inbound | Source |
|------|---------|--------|
| **ALB** | HTTP 80 | Internet |
| **Frontend** | Port 80 | `alb-sg` only |
| **Backend** | Port 4000 | `alb-sg` only |
| **RDS** | MySQL 3306 | `backend-sg` only |

### Platform Hardening

| Control | Status |
|---------|--------|
| **IMDSv2** (`http_tokens = required`) | ✅ Enabled |
| **RDS storage encryption** | ✅ Enabled |
| **OIDC** (no static AWS keys) | ✅ Active |
| **Private Subnets** for compute & DB | ✅ Enforced |

Deep dive: [docs/security-architecture.md](docs/security-architecture.md)

<!-- SCREENSHOT PLACEHOLDER
What to capture:
IAM EC2 role policies showing SSM access and CloudWatch Logs permissions for the frontend and backend log groups.

Save as:
docs/screenshots/iam-security.png
-->

<!-- ![IAM and security configuration](docs/screenshots/iam-security.png) -->

---

## Security Pipeline

Defense-in-depth across local development and CI.

| Layer | Tool | Where |
|-------|------|-------|
| **Secret scanning** | **GitLeaks** | Pre-commit hooks |
| **Format & validate** | `terraform fmt`, `terraform validate` | Pre-commit + CI + CD |
| **Linting** | **TFLint** | Pre-commit + PR pipeline |
| **IaC security** | **Checkov** | PR pipeline (`soft_fail: true`) |
| **Auth** | **OIDC** + IAM | CI + CD workflows |

**Checkov accepted findings** (documented with `#checkov:skip` annotations for portfolio/dev environment):

- No WAF, HTTPS listener, or ACM certificate
- No VPC Flow Logs or ALB access logs
- Single-AZ RDS (`multi_az = false`)
- No RDS enhanced monitoring or deletion protection

---

## Pre-Commit Hooks

**File:** `.pre-commit-config.yaml`

| Hook | Purpose |
|------|---------|
| `terraform_fmt` | Enforce consistent formatting |
| `terraform_validate` | Validate config (`-backend=false` locally) |
| `terraform_tflint` | Lint before push |
| `gitleaks` | Detect secrets and credentials |

---

## Cost Visibility (Infracost)

**Infracost** runs in the PR pipeline against the Terraform plan artifact.

```bash
infracost breakdown --path=tfplan --format=json --out-file=infracost.json
```

| Output | Artifact |
|--------|----------|
| JSON cost report | `infracost-report` |
| Table summary | Printed in workflow logs |

Provides cost awareness **before** infrastructure changes merge — a key **FinOps** practice for **Cloud Engineering** teams.

---

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| **Terraform over Console** | Repeatable, version-controlled, reviewable infrastructure |
| **S3 backend + `use_lockfile`** | Remote state with native locking — no DynamoDB dependency |
| **OIDC over static keys** | Industry-standard, rotatable, no secrets in GitHub |
| **Separate CI and CD workflows** | PR validation vs gated production apply |
| **GitHub Environment approval** | Human gate before live infrastructure changes |
| **Private app subnets for EC2** | ALB-only ingress; NAT for Docker Hub egress |
| **Path-based ALB routing** | Single entry point; `/api/*` to backend, `/*` to frontend |
| **App-level schema bootstrap** | `bootstrap.js` eliminates manual RDS DDL |
| **Checkov `soft_fail`** | Security signal without blocking portfolio iteration |
| **Infracost in PR only** | Cost feedback at review time, not on every apply |
| **CloudWatch dashboard** | One view for ALB, ASG, and RDS health metrics |
| **ASG group metrics at 1 minute** | Publishes the group-level data required by the dashboard |
| **CloudWatch alarms + SNS** | Sends operational alerts without coupling alerting to application code |
| **Docker `awslogs` over CloudWatch Agent** | Sends container stdout/stderr directly to CloudWatch with less configuration and no extra agent |
| **Seven-day log retention** | Controls cost while keeping recent application logs available |
| **ALB 5XX missing data as `notBreaching`** | Treats a healthy absence of 5XX events as healthy rather than insufficient data |

---

## Deployment Guide

### Prerequisites

- Docker images on Docker Hub (`rahul6364/expense-tracker-web`, `rahul6364/expense-tracker-api`)
- `terraform.tfvars` configured (never commit — use GitHub Secrets in CI)
- S3 backend bootstrapped (`terraform-backend/`)

### Application images

```bash
cd backend
docker build -t rahul6364/expense-tracker-api:latest .
docker push rahul6364/expense-tracker-api:latest

cd ../frontend
docker build --build-arg VITE_API_URL= -t rahul6364/expense-tracker-web:latest .
docker push rahul6364/expense-tracker-web:latest
```

### Deploy via CI/CD (recommended)

1. Open a PR with Terraform changes → CI pipeline runs automatically
2. Review plan artifact and Infracost report
3. Merge to `main` → CD pipeline triggers
4. Approve the `production` environment gate
5. Workflow applies and outputs `application_url`

### Deploy locally

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit locally
terraform init
terraform validate
terraform plan
terraform apply
terraform output application_url
```

### Verify live deployment

```bash
ALB=$(terraform output -raw alb_dns_name)
curl -s "http://${ALB}/api/transactions"
```

<!-- SCREENSHOT PLACEHOLDER
What to capture:
The deployed Expense Tracker frontend running through the ALB URL, with the dashboard visible.

Save as:
docs/screenshots/deployed-application.png
-->

<!-- ![Deployed Expense Tracker](docs/screenshots/deployed-application.png) -->

**Full guide:** [docs/terraform-deployment.md](docs/terraform-deployment.md)

### Local application development

```bash
cd backend && npm install && npm run dev    # :4000
cd frontend && npm install && npm run dev  # :5173
```

### Historical / learning path (manual AWS)

Console-based walkthrough preserved for education: [docs/aws-setup.md](docs/aws-setup.md)

---

## Repository Structure

```
Expense-Tracker-AWS/
├── frontend/                      # React + Vite + Tailwind + nginx
│   ├── Dockerfile
│   ├── nginx.conf
│   └── src/
├── backend/                       # Express REST API
│   ├── server.js
│   ├── db.js
│   ├── bootstrap.js               # Auto RDS schema on startup
│   └── schema.sql
├── terraform/                     # Main AWS Infrastructure as Code
│   ├── provider.tf                # S3 remote backend configured
│   ├── main.tf                    # VPC, subnets, IGW, NAT
│   ├── route_table.tf
│   ├── security_groups.tf
│   ├── alb.tf
│   ├── asg.tf
│   ├── launch_template.tf         # IMDSv2, user data
│   ├── rds.tf                     # Encrypted RDS
│   ├── iam.tf
│   ├── output.tf                  # application_url, alb_dns_name
│   ├── scripts/                   # EC2 Docker bootstrap
│   │   ├── frontend.sh
│   │   └── backend.sh
│   └── terraform.tfvars.example
├── terraform-backend/             # S3 state bucket bootstrap
│   ├── backend.tf
│   └── README.md
├── docs/
│   ├── architecture.md
│   ├── terraform-deployment.md
│   ├── security-architecture.md
│   ├── troubleshooting.md
│   ├── images/
│   │   └── architecture-diagram.png
│   └── screenshots/               # Project evidence captured after deployment
│       └── project-overview.png   # Overall architecture, CI/CD, and observability diagram
├── .github/workflows/
│   ├── terraform-pr.yml           # CI: validate, scan, plan, cost
│   └── deploy.yml                 # CD: plan, approve, apply
├── .pre-commit-config.yaml        # fmt, validate, tflint, gitleaks
├── .gitattributes                 # LF enforcement for .tf, .sh, .yml
└── README.md
```

### Screenshot Files

Add captured evidence to `docs/screenshots/` using these filenames:

```text
docs/
└── screenshots/
  ├── aws-architecture.png
  ├── aws-vpc.png
  ├── alb-target-groups.png
  ├── autoscaling-groups.png
  ├── rds-mysql.png
  ├── ec2-instances.png
  ├── eip-addresses.png
  ├── security-groups.png
  ├── launch-templates.png
  ├── nat-gateways.png
  ├── internet-gateway.png
  ├── route-tables.png
  ├── github-actions.png
  ├── github-oidc.png
  ├── terraform-plan.png
  ├── cloudwatch-dashboard.png
  ├── cloudwatch-dashboard-2.png
  ├── cloudwatch-alarms.png
  ├── sns-alert.png
  ├── frontend-logs.png
  ├── backend-logs.png
  ├── iam-security.png
  └── deployed-application.png
```

### Terraform Provisions

VPC · Internet Gateway · Route Tables · Public / Private App / Private DB Subnets · Security Groups · Launch Templates · **Auto Scaling Groups** · **Application Load Balancer** · Target Groups · Listener Rules · **IAM** Roles · Instance Profiles · **RDS MySQL** · Outputs

---

## Challenges Solved

| Challenge | Solution |
|-----------|----------|
| **S3 backend bootstrap chicken-and-egg** | `terraform init -backend=false` → `apply` → `init -migrate-state` |
| **Static AWS credentials in CI** | Migrated to **OIDC** + `AssumeRoleWithWebIdentity` |
| **Unreviewed production applies** | GitHub `production` environment with manual approval |
| **No cost visibility on PRs** | **Infracost** breakdown on plan artifacts |
| **Missing RDS table on first boot** | `bootstrap.js` — `CREATE TABLE IF NOT EXISTS` before API listens |
| **ALB API routing** | Empty `VITE_API_URL` — browser calls `/api/*` on same ALB host |
| **Checkov noise in dev** | `#checkov:skip` annotations + `soft_fail: true` |
| **CRLF line endings on Windows** | `.gitattributes` enforces LF for IaC files |
| **Concurrent deploys** | `concurrency` group `terraform-production` |
| **ASG dashboard showed no data** | Enabled `metrics_granularity = "1Minute"` and the ASG group metrics used by the dashboard |
| **ALB 5XX alarm showed `INSUFFICIENT_DATA`** | Configured `treat_missing_data = "notBreaching"` because no 5XX datapoints is normal during healthy operation |
| **CloudWatch Agent vs Docker logging** | Chose Docker `awslogs` to send container stdout/stderr directly to Terraform-managed log groups without installing an agent |
| **Terraform `templatefile()` and `HOSTNAME`** | Escaped the backend shell variable as `$${HOSTNAME}` so Terraform emits `${HOSTNAME}` for runtime expansion |
| **Frontend and backend user-data differ** | Frontend uses `file()` and `${HOSTNAME}` directly; backend uses `templatefile()` and `$${HOSTNAME}` |
| **Windows CRLF/LF normalization** | `.gitattributes` enforces LF for `*.tf`, `*.sh`, `*.yml`, and `*.yaml`; normalization was handled without losing observability changes |

---

## Lessons Learned

- **Remote state is foundational** — S3 backend unlocks team CI/CD, locking, and state consistency
- **Separate CI from CD** — PR validation and production apply serve different risk profiles
- **OIDC eliminates credential sprawl** — no keys to rotate, leak, or audit separately
- **Infracost changes review behavior** — engineers see cost impact alongside plan diffs
- **Environment gates matter** — approval before `terraform apply` prevents accidental production changes
- **Private subnet design** — ALB + NAT pattern keeps compute off the public internet
- **Security groups over CIDR** — tier-to-tier trust via SG references, not IP ranges
- **Shift-left security** — pre-commit + PR scanning catches issues before AWS touch
- **Infrastructure vs application** — Terraform builds the platform; user data + Docker deliver the app
- **Metrics must be published** — a dashboard cannot display an AWS metric that its resource is not emitting
- **No errors is meaningful** — a healthy ALB can legitimately produce no 5XX datapoints
- **Terraform templates parse `${...}`** — shell variables need escaping when scripts pass through `templatefile()`
- **Docker logging can be simpler** — `awslogs` is a practical fit for small containerized workloads without a log agent
- **ASG replacement needs distinct streams** — hostname-based stream names separate logs across instances
- **Managed log groups make retention explicit** — Terraform defines the groups and seven-day lifecycle policy

---

## Skills Demonstrated

**Terraform** · **AWS** · **DevOps** · **GitHub Actions** · **CI/CD** · **OIDC** · **Infrastructure as Code** · **Docker** · **RDS** · **Application Load Balancer** · **Auto Scaling** · **Private Subnets** · **IAM** · **S3 Backend** · **Cloud Engineering** · **TFLint** · **Checkov** · **GitLeaks** · **Infracost** · **FinOps** · **Network Security** · **EC2** · **VPC Design**

---

## Interview Talking Points

1. **End-to-end delivery** — "I built a full CI/CD pipeline: PR checks with plan + Infracost, gated production apply via GitHub Environments."
2. **OIDC authentication** — "No static AWS keys — GitHub Actions assumes an IAM role via `AssumeRoleWithWebIdentity`."
3. **Remote state** — "Bootstrapped an S3 backend with versioning, encryption, and native lock files — migrated state from local."
4. **3-tier on AWS** — "ALB path routing to Dockerized frontend/backend ASGs in private subnets, RDS in isolated DB subnets."
5. **Security pipeline** — "Shift-left with GitLeaks pre-commit, TFLint, and Checkov in CI — accepted risks documented inline."
6. **Cost awareness** — "Infracost runs on every PR plan so reviewers see infrastructure cost before merge."
7. **Zero-touch schema** — "Backend bootstraps RDS DDL on startup — no manual SQL after deploy."
8. **Production gating** — "Deploy workflow uses concurrency control and environment approval before `terraform apply`."
9. **CloudWatch dashboard** — "I built a CloudWatch dashboard covering ALB, ASG, and RDS health metrics."
10. **Application logging** — "I configured Docker's `awslogs` driver to send frontend and backend container logs directly to CloudWatch Logs."
11. **Alerting** — "I configured CloudWatch alarms for ASG CPU, RDS CPU, and ALB 5XX errors, with SNS email notification."
12. **Observability troubleshooting** — "The ASG dashboard initially showed no data because group metrics were not enabled, so I enabled 1-minute ASG metrics."
13. **Alarm behavior** — "The ALB 5XX alarm initially showed insufficient data because no 5XX events existed, so I configured missing data as `notBreaching`."
14. **Terraform templating** — "The backend user-data uses `templatefile()`, so shell variables such as `HOSTNAME` must be escaped as `$${HOSTNAME}`."

---

## Future Enhancements

- ACM certificate + HTTPS listener + HTTP redirect
- AWS WAF on ALB
- VPC Flow Logs and ALB access logs
- Multi-AZ RDS and deletion protection
- Amazon ECR instead of Docker Hub
- Flyway/Liquibase for versioned schema migrations

---

---

## API Reference

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
| [docs/terraform-deployment.md](docs/terraform-deployment.md) | Deploy guide |
| [docs/aws-setup.md](docs/aws-setup.md) | Historical manual Console guide |
| [docs/troubleshooting.md](docs/troubleshooting.md) | ALB, RDS, Docker, DB errors |
| [docs/security-architecture.md](docs/security-architecture.md) | Security deep dive |
| [terraform/README.md](terraform/README.md) | Terraform quick reference |
| [terraform-backend/README.md](terraform-backend/README.md) | S3 backend bootstrap |

---

---

## License

Open source for portfolio and educational use.

---

## Author

- GitHub: [@rahul6364](https://github.com/rahul6364) · [Expense-Tracker-AWS](https://github.com/rahul6364/Expense-Tracker-AWS)
