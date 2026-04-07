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

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# TASK 1: Create a Custom VPC (Student Name + Roll Number)
# ============================================================

resource "aws_vpc" "lab7_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "HaseenUllah-22MDSWE238-VPC"
  }
}

# ============================================================
# TASK 3: Attach Internet Gateway to the VPC
# ============================================================

resource "aws_internet_gateway" "lab7_igw" {
  vpc_id = aws_vpc.lab7_vpc.id

  tags = {
    Name = "Lab7-IGW"
  }
}

# ============================================================
# TASK 2: Create Public and Private Subnets
# ============================================================

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
  vpc_id            = aws_vpc.lab7_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Lab7-Private-Subnet"
  }
}

# ============================================================
# TASK 4: Attach Route Tables to Public and Private Subnets
# ============================================================

# --- Public Route Table ---
# Routes internet-bound traffic (0.0.0.0/0) through the Internet Gateway

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

resource "aws_route_table_association" "lab7_public_rta" {
  subnet_id      = aws_subnet.lab7_public_subnet.id
  route_table_id = aws_route_table.lab7_public_rt.id
}

# --- Private Route Table ---
# No internet route — instances in this subnet are isolated from the internet

resource "aws_route_table" "lab7_private_rt" {
  vpc_id = aws_vpc.lab7_vpc.id

  tags = {
    Name = "Lab7-Private-RT"
  }
}

resource "aws_route_table_association" "lab7_private_rta" {
  subnet_id      = aws_subnet.lab7_private_subnet.id
  route_table_id = aws_route_table.lab7_private_rt.id
}

# ============================================================
# SECURITY GROUP: Demonstrates traffic control within the VPC
# ============================================================

resource "aws_security_group" "lab7_public_sg" {
  name        = "lab7-public-sg-${random_id.suffix.hex}"
  description = "Allow SSH and HTTP from the internet (public subnet)"
  vpc_id      = aws_vpc.lab7_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Lab only — restrict in production
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab7-Public-SG"
  }
}

resource "aws_security_group" "lab7_private_sg" {
  name        = "lab7-private-sg-${random_id.suffix.hex}"
  description = "Allow traffic only from within the VPC (private subnet)"
  vpc_id      = aws_vpc.lab7_vpc.id

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab7-Private-SG"
  }
}

# ============================================================
# IMPORTANT: Destroy resources after lab to avoid billing
# ============================================================
# Run: Actions → Deploy Labs → Lab 7 → aws → destroy
