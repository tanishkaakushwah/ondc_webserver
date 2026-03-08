module "network" {
  source = "../../modules/network"
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

module "security" {
  source = "../../modules/security"
  environment     = var.environment
  vpc_id = module.network.vpc_id
}

module "alb" {
  source = "../../modules/alb"
  environment     = var.environment
  vpc_id              = module.network.vpc_id
  public_subnets      = module.network.public_subnets
  alb_security_group  = module.security.alb_security_group
  log_bucket          = module.observability.log_bucket
}

module "compute" {
  source = "../../modules/compute"
  environment     = var.environment
  vpc_id           = module.network.vpc_id
  private_subnets  = module.network.private_subnets
  target_group_arn = module.alb.target_group_arn

  ec2_security_group = module.security.ec2_security_group

  instance_type    = var.instance_type
  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size
}

module "observability" {
  source = "../../modules/observability"
  asg_name = module.compute.asg_name
  alb_arn  = module.alb.alb_dns_name
}