# Terraform Remote State Backend (Bootstrap)

Creates the S3 bucket used to store Terraform state for this project. State locking uses **S3 native lock files** (`use_lockfile = true`) — no DynamoDB table required.

## Why `terraform init` failed

Terraform tries to connect to the S3 backend **before** the bucket exists. This is a one-time bootstrap problem: create the bucket with **local state** first, then migrate to S3.

## Bootstrap (first time only)

Run from this directory:

```bash
# Step 1: Init without configuring the remote backend
terraform init -backend=false

# Step 2: Create the S3 bucket (state stays local for this run)
terraform apply

# Step 3: Migrate local state into S3 and enable the backend
terraform init -migrate-state
```

When prompted to copy existing state to the new backend, type **yes**.

## Normal usage (after bootstrap)

```bash
terraform init
terraform plan
terraform apply
```

## Use this backend from `terraform/`

After bootstrap, add to `terraform/provider.tf` (or a `backend.tf`):

```hcl
terraform {
  backend "s3" {
    bucket       = "rahul-expense-tracker-tf-state"
    key          = "terraform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Then in `terraform/`:

```bash
terraform init -migrate-state   # first time only, if you have existing local state
terraform init                # subsequent runs
```

## Bucket details

| Setting | Value |
|---------|-------|
| Bucket | `rahul-expense-tracker-tf-state` |
| Backend state key | `terraform-backend/terraform.tfstate` |
| App state key (recommended) | `terraform/terraform.tfstate` |
| Region | `us-east-1` |
| Versioning | Enabled |
| Encryption | AES256 |
| Locking | S3 `use_lockfile` |

## Destroy

Only destroy this stack if no other Terraform configurations still depend on the bucket.

```bash
terraform destroy
```
