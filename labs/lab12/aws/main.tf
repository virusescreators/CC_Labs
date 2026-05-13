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
}

provider "aws" {
  region = "us-east-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

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

# ─── VPC & Networking ──────────────────────────────────────────────────────────

resource "aws_vpc" "lab12_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab12-VPC"
  }
}

resource "aws_internet_gateway" "lab12_igw" {
  vpc_id = aws_vpc.lab12_vpc.id

  tags = {
    Name = "Lab12-IGW"
  }
}

resource "aws_subnet" "lab12_subnet" {
  vpc_id                  = aws_vpc.lab12_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab12-Subnet"
  }
}

resource "aws_route_table" "lab12_public_rt" {
  vpc_id = aws_vpc.lab12_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab12_igw.id
  }

  tags = {
    Name = "Lab12-Public-RT"
  }
}

resource "aws_route_table_association" "lab12_rta" {
  subnet_id      = aws_subnet.lab12_subnet.id
  route_table_id = aws_route_table.lab12_public_rt.id
}

# ─── Security Groups ───────────────────────────────────────────────────────────

resource "aws_security_group" "lab12_sg" {
  name        = "lab12-sg-${random_id.suffix.hex}"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.lab12_vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name = "Lab12-SG"
  }
}

# ─── Key Pair ─────────────────────────────────────────────────────────────────

resource "tls_private_key" "lab12_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab12_keypair" {
  key_name   = "lab12-keypair-${random_id.suffix.hex}"
  public_key = tls_private_key.lab12_key.public_key_openssh

  tags = {
    Name = "Lab12-KeyPair"
  }
}

# ─── EC2 Instance ─────────────────────────────────────────────────────────────

resource "aws_instance" "lab12_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.lab12_subnet.id
  vpc_security_group_ids = [aws_security_group.lab12_sg.id]
  key_name               = aws_key_pair.lab12_keypair.key_name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update and install dependencies
    yum update -y
    curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs git nginx

    # Set up simple React application
    cd /home/ec2-user
    npx create-react-app@latest react-app
    cd react-app
    npm run build

    # Configure Nginx to serve the React app
    rm -rf /usr/share/nginx/html/*
    cp -r build/* /usr/share/nginx/html/

    # Start Nginx
    systemctl start nginx
    systemctl enable nginx
  EOF
  )

  tags = {
    Name = "Lab12-React-App-EC2"
  }
}
