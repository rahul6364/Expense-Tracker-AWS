resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "expens-tracker-db-subent-group"
  subnet_ids = [
    aws_subnet.db_private_subnet_az1.id,
    aws_subnet.db_private_subnet_az2.id
  ]
  tags = {
    name = "expens-tracker-db-subent-group"
  }
}

resource "aws_db_instance" "mysql_rds" {
  identifier = "expense-tracker-db"

  allocated_storage = 20
  storage_type      = "gp2"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = "db.t3.micro"

  db_name  = "expense_tracker"
  username = var.db_user
  password = var.db_password

  publicly_accessible = false

  multi_az = false

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]

  skip_final_snapshot = true

  tags = {
    Name = "expense-tracker-rds"
  }
}