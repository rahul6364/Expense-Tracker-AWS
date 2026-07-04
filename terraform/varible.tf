variable "project_name" {
  type        = string
  description = "The name of the project"
  default     = "expense-tracker"
}
# variable "profile" {
#   type        = string
#   description = "The profile to use for the AWS CLI"
# }

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
variable "web_public_subnet_az1_cidr" {
  type        = string
  description = "The CIDR block for the web public subnet in availability zone 1"
  default     = "10.0.1.0/24"
}
variable "web_public_subnet_az2_cidr" {
  type        = string
  description = "The CIDR block for the web public subnet in availability zone 2"
  default     = "10.0.2.0/24"
}
variable "app_private_subnet_az1_cidr" {
  type        = string
  description = "The CIDR block for the app private subnet in availability zone 1"
  default     = "10.0.3.0/24"
}
variable "app_private_subnet_az2_cidr" {
  type        = string
  description = "The CIDR block for the app private subnet in availability zone 2"
  default     = "10.0.4.0/24"
}
variable "db_private_subnet_az1_cidr" {
  type        = string
  description = "The CIDR block for the db private subnet in availability zone 1"
  default     = "10.0.5.0/24"
}
variable "db_private_subnet_az2_cidr" {
  type        = string
  description = "The CIDR block for the db private subnet in availability zone 2"
  default     = "10.0.6.0/24"
}
variable "region" {
  type        = string
  description = "The region to deploy the resources to"
  default     = "us-east-1"
}
variable "availability_zone_1" {
  type        = string
  description = "The availability zone for the web public subnet"
  default     = "us-east-1a"
}
variable "availability_zone_2" {
  type        = string
  description = "The availability zone for the web public subnet"
  default     = "us-east-1b"
}
variable "db_user" {
  type        = string
  description = "The username for the db"
}
variable "db_password" {
  type        = string
  description = "The password for the db"
  sensitive   = true
}
# variable "rds_endpoint" {
#   type        = string
#   description = "The endpoint for the rds"
# }
