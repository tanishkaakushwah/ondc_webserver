vpc_cidr = "10.1.0.0/16"

public_subnets = [
  "10.1.1.0/24",
  "10.1.2.0/24"
]

private_subnets = [
  "10.1.3.0/24",
  "10.1.4.0/24"
]

instance_type = "t3.small"

desired_capacity = 3
min_size = 2
max_size = 6
environment = "prod"