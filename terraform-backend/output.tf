output "terraform_state_bucket" {
  description = "The name of the S3 bucket used to store the Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}