# backend.tf
terraform {
  backend "s3" {
    bucket         = "datalake-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}