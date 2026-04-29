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

resource "aws_vpc" "lab10_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab10-VPC"
  }
}

resource "aws_internet_gateway" "lab10_igw" {
  vpc_id = aws_vpc.lab10_vpc.id

  tags = {
    Name = "Lab10-IGW"
  }
}

resource "aws_subnet" "lab10_subnet_1" {
  vpc_id                  = aws_vpc.lab10_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab10-Subnet-1"
  }
}

resource "aws_subnet" "lab10_subnet_2" {
  vpc_id                  = aws_vpc.lab10_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab10-Subnet-2"
  }
}

resource "aws_route_table" "lab10_public_rt" {
  vpc_id = aws_vpc.lab10_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab10_igw.id
  }

  tags = {
    Name = "Lab10-Public-RT"
  }
}

resource "aws_route_table_association" "lab10_rta_1" {
  subnet_id      = aws_subnet.lab10_subnet_1.id
  route_table_id = aws_route_table.lab10_public_rt.id
}

resource "aws_route_table_association" "lab10_rta_2" {
  subnet_id      = aws_subnet.lab10_subnet_2.id
  route_table_id = aws_route_table.lab10_public_rt.id
}

resource "aws_security_group" "lab10_alb_sg" {
  name        = "lab10-alb-sg-${random_id.suffix.hex}"
  description = "Allow HTTP inbound traffic for ALB"
  vpc_id      = aws_vpc.lab10_vpc.id

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
    Name = "Lab10-ALB-SG"
  }
}

resource "aws_security_group" "lab10_asg_sg" {
  name        = "lab10-asg-sg-${random_id.suffix.hex}"
  description = "Allow HTTP from ALB, SSH from Internet"
  vpc_id      = aws_vpc.lab10_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lab10_alb_sg.id]
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
    Name = "Lab10-ASG-SG"
  }
}

resource "tls_private_key" "lab10_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab10_keypair" {
  key_name   = "lab10-keypair-${random_id.suffix.hex}"
  public_key = tls_private_key.lab10_key.public_key_openssh

  tags = {
    Name = "Lab10-KeyPair"
  }
}

resource "aws_launch_template" "lab10_lt" {
  name_prefix   = "lab10-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.lab10_keypair.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.lab10_asg_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
    AZ=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
    echo "<h1>Lab 10 - Auto Scaling Group Instance</h1><p>Served from AZ: $AZ</p>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Lab10-ASG-Instance"
    }
  }
}

resource "aws_lb_target_group" "lab10_tg" {
  name     = "lab10-tg-${random_id.suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab10_vpc.id

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

resource "aws_lb" "lab10_alb" {
  name               = "lab10-alb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lab10_alb_sg.id]
  subnets            = [aws_subnet.lab10_subnet_1.id, aws_subnet.lab10_subnet_2.id]

  tags = {
    Name = "Lab10-ALB"
  }
}

resource "aws_lb_listener" "lab10_alb_listener" {
  load_balancer_arn = aws_lb.lab10_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab10_tg.arn
  }
}

resource "aws_autoscaling_group" "lab10_asg" {
  name                = "lab10-asg-${random_id.suffix.hex}"
  vpc_zone_identifier = [aws_subnet.lab10_subnet_1.id, aws_subnet.lab10_subnet_2.id]
  target_group_arns   = [aws_lb_target_group.lab10_tg.arn]

  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.lab10_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Lab10-ASG-Instance"
    propagate_at_launch = true
  }
}
