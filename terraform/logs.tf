resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/expense-tracker/frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/expense-tracker/backend"
  retention_in_days = 7
}