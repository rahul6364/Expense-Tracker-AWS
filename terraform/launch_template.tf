resource "aws_launch_template" "frontend_lt" {
  name_prefix            = "frontend-launch-template"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  user_data = base64encode(file("scripts/frontend.sh"))
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "frontend-launch-template"
    }
  }

}
resource "aws_launch_template" "backend_lt" {
  name_prefix            = "backend-launch-template"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  user_data = base64encode(templatefile("${path.module}/scripts/backend.sh", {
    db_host     = aws_db_instance.mysql_rds.address
    db_user     = var.db_user
    db_password = var.db_password
  }))
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "backend-launch-template"
    }
  }

}
