# Terraform — Expense Tracker AWS Stack

Provisions the complete 3-tier stack. See **[../docs/terraform-deployment.md](../docs/terraform-deployment.md)** for the full guide.

## Quick commands

```bash
cp terraform.tfvars.example terraform.tfvars   # edit secrets
terraform init
terraform validate
terraform plan
terraform apply
terraform output application_url
terraform destroy   # tears down everything
```

## Before apply

1. Push `rahul6364/expense-tracker-web:latest` and `rahul6364/expense-tracker-api:latest` to Docker Hub.
2. Configure AWS credentials.
3. Never commit `terraform.tfvars`.

## Outputs

| Output | Description |
|--------|-------------|
| `application_url` | Open in browser |
| `alb_dns_name` | ALB hostname |
| `rds_endpoint` | MySQL host (private) |
