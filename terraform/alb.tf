#checkov:skip=CKV_AWS_378: Backend communication remains HTTP inside private VPC

resource "aws_lb_target_group" "frontend_tg" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "frontend-tg"
  }
}
#checkov:skip=CKV_AWS_378: Backend communication remains HTTP inside private VPC

resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "instance"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "backend-tg"
  }
}
#checkov:skip=CKV2_AWS_28: WAF omitted for portfolio project to avoid additional cost

resource "aws_lb" "expense_alb" {
  name               = "expenses-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [aws_subnet.web_public_subnet_az1.id,
  aws_subnet.web_public_subnet_az2.id]

  enable_deletion_protection = false

  tags = {
    Name = "Expenses-tracker-alb"
  }
}
#checkov:skip=CKV_AWS_2: HTTPS will be implemented in a later phase using ACM certificates
#checkov:skip=CKV_AWS_103: TLS policy not applicable until HTTPS listener is configured
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.expense_alb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http_listener.arn

  priority = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}