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

# ─── VPC & Networking ──────────────────────────────────────────────────────────

resource "aws_vpc" "lab11_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab11-VPC"
  }
}

resource "aws_internet_gateway" "lab11_igw" {
  vpc_id = aws_vpc.lab11_vpc.id

  tags = {
    Name = "Lab11-IGW"
  }
}

resource "aws_subnet" "lab11_subnet_1" {
  vpc_id                  = aws_vpc.lab11_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab11-Subnet-1"
  }
}

resource "aws_subnet" "lab11_subnet_2" {
  vpc_id                  = aws_vpc.lab11_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab11-Subnet-2"
  }
}

resource "aws_route_table" "lab11_public_rt" {
  vpc_id = aws_vpc.lab11_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab11_igw.id
  }

  tags = {
    Name = "Lab11-Public-RT"
  }
}

resource "aws_route_table_association" "lab11_rta_1" {
  subnet_id      = aws_subnet.lab11_subnet_1.id
  route_table_id = aws_route_table.lab11_public_rt.id
}

resource "aws_route_table_association" "lab11_rta_2" {
  subnet_id      = aws_subnet.lab11_subnet_2.id
  route_table_id = aws_route_table.lab11_public_rt.id
}

# ─── Security Groups ───────────────────────────────────────────────────────────

resource "aws_security_group" "lab11_alb_sg" {
  name        = "lab11-alb-sg-${random_id.suffix.hex}"
  description = "Allow HTTP inbound traffic for ALB"
  vpc_id      = aws_vpc.lab11_vpc.id

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
    Name = "Lab11-ALB-SG"
  }
}

resource "aws_security_group" "lab11_asg_sg" {
  name        = "lab11-asg-sg-${random_id.suffix.hex}"
  description = "Allow HTTP from ALB only"
  vpc_id      = aws_vpc.lab11_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lab11_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab11-ASG-SG"
  }
}

# ─── Key Pair ─────────────────────────────────────────────────────────────────

resource "tls_private_key" "lab11_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab11_keypair" {
  key_name   = "lab11-keypair-${random_id.suffix.hex}"
  public_key = tls_private_key.lab11_key.public_key_openssh

  tags = {
    Name = "Lab11-KeyPair"
  }
}

# ─── Application Load Balancer ────────────────────────────────────────────────

resource "aws_lb" "lab11_alb" {
  name               = "lab11-alb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lab11_alb_sg.id]
  subnets            = [aws_subnet.lab11_subnet_1.id, aws_subnet.lab11_subnet_2.id]

  tags = {
    Name = "Lab11-ALB"
  }
}

# ─── Target Groups ─────────────────────────────────────────────────────────────

# Target Group A: /app/* → Frontend ASG
resource "aws_lb_target_group" "lab11_tg_app" {
  name     = "lab11-tg-app-${random_id.suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab11_vpc.id

  health_check {
    path                = "/app/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "Lab11-TG-App"
  }
}

# Target Group B: /api/* → Backend ASG
resource "aws_lb_target_group" "lab11_tg_api" {
  name     = "lab11-tg-api-${random_id.suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab11_vpc.id

  health_check {
    path                = "/api/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "Lab11-TG-Api"
  }
}

# ─── ALB Listener & Path-Based Routing Rules ──────────────────────────────────

resource "aws_lb_listener" "lab11_alb_listener" {
  load_balancer_arn = aws_lb.lab11_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action: returns 404 for unmatched paths
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Path not found. Use /app/ or /api/"
      status_code  = "404"
    }
  }
}

# Rule 1: Route /app/* to the App Target Group (frontend)
resource "aws_lb_listener_rule" "lab11_rule_app" {
  listener_arn = aws_lb_listener.lab11_alb_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab11_tg_app.arn
  }

  condition {
    path_pattern {
      values = ["/app/*"]
    }
  }
}

# Rule 2: Route /api/* to the API Target Group (backend)
resource "aws_lb_listener_rule" "lab11_rule_api" {
  listener_arn = aws_lb_listener.lab11_alb_listener.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab11_tg_api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# ─── Launch Templates ─────────────────────────────────────────────────────────

# Launch Template for Frontend App ASG (serves /app/ path)
resource "aws_launch_template" "lab11_lt_app" {
  name_prefix   = "lab11-lt-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.lab11_keypair.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.lab11_asg_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
    AZ=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
    mkdir -p /var/www/html/app
    cat > /var/www/html/app/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head><title>Lab 11 - Frontend App</title></head>
    <body style="font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;text-align:center;padding:50px;">
      <h1 style="color:#0f3460;">&#128196; Frontend App</h1>
      <p>Path: <strong>/app/</strong></p>
      <p>Auto Scaling Group: <strong>App ASG</strong></p>
      <p>Availability Zone: <strong>$AZ</strong></p>
    </body>
    </html>
    HTML
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Lab11-App-ASG-Instance"
    }
  }
}

# Launch Template for Backend API ASG (serves /api/ path)
resource "aws_launch_template" "lab11_lt_api" {
  name_prefix   = "lab11-lt-api-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.lab11_keypair.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.lab11_asg_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
    AZ=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
    mkdir -p /var/www/html/api
    cat > /var/www/html/api/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head><title>Lab 11 - Backend API</title></head>
    <body style="font-family:sans-serif;background:#0a0a0a;color:#e0e0e0;text-align:center;padding:50px;">
      <h1 style="color:#e94560;">&#128196; Backend API</h1>
      <p>Path: <strong>/api/</strong></p>
      <p>Auto Scaling Group: <strong>API ASG</strong></p>
      <p>Availability Zone: <strong>$AZ</strong></p>
    </body>
    </html>
    HTML
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Lab11-Api-ASG-Instance"
    }
  }
}

# ─── Auto Scaling Groups ──────────────────────────────────────────────────────

# ASG A: Frontend App
resource "aws_autoscaling_group" "lab11_asg_app" {
  name                = "lab11-asg-app-${random_id.suffix.hex}"
  vpc_zone_identifier = [aws_subnet.lab11_subnet_1.id, aws_subnet.lab11_subnet_2.id]
  target_group_arns   = [aws_lb_target_group.lab11_tg_app.arn]

  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.lab11_lt_app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Lab11-App-ASG-Instance"
    propagate_at_launch = true
  }
}

# ASG B: Backend API
resource "aws_autoscaling_group" "lab11_asg_api" {
  name                = "lab11-asg-api-${random_id.suffix.hex}"
  vpc_zone_identifier = [aws_subnet.lab11_subnet_1.id, aws_subnet.lab11_subnet_2.id]
  target_group_arns   = [aws_lb_target_group.lab11_tg_api.arn]

  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.lab11_lt_api.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Lab11-Api-ASG-Instance"
    propagate_at_launch = true
  }
}
