resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {

  alarm_name          = "ondc-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_description = "Alarm when EC2 CPU exceeds 70%"
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "ondc-alb-access-logs-${random_id.rand.hex}"

  force_destroy = true
}

resource "random_id" "rand" {
  byte_length = 4
}

resource "aws_s3_bucket_policy" "alb_logs_policy" {

  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}