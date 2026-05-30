variable "project_name" {
  type        = string
  description = "The name of the project"
}
# variable "profile" {
#   type        = string
#   description = "The profile to use for the AWS CLI"
# }

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
}
variable "web_public_subnet_az1_cidr" {
  type        = string
  description = "The CIDR block for the web public subnet in availability zone 1"
}
variable "web_public_subnet_az2_cidr" {
  type        = string
  description = "The CIDR block for the web public subnet in availability zone 2"
}
variable "app_private_subnet_az1_cidr" {
  type        = string
  description = "The CIDR block for the app private subnet in availability zone 1"
}
variable "app_private_subnet_az2_cidr" {
  type        = string
  description = "The CIDR block for the app private subnet in availability zone 2"
}
variable "db_private_subnet_az1_cidr" {
  type        = string
  description = "The CIDR block for the db private subnet in availability zone 1"
}
variable "db_private_subnet_az2_cidr" {
  type        = string
  description = "The CIDR block for the db private subnet in availability zone 2"
}
variable "region" {
  type        = string
  description = "The region to deploy the resources to"
}
variable "availability_zone_1" {
  type        = string
  description = "The availability zone for the web public subnet"
}
variable "availability_zone_2" {
  type        = string
  description = "The availability zone for the web public subnet"
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
