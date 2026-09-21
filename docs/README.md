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

Project screenshot placeholders are kept beside the relevant explanations in the root [README.md](../README.md). Capture evidence from the deployed AWS account and application, then save the files under `docs/screenshots/` using the filenames specified in those placeholders.

The existing `docs/images/architecture-diagram.png` is the repository architecture image. Do not create empty files or use stock/AI-generated images for deployment evidence.
