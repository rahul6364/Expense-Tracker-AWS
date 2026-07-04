terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.10.0"
  backend "s3" {
    bucket       = "rahul-expense-tracker-tf-state"
    key          = "terraform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}