terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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
# DATA: Latest Amazon Linux 2023 AMI
# ============================================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# ============================================================
# VPC & Networking
# ============================================================

resource "aws_vpc" "lab9_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab9-VPC"
  }
}

resource "aws_internet_gateway" "lab9_igw" {
  vpc_id = aws_vpc.lab9_vpc.id

  tags = {
    Name = "Lab9-IGW"
  }
}

# Subnet 1 (AZ: us-east-1a)
resource "aws_subnet" "lab9_subnet_1" {
  vpc_id                  = aws_vpc.lab9_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab9-Subnet-1"
  }
}

# Subnet 2 (AZ: us-east-1b)
resource "aws_subnet" "lab9_subnet_2" {
  vpc_id                  = aws_vpc.lab9_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab9-Subnet-2"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "lab9_public_rt" {
  vpc_id = aws_vpc.lab9_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab9_igw.id
  }

  tags = {
    Name = "Lab9-Public-RT"
  }
}

resource "aws_route_table_association" "lab9_rta_1" {
  subnet_id      = aws_subnet.lab9_subnet_1.id
  route_table_id = aws_route_table.lab9_public_rt.id
}

resource "aws_route_table_association" "lab9_rta_2" {
  subnet_id      = aws_subnet.lab9_subnet_2.id
  route_table_id = aws_route_table.lab9_public_rt.id
}

# ============================================================
# SECURITY GROUPS
# ============================================================

# Security Group for Load Balancer (Allows HTTP from anywhere)
resource "aws_security_group" "lab9_alb_sg" {
  name        = "lab9-alb-sg-${random_id.suffix.hex}"
  description = "Allow HTTP inbound traffic for ALB"
  vpc_id      = aws_vpc.lab9_vpc.id

  ingress {
    description = "HTTP from Internet"
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
    Name = "Lab9-ALB-SG"
  }
}

# Security Group for EC2 Instances (Allows HTTP only from ALB, SSH from anywhere for debug)
resource "aws_security_group" "lab9_ec2_sg" {
  name        = "lab9-ec2-sg-${random_id.suffix.hex}"
  description = "Allow HTTP from ALB, SSH from Internet"
  vpc_id      = aws_vpc.lab9_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lab9_alb_sg.id]
  }

  ingress {
    description = "SSH from Internet"
    from_port   = 22
    to_port     = 22
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
    Name = "Lab9-EC2-SG"
  }
}

# ============================================================
# KEY PAIR
# ============================================================

resource "tls_private_key" "lab9_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab9_keypair" {
  key_name   = "lab9-keypair-${random_id.suffix.hex}"
  public_key = tls_private_key.lab9_key.public_key_openssh

  tags = {
    Name = "Lab9-KeyPair"
  }
}

# ============================================================
# EC2 INSTANCES
# ============================================================

resource "aws_instance" "lab9_instance_1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.lab9_subnet_1.id
  vpc_security_group_ids = [aws_security_group.lab9_ec2_sg.id]
  key_name               = aws_key_pair.lab9_keypair.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Lab 9 - Instance A</h1><p>Served from Availability Zone: us-east-1a</p>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "Lab9-Instance-A"
  }
}

resource "aws_instance" "lab9_instance_2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.lab9_subnet_2.id
  vpc_security_group_ids = [aws_security_group.lab9_ec2_sg.id]
  key_name               = aws_key_pair.lab9_keypair.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Lab 9 - Instance B</h1><p>Served from Availability Zone: us-east-1b</p>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "Lab9-Instance-B"
  }
}

# ============================================================
# TARGET GROUP & LOAD BALANCER
# ============================================================

resource "aws_lb_target_group" "lab9_tg" {
  name     = "lab9-tg-${random_id.suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab9_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "lab9_tga_1" {
  target_group_arn = aws_lb_target_group.lab9_tg.arn
  target_id        = aws_instance.lab9_instance_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "lab9_tga_2" {
  target_group_arn = aws_lb_target_group.lab9_tg.arn
  target_id        = aws_instance.lab9_instance_2.id
  port             = 80
}

resource "aws_lb" "lab9_alb" {
  name               = "lab9-alb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lab9_alb_sg.id]
  subnets            = [aws_subnet.lab9_subnet_1.id, aws_subnet.lab9_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "Lab9-ALB"
  }
}

resource "aws_lb_listener" "lab9_alb_listener" {
  load_balancer_arn = aws_lb.lab9_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab9_tg.arn
  }
}
