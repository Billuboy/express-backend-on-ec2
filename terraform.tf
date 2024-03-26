terraform {
  required_version = ">= 1.7.4"

  # Local backend configuration for tf state.
  backend "local" {
    path = "./tfstate/terraform.tfstate"
  }

  # S3 backend configuration for tf state.
  # Before configuring a bucket to store tf state, please make sure the bucket:
  # 1. Has versioning enabled
  # 2. Has all public access blocked to it
  # 3. Only certain can access the bucket through proper bucket policy
  # backend "s3" {
  #   bucket = "express-lambda-tf-state-bucket"
  #   key    = "terraform.tfstate"
  #   region = "ap-south-1"

  #   # S3 backend uses DynamoDB table for state locking and consistency
  #   # dynamodb_table = "value"
  # }

  # Remote backend configuration for tf state.
  # Remote backend runs on Terraform Cloud. 
  # Please make sure to create an account and login via that account in your system via `terraform login` CLI command. 
  # backend "remote" {
  #   hostname = "app.terraform.io"
  #   organization = "manujk171801"

  #   workspaces {
  #     name = "lambda-workflow"
  #   }
  # }

  required_providers {
    aws = {
      version = "= 5.42.0"
      source  = "hashicorp/aws"
    }
  }
}