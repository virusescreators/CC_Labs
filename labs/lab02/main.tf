terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
}

# --- Regional Service: VPC ---
resource "aws_vpc" "lab2_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Lab2-Regional-VPC"
  }
}

# --- AZ-Specific Service: Subnet ---
# We deliberately pick a specific AZ to show dependency
resource "aws_subnet" "lab2_subnet" {
  vpc_id            = aws_vpc.lab2_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Lab2-Subnet-US-East-1A"
  }
}

# --- Regional Service: S3 Bucket ---
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "lab2_bucket" {
  bucket = "lab2-regional-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Lab2-Regional-Bucket"
    Description = "S3 Buckets are Regional"
  }
}

# --- Global Service: IAM Group ---
resource "aws_iam_group" "lab2_global_group" {
  name = "Lab2-Global-Group"
}
