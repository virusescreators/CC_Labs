terraform {
  backend "s3" {
    bucket         = "tfstate-haseen-22mdswe238"
    key            = "lab14/terraform.tfstate"
    region         = "us-east-1"
  }

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

resource "aws_vpc" "lab14_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab14-VPC"
  }
}

resource "aws_internet_gateway" "lab14_igw" {
  vpc_id = aws_vpc.lab14_vpc.id

  tags = {
    Name = "Lab14-IGW"
  }
}

resource "aws_subnet" "lab14_subnet" {
  vpc_id                  = aws_vpc.lab14_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab14-Subnet"
  }
}

resource "aws_route_table" "lab14_public_rt" {
  vpc_id = aws_vpc.lab14_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab14_igw.id
  }

  tags = {
    Name = "Lab14-Public-RT"
  }
}

resource "aws_route_table_association" "lab14_rta" {
  subnet_id      = aws_subnet.lab14_subnet.id
  route_table_id = aws_route_table.lab14_public_rt.id
}

# ─── Security Groups ───────────────────────────────────────────────────────────

resource "aws_security_group" "lab14_sg" {
  name        = "lab14-sg-${random_id.suffix.hex}"
  description = "Allow SSH inbound traffic and all outbound traffic for CloudWatch Agent"
  vpc_id      = aws_vpc.lab14_vpc.id

  ingress {
    description = "SSH from Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab14-SG"
  }
}

# ─── Key Pair ─────────────────────────────────────────────────────────────────

resource "tls_private_key" "lab14_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab14_keypair" {
  key_name   = "lab14-keypair-${random_id.suffix.hex}"
  public_key = tls_private_key.lab14_key.public_key_openssh

  tags = {
    Name = "Lab14-KeyPair"
  }
}

# ─── IAM Service Roles for CloudWatch Agent ───────────────────────────────────

resource "aws_iam_role" "ec2_role" {
  name = "lab14-ec2-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attachment of AWS-managed policy for CloudWatch Server Agent
resource "aws_iam_role_policy_attachment" "ec2_cw_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attachment of AWS-managed policy for Systems Manager (SSM) access
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "lab14-ec2-profile-${random_id.suffix.hex}"
  role = aws_iam_role.ec2_role.name
}

# ─── EC2 Instance ─────────────────────────────────────────────────────────────

resource "aws_instance" "lab14_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.lab14_subnet.id
  vpc_security_group_ids = [aws_security_group.lab14_sg.id]
  key_name               = aws_key_pair.lab14_keypair.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update packages
    dnf update -y

    # Install the CloudWatch Agent
    dnf install amazon-cloudwatch-agent -y

    # Create directory for the custom application logs
    mkdir -p /var/log/custom-app
    touch /var/log/custom-app/app.log
    chmod 666 /var/log/custom-app/app.log

    # Create a background loop script that generates custom logs with system stats
    cat << 'OUTER_EOF' > /usr/local/bin/log-generator.sh
    #!/bin/bash
    while true; do
      CPU_LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | sed 's/^[ \t]*//')
      MEM_FREE=$(free -m | awk '/Mem:/ { print $4 }')
      echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Lab14-App-Monitor: Periodic log heartbeat. CPU Load Avg: $CPU_LOAD | Free Memory: $MEM_FREE MB" >> /var/log/custom-app/app.log
      sleep 10
    done
    OUTER_EOF

    chmod +x /usr/local/bin/log-generator.sh
    # Start the log generator as a background daemon
    nohup /usr/local/bin/log-generator.sh > /dev/null 2>&1 &

    # Generate the CloudWatch Agent config JSON file
    cat << 'OUTER_EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
      "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
      },
      "metrics": {
        "append_dimensions": {
          "InstanceId": "$${aws:InstanceId}",
          "InstanceType": "$${aws:InstanceType}"
        },
        "metrics_collected": {
          "cpu": {
            "measurement": [
              "usage_active",
              "usage_user",
              "usage_system",
              "usage_idle"
            ],
            "metrics_collection_interval": 60,
            "totalcpu": true
          },
          "mem": {
            "measurement": [
              "mem_active",
              "mem_available",
              "mem_used",
              "mem_used_percent"
            ],
            "metrics_collection_interval": 60
          },
          "disk": {
            "measurement": [
              "used_percent",
              "free"
            ],
            "metrics_collection_interval": 60,
            "resources": [
              "/"
            ]
          }
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/custom-app/app.log",
                "log_group_name": "lab14-ec2-custom-logs",
                "log_stream_name": "custom-app-stream",
                "retention_in_days": 3
              }
            ]
          }
        }
      }
    }
    OUTER_EOF

    # Start the CloudWatch agent using the configuration file
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
  EOF
  )

  tags = {
    Name = "Lab14-CloudWatch-Agent-EC2"
  }
}
