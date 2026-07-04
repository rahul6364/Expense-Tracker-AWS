resource "aws_autoscaling_group" "frontend_asg" {
  name                = "frontend-asg"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = [aws_subnet.app_private_subnet_az1.id, aws_subnet.app_private_subnet_az2.id]
  target_group_arns = [
    aws_lb_target_group.frontend_tg.arn
  ]
  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "frontend-asg-instance"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_group" "backend_asg" {
  name                = "backend-asg"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = [aws_subnet.app_private_subnet_az1.id, aws_subnet.app_private_subnet_az2.id]
  target_group_arns = [
    aws_lb_target_group.backend_tg.arn
  ]
  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "backend-asg-instance"
    propagate_at_launch = true
  }
}
