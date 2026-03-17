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
# NETWORKING: VPC, Subnet, Internet Gateway, Route Table
# ============================================================

resource "aws_vpc" "lab6_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Lab6-EC2-VPC"
  }
}

resource "aws_internet_gateway" "lab6_igw" {
  vpc_id = aws_vpc.lab6_vpc.id

  tags = {
    Name = "Lab6-IGW"
  }
}

resource "aws_route_table" "lab6_public_rt" {
  vpc_id = aws_vpc.lab6_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab6_igw.id
  }

  tags = {
    Name = "Lab6-Public-RT"
  }
}

resource "aws_subnet" "lab6_public_subnet" {
  vpc_id                  = aws_vpc.lab6_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab6-Public-Subnet"
  }
}

resource "aws_route_table_association" "lab6_rta" {
  subnet_id      = aws_subnet.lab6_public_subnet.id
  route_table_id = aws_route_table.lab6_public_rt.id
}

# ============================================================
# SECURITY GROUP: Allow SSH (22) + HTTP (80)
# ============================================================

resource "aws_security_group" "lab6_ec2_sg" {
  name        = "lab6-ec2-sg"
  description = "Allow SSH and HTTP traffic for EC2"
  vpc_id      = aws_vpc.lab6_vpc.id

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
    Name = "Lab6-EC2-SG"
  }
}

# ============================================================
# KEY PAIR: Auto-generated TLS key for SSH access
# ============================================================

resource "tls_private_key" "lab6_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab6_keypair" {
  key_name   = "lab6-keypair-${random_id.suffix.hex}"
  public_key = tls_private_key.lab6_key.public_key_openssh

  tags = {
    Name = "Lab6-KeyPair"
  }
}

# ============================================================
# TASK 1: Launch an EC2 Instance
# ============================================================
# Free-tier eligible: t2.micro, Amazon Linux 2023
# user_data installs httpd and serves a student info HTML page

resource "aws_instance" "lab6_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro" # Free Tier eligible
  subnet_id              = aws_subnet.lab6_public_subnet.id
  vpc_security_group_ids = [aws_security_group.lab6_ec2_sg.id]
  key_name               = aws_key_pair.lab6_keypair.key_name

  associate_public_ip_address = true

  # ============================================================
  # TASK 2 & 3: Install httpd and serve student HTML page
  # ============================================================
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
        <title>Lab 6 - EC2 Web Server</title>
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
                background: linear-gradient(90deg, #6366f1, #8b5cf6);
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
                <p>Cloud Computing — Lab 6</p>
                <p>Amazon EC2 Web Server</p>
                <p>Instance Type: t2.micro &bull; AMI: Amazon Linux 2023</p>
            </div>
            <span class="badge">Served from EC2 &#x1F680;</span>
        </div>
    </body>
    </html>
    HTML
  EOF

  tags = {
    Name = "Lab6-EC2-Instance"
  }
}

# ============================================================
# TASK 4: Connect via SSH
# ============================================================
# After deploying, connect using:
#
#   Save the private key:
#     terraform output -raw private_key > lab6-key.pem
#     chmod 400 lab6-key.pem   (Linux/Mac)
#
#   SSH into the instance:
#     ssh -i lab6-key.pem ec2-user@<public_ip>
#
#   For Windows (PuTTY):
#     1. Convert the PEM to PPK using PuTTYgen
#     2. Open PuTTY → enter the public IP
#     3. Go to Connection → SSH → Auth → Browse for the PPK file
#     4. Click Open → login as: ec2-user
#
# ============================================================
# TASK 5: Verify Web Server
# ============================================================
# Open the public IP in your browser:
#   http://<public_ip>
#
# You should see the student info HTML page.
#
# ============================================================
# IMPORTANT: Terminate after lab to avoid billing
# ============================================================
# Run: Actions → Deploy Labs → Lab 6 → aws → destroy
