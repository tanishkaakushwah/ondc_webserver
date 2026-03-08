# Application Load Balancer

resource "aws_lb" "alb" {
  name = "ondc-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.alb_security_group]
  subnets         = var.public_subnets

  access_logs {
  bucket  = var.log_bucket
  enabled = true
}

  tags = {
    Name = "ondc-${var.environment}-alb"

  }
}

# Target Group

resource "aws_lb_target_group" "tg" {
  name     = "ondc-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name = "ondc-target-group"
  }
}

# Listener

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}