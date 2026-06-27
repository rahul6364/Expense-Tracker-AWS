resource "aws_s3_bucket" "terraform_state" {
  bucket        = "rahul-expense-tracker-tf-state"
  force_destroy = false
  tags = {
    Name        = "terraform-state-bucket"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "Expense-Tracker"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# terraform {
#   required_version = ">= 1.10.0"

#   backend "s3" {
#     bucket       = "rahul-expense-tracker-tf-state"
#     key          = "expense-tracker/terraform.tfstate"
#     region       = "us-east-1"
#     encrypt      = true
#     use_lockfile = true
#   }
# }
