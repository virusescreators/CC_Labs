terraform {
  backend "s3" {
    bucket         = "tfstate-haseen-22mdswe238"
    key            = "lab13/terraform.tfstate"
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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
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

resource "aws_vpc" "lab13_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "HaseenUllah-22MDSWE238-Lab13-VPC"
  }
}

resource "aws_internet_gateway" "lab13_igw" {
  vpc_id = aws_vpc.lab13_vpc.id

  tags = {
    Name = "Lab13-IGW"
  }
}

resource "aws_subnet" "lab13_subnet" {
  vpc_id                  = aws_vpc.lab13_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Lab13-Subnet"
  }
}

resource "aws_route_table" "lab13_public_rt" {
  vpc_id = aws_vpc.lab13_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab13_igw.id
  }

  tags = {
    Name = "Lab13-Public-RT"
  }
}

resource "aws_route_table_association" "lab13_rta" {
  subnet_id      = aws_subnet.lab13_subnet.id
  route_table_id = aws_route_table.lab13_public_rt.id
}

# ─── Security Groups ───────────────────────────────────────────────────────────

resource "aws_security_group" "lab13_sg" {
  name        = "lab13-sg-${random_id.suffix.hex}"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.lab13_vpc.id

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
    Name = "Lab13-SG"
  }
}

# ─── Key Pair ─────────────────────────────────────────────────────────────────

resource "tls_private_key" "lab13_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab13_keypair" {
  key_name   = "lab13-keypair-${random_id.suffix.hex}"
  public_key = tls_private_key.lab13_key.public_key_openssh

  tags = {
    Name = "Lab13-KeyPair"
  }
}

# ─── S3 Artifacts Bucket ──────────────────────────────────────────────────────

resource "aws_s3_bucket" "lab13_bucket" {
  bucket        = "lab13-pipeline-bucket-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "lab13_bucket_block" {
  bucket = aws_s3_bucket.lab13_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── IAM Service Roles ────────────────────────────────────────────────────────

# 1. EC2 Instance Role & Profile (CodeDeploy Access)
resource "aws_iam_role" "ec2_role" {
  name = "lab13-ec2-role-${random_id.suffix.hex}"

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

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ec2_s3_access" {
  name = "ec2-s3-access"
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.lab13_bucket.arn,
          "${aws_s3_bucket.lab13_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "lab13-ec2-profile-${random_id.suffix.hex}"
  role = aws_iam_role.ec2_role.name
}

# 2. CodeBuild Role
resource "aws_iam_role" "codebuild_role" {
  name = "lab13-codebuild-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-policy"
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.lab13_bucket.arn,
          "${aws_s3_bucket.lab13_bucket.arn}/*"
        ]
      }
    ]
  })
}

# 3. CodeDeploy Role
resource "aws_iam_role" "codedeploy_role" {
  name = "lab13-codedeploy-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attach" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# 4. CodePipeline Role
resource "aws_iam_role" "codepipeline_role" {
  name = "lab13-codepipeline-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline-policy"
  role = aws_iam_role.codepipeline_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketLocation",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.lab13_bucket.arn,
          "${aws_s3_bucket.lab13_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = [aws_codebuild_project.lab13_build.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetApplicationRevision",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = [
          aws_codedeploy_app.lab13_deploy.arn,
          aws_codedeploy_deployment_group.lab13_dg.arn,
          "arn:aws:codedeploy:us-east-1:*:deploymentconfig:*"
        ]
      }
    ]
  })
}

# ─── EC2 Instance ─────────────────────────────────────────────────────────────

resource "aws_instance" "lab13_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.lab13_subnet.id
  vpc_security_group_ids = [aws_security_group.lab13_sg.id]
  key_name               = aws_key_pair.lab13_keypair.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update and install dependencies
    yum update -y
    yum install -y ruby wget nginx

    # Configure Nginx for single page serving
    cat > /etc/nginx/nginx.conf << 'CONF'
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log notice;
    pid /run/nginx.pid;

    events {
        worker_connections 1024;
    }

    http {
        include             /etc/nginx/mime.types;
        default_type        application/octet-stream;
        sendfile            on;
        keepalive_timeout   65;

        server {
            listen       80;
            server_name  _;
            root         /home/ec2-user;
            index        index.html;

            location / {
                try_files $uri /index.html;
            }
        }
    }
    CONF

    # Setup permissions for nginx accessing ec2-user directory
    chmod o+x /home/ec2-user

    # Start and enable Nginx
    systemctl start nginx
    systemctl enable nginx

    # Install CodeDeploy agent (Region is us-east-1)
    cd /home/ec2-user
    wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto

    # Start CodeDeploy agent
    systemctl start codedeploy-agent
    systemctl enable codedeploy-agent
  EOF
  )

  tags = {
    Name = "Lab13-React-App-EC2"
  }
}

# ─── CodeDeploy Configurations ───────────────────────────────────────────────

resource "aws_codedeploy_app" "lab13_deploy" {
  compute_platform = "Server"
  name             = "lab13-codedeploy-app"
}

resource "aws_codedeploy_deployment_group" "lab13_dg" {
  app_name              = aws_codedeploy_app.lab13_deploy.name
  deployment_group_name = "lab13-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "Lab13-React-App-EC2"
    }
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
}

# ─── CodeBuild Project ────────────────────────────────────────────────────────

resource "aws_codebuild_project" "lab13_build" {
  name          = "lab13-codebuild-project"
  description   = "Builds the Lab 13 application for deployment"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
  }
}

# ─── Pipeline Trigger & S3 Source Package ────────────────────────────────────

# Zip the sample application files
data "archive_file" "sample_app_zip" {
  type        = "zip"
  source_dir  = "${path.module}/sample-app"
  output_path = "${path.module}/sample-app.zip"
}

# Upload the ZIP archive to S3. This automatically triggers CodePipeline!
resource "aws_s3_object" "source_archive" {
  bucket = aws_s3_bucket.lab13_bucket.id
  key    = "source/sample-app.zip"
  source = data.archive_file.sample_app_zip.output_path
  etag   = data.archive_file.sample_app_zip.output_md5
}

# ─── CodePipeline Configuration ───────────────────────────────────────────────

resource "aws_codepipeline" "lab13_pipeline" {
  name     = "lab13-continuous-deployment-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.lab13_bucket.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "S3_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket             = aws_s3_bucket.lab13_bucket.id
        S3ObjectKey          = aws_s3_object.source_archive.key
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.lab13_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "CodeDeploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.lab13_deploy.name
        DeploymentGroupName = aws_codedeploy_deployment_group.lab13_dg.deployment_group_name
      }
    }
  }
}
