data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "frontend" {
  name_prefix   = "${var.project_name}-${var.environment}-frontend-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    set -euxo pipefail

    dnf install -y docker awscli
    systemctl enable --now docker

    aws ecr get-login-password --region ap-south-1 \
      | docker login --username AWS --password-stdin \
        555509860178.dkr.ecr.ap-south-1.amazonaws.com

    IMAGE_URI="555509860178.dkr.ecr.ap-south-1.amazonaws.com/peoplehub-frontend:latest"

    docker pull "$IMAGE_URI"
    docker run -d \
      --name peoplehub-frontend \
      --restart unless-stopped \
      -p 80:80 \
      "$IMAGE_URI"
  USERDATA
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-frontend"
      Environment = var.environment
      Project     = var.project_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "frontend" {
  name                = "${var.project_name}-${var.environment}-frontend-asg"
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.frontend.id
    version = aws_launch_template.frontend.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-frontend"
    propagate_at_launch = true
  }
}
