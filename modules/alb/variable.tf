variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "alb_security_group" {
  type = string
}

variable "log_bucket" {
  type = string
}
variable "environment" {
  type = string
}