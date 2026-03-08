resource "aws_iam_role" "ec2_role" {
  name = "ondc-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ondc-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Get Latest Ubuntu AMI

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Launch Template

resource "aws_launch_template" "web" {

  name_prefix   = "ondc-web-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.ec2_security_group]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      encrypted   = true
      volume_size = 10
    }
  }

  user_data = base64encode(file("${path.module}/../../scripts/user_data.sh"))
}

# Auto Scaling Group

resource "aws_autoscaling_group" "web_asg" {

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  vpc_zone_identifier = var.private_subnets

  health_check_type = "ELB"

  target_group_arns = [
    var.target_group_arn
  ]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ondc-${var.environment}-web"
    propagate_at_launch = true
  }
}

# Scaling Group

resource "aws_autoscaling_policy" "cpu_scaling" {

  name                   = "cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60
  }
}