# Terraform Deployment Guide

End-to-end deployment of the Expense Tracker on AWS using Infrastructure as Code. After `terraform apply`, EC2 user data installs Docker, pulls images, and starts the application — **no manual Console steps or SQL scripts required**.

---

## Table of Contents

1. [What Terraform creates](#what-terraform-creates)
2. [Prerequisites](#prerequisites)
3. [Pre-deploy: Docker images](#pre-deploy-docker-images)
4. [Configure variables](#configure-variables)
5. [terraform init](#terraform-init)
6. [terraform validate](#terraform-validate)
7. [terraform plan](#terraform-plan)
8. [terraform apply](#terraform-apply)
9. [Verification steps](#verification-steps)
10. [Updating the application](#updating-the-application)
11. [terraform destroy](#terraform-destroy)
12. [Troubleshooting](#troubleshooting)

---

## What Terraform creates

| Category | Resources |
|----------|-----------|
| Network | VPC, 6 subnets, IGW, 2× NAT + EIP, route tables |
| Security | ALB, frontend, backend, RDS security groups |
| Load balancing | ALB `expenses-alb`, `frontend-tg`, `backend-tg`, `/api/*` rule |
| Compute | Launch templates, ASGs `frontend-asg` / `backend-asg` |
| Database | RDS MySQL `expense-tracker-db`, DB subnet group |
| IAM | EC2 instance profile for SSM |

**Application bootstrap:** Backend container runs `bootstrap.js` → creates `transactions` table if missing.

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| AWS account | IAM permissions for VPC, EC2, ELB, RDS, IAM |
| AWS CLI | `aws configure` with valid credentials |
| Terraform | 1.x ([install](https://developer.hashicorp.com/terraform/install)) |
| Docker | Local build/push to Docker Hub |
| Docker Hub images | Must exist **before** EC2 boots (see below) |

**Estimated first apply time:** 15–25 minutes (RDS is slowest).

---

## Pre-deploy: Docker images

Terraform does **not** build images. User data pulls from Docker Hub:

| Image | Used by |
|-------|---------|
| `rahul6364/expense-tracker-web:latest` | Frontend ASG |
| `rahul6364/expense-tracker-api:latest` | Backend ASG |

### Build and push

```bash
# Backend (includes bootstrap.js)
cd backend
docker build -t rahul6364/expense-tracker-api:latest .
docker push rahul6364/expense-tracker-api:latest

# Frontend — empty VITE_API_URL for same-origin /api/* via ALB
cd ../frontend
docker build --build-arg VITE_API_URL= -t rahul6364/expense-tracker-web:latest .
docker push rahul6364/expense-tracker-web:latest
```

Update image names in `terraform/scripts/frontend.sh` and `backend.sh` if you use a different registry.

---

## Configure variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` (gitignored — never commit):

| Variable | Example | Purpose |
|----------|---------|---------|
| `project_name` | `expense-tracker` | Resource naming |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR |
| `*_cidr` | See example file | Subnet CIDRs |
| `region` | `us-east-1` | AWS region |
| `availability_zone_1/2` | `us-east-1a/b` | AZ placement |
| `db_user` | `admin` | RDS master user |
| `db_password` | Strong secret | RDS master password |

---

## terraform init

Downloads the AWS provider and initializes the backend.

```bash
cd terraform
terraform init
```

**Expected output:** `Terraform has been successfully initialized!`

If provider version changes, run `terraform init -upgrade`.

---

## terraform validate

Checks configuration syntax without contacting AWS (provider must be installed from `init`).

```bash
terraform validate
```

**Expected output:** `Success! The configuration is valid.`

Fix any reported errors before planning.

---

## terraform plan

Preview changes before applying.

```bash
terraform plan
```

Save a plan file (optional, recommended for review):

```bash
terraform plan -out=tfplan
```

Review the plan for:

- ~6 subnets, 2 NAT gateways, 1 ALB, 2 ASGs, 1 RDS instance
- Security group rules (ALB → EC2, backend → RDS)
- No unexpected destroys if re-running on existing state

---

## terraform apply

### Interactive

```bash
terraform apply
```

Type `yes` when prompted.

### Using saved plan

```bash
terraform apply tfplan
```

![Terraform apply completed](images/terraform-apply-success.png)

### Outputs

```bash
terraform output alb_dns_name
terraform output application_url
terraform output rds_endpoint
```

Example:

```
application_url = "http://expenses-alb-123456789.us-east-1.elb.amazonaws.com/"
```

---

## Verification steps

Allow **10–15 minutes** after apply for RDS, EC2 user data (Docker install/pull), and ALB health checks.

### 1. Target groups healthy

AWS Console → EC2 → Target Groups → `frontend-tg` and `backend-tg` → **Targets** tab.

| Target group | Port | Health path | Expected |
|--------------|------|-------------|----------|
| frontend-tg | 80 | `/` | healthy |
| backend-tg | 4000 | `/health` | healthy |

![ALB healthy targets](images/alb-healthy.png)

### 2. HTTP checks from your machine

```bash
ALB=$(terraform output -raw alb_dns_name)

curl -s "http://${ALB}/health"
# Frontend nginx health (if exposed via ALB default — use target group check on instance)

curl -s "http://${ALB}/api/transactions"
# Expect JSON array (possibly empty [])
```

### 3. Open the application

```bash
terraform output application_url
```

Open in browser — add a transaction and confirm it persists.

![Application dashboard](images/app-dashboard.png)

### 4. Verify Docker on instances (SSM)

Instances use IAM profile with SSM. No SSH key required.

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=backend-asg-instance" \
  --query "Reservations[].Instances[].InstanceId" --output text
```

In **Session Manager** on the backend instance:

```bash
sudo docker ps
sudo docker logs backend
```

Look for:

```
Database connected successfully.
Transactions table verified.
```
or `Transactions table created.`

![Docker containers running](images/ec2-docker-ps.png)

### 5. RDS (optional)

Console → RDS → `expense-tracker-db` → confirm **Publicly accessible: No**.

![RDS instance](images/rds-instance.png)

---

## Updating the application

1. Rebuild and push Docker image(s).
2. Refresh ASG instances:

```bash
aws autoscaling start-instance-refresh --auto-scaling-group-name backend-asg
aws autoscaling start-instance-refresh --auto-scaling-group-name frontend-asg
```

Or terminate instances; ASG replaces them and re-runs user data.

For infrastructure changes: `terraform plan` → `terraform apply`.

---

## terraform destroy

Removes all Terraform-managed resources.

```bash
cd terraform
terraform destroy
```

Type `yes` to confirm.

**Warning:** RDS uses `skip_final_snapshot = true` — **all database data is deleted**.

---

## Troubleshooting

Quick reference — full guide: [troubleshooting.md](troubleshooting.md).

| Symptom | Likely cause |
|---------|----------------|
| Target unhealthy | User data still running; wrong health path; container crashed |
| 502 Bad Gateway | Backend not listening on 4000 |
| Empty API / CORS | Frontend built without same-origin `/api` routing |
| DB connection errors | RDS not ready when container started; SG or wrong `DB_*` env |
| Image pull failed | Image missing on Docker Hub or wrong name in user data |

---

## Terraform file reference

| File | Purpose |
|------|---------|
| `provider.tf` | AWS provider ~> 6.0 |
| `varible.tf` | Input variables |
| `main.tf` | VPC, subnets, IGW, NAT |
| `route_table.tf` | Route tables and associations |
| `security_groups.tf` | ALB, frontend, backend, RDS SGs |
| `data.tf` | Ubuntu 22.04 AMI |
| `iam.tf` | EC2 role + SSM |
| `rds.tf` | RDS MySQL |
| `alb.tf` | ALB, target groups, listener rules |
| `launch_template.tf` | Launch templates + user data |
| `asg.tf` | Auto Scaling Groups |
| `output.tf` | ALB URL, RDS endpoint |
| `scripts/frontend.sh` | Docker bootstrap (frontend) |
| `scripts/backend.sh` | Docker bootstrap (backend + RDS env) |

---

## Related documentation

- [architecture.md](architecture.md)
- [aws-setup.md](aws-setup.md) — Manual equivalent
- [README.md](README.md) — Doc index and screenshot checklist
