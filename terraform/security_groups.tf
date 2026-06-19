resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for the ALB"
  vpc_id      = aws_vpc.main.id
}
resource "aws_vpc_security_group_ingress_rule" "alb_sg_ingress_rule_http" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTP traffic from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "alb_sg_ingress_rule_https" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTPS traffic from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "alb_sg_egress_rule" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow all traffic out of the ALB"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "frontend_sg" {
  description = "Security group for the frontend"
  name        = "frontend-sg"
  vpc_id      = aws_vpc.main.id
}
resource "aws_vpc_security_group_ingress_rule" "frontend_sg_ingress_rule_http" {
  security_group_id            = aws_security_group.frontend_sg.id
  description                  = "Allow HTTP traffic from the ALB"
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "frontend_sg_egress_rule" {
  security_group_id = aws_security_group.frontend_sg.id
  description       = "Allow all traffic out of the frontend"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Security group for the backend"
  vpc_id      = aws_vpc.main.id
}
resource "aws_vpc_security_group_ingress_rule" "backend_sg_ingress_rule_http" {
  security_group_id            = aws_security_group.backend_sg.id
  description                  = "Allow HTTP traffic from the ALB"
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 4000
  to_port                      = 4000
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "backend_sg_egress_rule" {
  security_group_id = aws_security_group.backend_sg.id
  description       = "Allow all traffic out of the backend"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for the RDS"
  vpc_id      = aws_vpc.main.id
}
resource "aws_vpc_security_group_ingress_rule" "rds_sg_ingress_rule_mysql" {
  security_group_id            = aws_security_group.rds_sg.id
  description                  = "Allow MySQL traffic from the backend"
  referenced_security_group_id = aws_security_group.backend_sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "rds_sg_egress_rule" {
  security_group_id = aws_security_group.rds_sg.id
  description       = "Allow all traffic out of the RDS"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
