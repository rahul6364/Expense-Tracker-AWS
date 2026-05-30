# Documentation Index

Welcome to the Expense Tracker AWS 3-tier project documentation. This repository documents two deployment paths that produce the **same architecture** with different provisioning methods.

---

## Choose your path

| I want to… | Read this |
|------------|-----------|
| Deploy everything with one `terraform apply` | [terraform-deployment.md](terraform-deployment.md) |
| Learn AWS by building step-by-step in the Console | [aws-setup.md](aws-setup.md) |
| Understand VPC, ALB, tiers, and request flow | [architecture.md](architecture.md) |
| Debug unhealthy targets, 502s, or DB errors | [troubleshooting.md](troubleshooting.md) |
| Review security groups and network isolation | [security-architecture.md](security-architecture.md) |
| Quick Terraform commands | [../terraform/README.md](../terraform/README.md) |

---

## Project evolution

| Phase | What changed |
|-------|----------------|
| **Phase 1 — Manual AWS** | VPC, ALB, RDS, ASGs, and Docker configured via Console ([aws-setup.md](aws-setup.md)) |
| **Phase 2 — IaC** | Full stack codified in `terraform/` with EC2 user data |
| **Phase 3 — Self-healing app** | `backend/bootstrap.js` creates schema on startup — no manual SQL |

---

## Document map

| File | Contents |
|------|----------|
| [architecture.md](architecture.md) | Mermaid diagrams, request flows, VPC/NAT/SG design |
| [terraform-deployment.md](terraform-deployment.md) | `init` → `validate` → `plan` → `apply` → verify → `destroy` |
| [aws-setup.md](aws-setup.md) | Manual Console deployment (learning / reference) |
| [troubleshooting.md](troubleshooting.md) | ALB, RDS, Docker, database errors |
| [security-architecture.md](security-architecture.md) | Defense in depth, SG matrix |

---

## Screenshots

Place captured images in `docs/images/`. See **[Screenshot Placement Checklist](#screenshot-placement-checklist)** below for exact filenames and where each image is referenced in the docs.

---

## Screenshot Placement Checklist

Capture these from **your** AWS account and application after a successful deploy. Do not use stock or AI-generated images.

| # | Save as `docs/images/…` | Capture this | Referenced in |
|---|-------------------------|--------------|---------------|
| 1 | `architecture-diagram.png` | draw.io / Lucidchart export of full 3-tier diagram (optional if using Mermaid in GitHub only) | [README.md](../README.md), [architecture.md](architecture.md) |
| 2 | `vpc-subnets.png` | VPC console → Subnets list showing 2 public + 4 private | [README.md](../README.md) |
| 3 | `alb-overview.png` | EC2 → Load Balancers → `expenses-alb` → Description tab | [README.md](../README.md), [terraform-deployment.md](terraform-deployment.md) |
| 4 | `alb-healthy.png` | EC2 → Target Groups → both groups → Targets tab, status **healthy** | [README.md](../README.md), [terraform-deployment.md](terraform-deployment.md), [troubleshooting.md](troubleshooting.md) |
| 5 | `alb-listener-rules.png` | ALB → Listeners → Rules showing `/api/*` → backend, default → frontend | [README.md](../README.md), [architecture.md](architecture.md) |
| 6 | `rds-instance.png` | RDS → `expense-tracker-db` → Connectivity & security (endpoint, private) | [README.md](../README.md) |
| 7 | `asg-instances.png` | EC2 → Auto Scaling Groups → `frontend-sg` / `backend-sg` → Instance management | [README.md](../README.md) |
| 8 | `ec2-docker-ps.png` | SSM Session Manager on backend instance → `sudo docker ps` showing running containers | [terraform-deployment.md](terraform-deployment.md) |
| 9 | `app-dashboard.png` | Browser → ALB URL → dashboard with balance cards | [README.md](../README.md) |
| 10 | `app-transactions.png` | Browser → transaction list with sample data | [README.md](../README.md) |
| 11 | `app-chart.png` | Browser → 6-month spending chart visible | [README.md](../README.md) |
| 12 | `terraform-apply-success.png` | Terminal → `terraform apply` completed with outputs | [README.md](../README.md), [terraform-deployment.md](terraform-deployment.md) |

### How to capture

1. Deploy with [terraform-deployment.md](terraform-deployment.md).
2. Wait until target groups are healthy (~10–15 minutes first time).
3. Save PNG files **exactly** as named above into `docs/images/`.
4. Commit images to Git (or keep local for portfolio PDF).

### Markdown syntax used in docs

```markdown
![Short description](images/filename.png)
```

Paths are relative to the `docs/` folder (e.g. `docs/images/alb-healthy.png` → `images/alb-healthy.png` inside markdown files under `docs/`). In root `README.md`, use `docs/images/filename.png`.
