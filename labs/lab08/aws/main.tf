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
# TASK 1: Create VPC with Public & Private Subnets
# ============================================================

resource "aws_vpc" "lab8_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab8-VPC"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "lab8_igw" {
  vpc_id = aws_vpc.lab8_vpc.id

  tags = {
    Name = "Lab8-IGW"
  }
}

# --- Public Subnet ---
resource "aws_subnet" "lab8_public_subnet" {
  vpc_id                  = aws_vpc.lab8_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab8-Public-Subnet"
  }
}

# --- Private Subnet ---
resource "aws_subnet" "lab8_private_subnet" {
  vpc_id            = aws_vpc.lab8_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Lab8-Private-Subnet"
  }
}

# ============================================================
# TASK 1 (cont.): Route Tables for Internet Gateway
# ============================================================

# --- Public Route Table ---
# Routes internet-bound traffic (0.0.0.0/0) through the Internet Gateway
resource "aws_route_table" "lab8_public_rt" {
  vpc_id = aws_vpc.lab8_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab8_igw.id
  }

  tags = {
    Name = "Lab8-Public-RT"
  }
}

resource "aws_route_table_association" "lab8_public_rta" {
  subnet_id      = aws_subnet.lab8_public_subnet.id
  route_table_id = aws_route_table.lab8_public_rt.id
}

# --- Private Route Table ---
# No internet route — instances in this subnet are isolated
resource "aws_route_table" "lab8_private_rt" {
  vpc_id = aws_vpc.lab8_vpc.id

  tags = {
    Name = "Lab8-Private-RT"
  }
}

resource "aws_route_table_association" "lab8_private_rta" {
  subnet_id      = aws_subnet.lab8_private_subnet.id
  route_table_id = aws_route_table.lab8_private_rt.id
}

# ============================================================
# SECURITY GROUPS
# ============================================================

# --- Public EC2 Security Group ---
# Allows SSH (22) and HTTP (80) from the internet, plus ICMP for ping
resource "aws_security_group" "lab8_public_sg" {
  name        = "lab8-public-sg-${random_id.suffix.hex}"
  description = "Allow SSH, HTTP, and ICMP from the internet (public subnet)"
  vpc_id      = aws_vpc.lab8_vpc.id

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

  ingress {
    description = "ICMP (Ping)"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab8-Public-SG"
  }
}

# --- Private EC2 Security Group ---
# ONLY allows SSH and ICMP from the public subnet CIDR (10.0.1.0/24)
# This ensures the private instance is reachable ONLY through the public EC2
resource "aws_security_group" "lab8_private_sg" {
  name        = "lab8-private-sg-${random_id.suffix.hex}"
  description = "Allow SSH and ICMP only from public subnet (private subnet)"
  vpc_id      = aws_vpc.lab8_vpc.id

  ingress {
    description = "SSH from Public Subnet only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"] # Public subnet CIDR
  }

  ingress {
    description = "ICMP (Ping) from Public Subnet only"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.1.0/24"] # Public subnet CIDR
  }

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
    Name = "Lab8-Private-SG"
  }
}

# ============================================================
# KEY PAIR: Auto-generated TLS key for SSH access
# ============================================================

resource "tls_private_key" "lab8_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab8_keypair" {
  key_name   = "lab8-keypair-${random_id.suffix.hex}"
  public_key = tls_private_key.lab8_key.public_key_openssh

  tags = {
    Name = "Lab8-KeyPair"
  }
}

# ============================================================
# TASK 2: Launch Public EC2 Instance
# ============================================================
# Launched in the public subnet with a public IP.
# Acts as a bastion / jump host to reach the private instance.

resource "aws_instance" "lab8_public_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro" # Free Tier eligible
  subnet_id              = aws_subnet.lab8_public_subnet.id
  vpc_security_group_ids = [aws_security_group.lab8_public_sg.id]
  key_name               = aws_key_pair.lab8_keypair.key_name

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Lab 8 - Public EC2</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
                background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
                color: #fff;
            }
            .card {
                background: rgba(255, 255, 255, 0.08);
                backdrop-filter: blur(12px);
                border: 1px solid rgba(255, 255, 255, 0.15);
                border-radius: 20px;
                padding: 3rem 4rem;
                text-align: center;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
            }
            h1 { font-size: 2.2rem; margin-bottom: 0.5rem; }
            .reg { font-size: 1.1rem; color: #a78bfa; margin-bottom: 1.5rem; }
            .info { font-size: 0.95rem; color: #cbd5e1; line-height: 1.8; }
            .badge {
                display: inline-block;
                margin-top: 1.5rem;
                padding: 0.4rem 1.2rem;
                background: linear-gradient(90deg, #22c55e, #16a34a);
                border-radius: 999px;
                font-size: 0.85rem;
                font-weight: 600;
            }
        </style>
    </head>
    <body>
        <div class="card">
            <h1>Haseen Ullah</h1>
            <p class="reg">Registration # 22MDSWE238</p>
            <div class="info">
                <p>Cloud Computing — Lab 8</p>
                <p>Public EC2 Instance (Bastion Host)</p>
                <p>Subnet: Public (10.0.1.0/24) &bull; Instance Type: t2.micro</p>
            </div>
            <span class="badge">Public Subnet &#x1F310;</span>
        </div>
    </body>
    </html>
    HTML
  EOF

  tags = {
    Name = "Lab8-Public-EC2"
  }
}

# ============================================================
# TASK 3: Launch Private EC2 Instance
# ============================================================
# Launched in the private subnet WITHOUT a public IP.
# Accessible ONLY from the public EC2 instance via SSH / ping.

resource "aws_instance" "lab8_private_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro" # Free Tier eligible
  subnet_id              = aws_subnet.lab8_private_subnet.id
  vpc_security_group_ids = [aws_security_group.lab8_private_sg.id]
  key_name               = aws_key_pair.lab8_keypair.key_name

  associate_public_ip_address = false # No public IP for private instance

  tags = {
    Name = "Lab8-Private-EC2"
  }
}

# ============================================================
# TASK 4 & 5: Access Verification
# ============================================================
# Steps to verify:
#
# 1. Save the private key:
#      terraform output -raw private_key > lab8-key.pem
#      chmod 400 lab8-key.pem   (Linux/Mac)
#
# 2. SSH into the PUBLIC EC2 instance:
#      ssh -i lab8-key.pem ec2-user@<public_ec2_public_ip>
#
# 3. From the PUBLIC instance, copy the key and SSH into PRIVATE:
#      # On your local machine, copy key to public instance:
#      scp -i lab8-key.pem lab8-key.pem ec2-user@<public_ip>:~/
#
#      # On the public instance:
#      chmod 400 lab8-key.pem
#      ssh -i lab8-key.pem ec2-user@<private_ec2_private_ip>
#
# 4. Ping the private instance from the public instance:
#      ping <private_ec2_private_ip>
#      (Should SUCCEED — allowed by security group)
#
# 5. Try pinging the private instance from outside the VPC:
#      (Should FAIL — no public IP, no internet route)
#
# For Windows (PuTTY):
#   1. Convert the PEM to PPK using PuTTYgen
#   2. Open PuTTY → enter the public IP
#   3. Connection → SSH → Auth → Browse for the PPK file
#   4. Click Open → login as: ec2-user
#   5. From public EC2, ping the private IP
#
# ============================================================
# IMPORTANT: Destroy resources after lab to avoid billing
# ============================================================
# Run: Actions → Deploy Labs → Lab 8 → aws → destroy
