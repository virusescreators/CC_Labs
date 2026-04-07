terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
}

# ============================================================
# NETWORKING: VPC, Subnets, Internet Gateway, Route Tables
# ============================================================

resource "aws_vpc" "lab7_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Lab7-Haseen-VPC"
  }
}

resource "aws_subnet" "lab7_public_subnet" {
  vpc_id                  = aws_vpc.lab7_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab7-Public-Subnet"
  }
}

resource "aws_subnet" "lab7_private_subnet" {
  vpc_id                  = aws_vpc.lab7_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Lab7-Private-Subnet"
  }
}

resource "aws_internet_gateway" "lab7_igw" {
  vpc_id = aws_vpc.lab7_vpc.id

  tags = {
    Name = "Lab7-IGW"
  }
}

resource "aws_route_table" "lab7_public_rt" {
  vpc_id = aws_vpc.lab7_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab7_igw.id
  }

  tags = {
    Name = "Lab7-Public-RT"
  }
}

resource "aws_route_table" "lab7_private_rt" {
  vpc_id = aws_vpc.lab7_vpc.id

  tags = {
    Name = "Lab7-Private-RT"
  }
}

resource "aws_route_table_association" "lab7_public_rta" {
  subnet_id      = aws_subnet.lab7_public_subnet.id
  route_table_id = aws_route_table.lab7_public_rt.id
}

resource "aws_route_table_association" "lab7_private_rta" {
  subnet_id      = aws_subnet.lab7_private_subnet.id
  route_table_id = aws_route_table.lab7_private_rt.id
}
