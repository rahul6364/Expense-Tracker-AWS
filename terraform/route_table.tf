resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}
resource "aws_route_table" "private_az1" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_az1_gateway.id
  }
  tags = { Name = "private-az1-rt" }
}
resource "aws_route_table" "private_az2" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_az2_gateway.id
  }
  tags = { Name = "private-az2-rt" }
}
resource "aws_route_table_association" "public_az1_association" {
  subnet_id      = aws_subnet.web_public_subnet_az1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_az2_association" {
  subnet_id      = aws_subnet.web_public_subnet_az2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private_az1_association" {
  subnet_id      = aws_subnet.app_private_subnet_az1.id
  route_table_id = aws_route_table.private_az1.id
}
resource "aws_route_table_association" "private_az2_association" {
  subnet_id      = aws_subnet.app_private_subnet_az2.id
  route_table_id = aws_route_table.private_az2.id
}
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-db-rt"
  }
}
resource "aws_route_table_association" "private_db_az1_association" {
  subnet_id      = aws_subnet.db_private_subnet_az1.id
  route_table_id = aws_route_table.private_db.id
}
resource "aws_route_table_association" "private_db_az2_association" {
  subnet_id      = aws_subnet.db_private_subnet_az2.id
  route_table_id = aws_route_table.private_db.id
}