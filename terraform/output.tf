output "rds_endpoint" {
  description = "RDS MySQL hostname (private)"
  value       = aws_db_instance.mysql_rds.address #gives the private url of the database
}

output "alb_dns_name" {
  description = "DNS name of the external Application Load Balancer"
  value       = aws_lb.expense_alb.dns_name
}

output "application_url" {
  description = "URL to open the expense tracker in a browser"
  value       = "http://${aws_lb.expense_alb.dns_name}/" #gives the public url of the application
}