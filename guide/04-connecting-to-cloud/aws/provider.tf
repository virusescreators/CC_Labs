terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region

  # Credentials are read from:
  # 1. Environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
  # 2. ~/.aws/credentials file (configured via `aws configure`)
  # 3. IAM instance profile (when running on EC2)
  # Never hardcode credentials here!
}
