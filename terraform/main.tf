resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "web_public_subnet_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.web_public_subnet_az1_cidr
  availability_zone = var.availability_zone_1
  tags = {
    Name = "web-public-subnet-az1"
  }
}
resource "aws_subnet" "web_public_subnet_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.web_public_subnet_az2_cidr
  availability_zone = var.availability_zone_2
  tags = {
    Name = "web-public-subnet-az2"
  }
}
resource "aws_subnet" "app_private_subnet_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_private_subnet_az1_cidr
  availability_zone = var.availability_zone_1
  tags = {
    Name = "app-private-subnet-az1"
  }
}
resource "aws_subnet" "app_private_subnet_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_private_subnet_az2_cidr
  availability_zone = var.availability_zone_2
  tags = {
    Name = "app-private-subnet-az2"
  }
}
resource "aws_subnet" "db_private_subnet_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_private_subnet_az1_cidr
  availability_zone = var.availability_zone_1
  tags = {
    Name = "db-private-subnet-az1"
  }
}
resource "aws_subnet" "db_private_subnet_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_private_subnet_az2_cidr
  availability_zone = var.availability_zone_2
  tags = {
    Name = "db-private-subnet-az2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}
resource "aws_eip" "nat_az1_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags       = { Name = "${var.project_name}-nat-eip" }
}
resource "aws_eip" "nat_az2_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags       = { Name = "${var.project_name}-nat-eip" }
}
resource "aws_nat_gateway" "nat_az1_gateway" {
  allocation_id = aws_eip.nat_az1_eip.id
  subnet_id     = aws_subnet.web_public_subnet_az1.id # Placed in public subnet to access internet
  tags          = { Name = "${var.project_name}-nat-gw" }
}
resource "aws_nat_gateway" "nat_az2_gateway" {
  allocation_id = aws_eip.nat_az2_eip.id
  subnet_id     = aws_subnet.web_public_subnet_az2.id # Placed in public subnet to access internet
  tags          = { Name = "${var.project_name}-nat-gw" }
}
