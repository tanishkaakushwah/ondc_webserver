terraform {
  backend "s3" {
    bucket         = "terraform-ondc-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock-table"
  }
}