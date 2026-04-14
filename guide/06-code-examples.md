# 06 — Code Examples

Hands-on Terraform examples progressing from simple to complex.

---

## Example 1 — Launching an EC2 Instance

**Goal**: Create a single EC2 (virtual machine) instance on AWS.

**What this creates**:
- 1 EC2 instance (t2.micro — free tier eligible)

### main.tf

```hcl
# Fetch the latest Ubuntu 22.04 AMI automatically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create the EC2 instance
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name        = var.instance_name
    Environment = "learning"
    ManagedBy   = "terraform"
  }
}
```

### variables.tf

```hcl
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "terraform-demo-server"
}
```

### outputs.tf

```hcl
output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "public_ip" {
  description = "The public IP address of the instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_state" {
  description = "The current state of the instance"
  value       = aws_instance.web_server.instance_state
}
```

### How to run

```bash
terraform init
terraform plan
terraform apply

# Expected output:
# instance_id = "i-0abc1234..."
# public_ip   = "3.91.xx.xx"

terraform destroy   # IMPORTANT — avoid charges!
```

---

## Example 2 — Creating an S3 Bucket

**Goal**: Create an S3 storage bucket with versioning enabled.

**What this creates**:
- 1 S3 bucket with a unique name
- Versioning enabled on the bucket

### main.tf

```hcl
resource "aws_s3_bucket" "demo_bucket" {
  bucket = var.bucket_name

  tags = {
    Name      = var.bucket_name
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.demo_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

### variables.tf

```hcl
variable "region" {
  default = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket"
  type        = string
  default     = "terraform-demo-bucket-12345"  # Change this to something unique!
}
```

### outputs.tf

```hcl
output "bucket_name" {
  value = aws_s3_bucket.demo_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.demo_bucket.arn
}

output "bucket_domain" {
  value = aws_s3_bucket.demo_bucket.bucket_domain_name
}
```

---

## Example 3 — Creating a VPC Network

**Goal**: Set up a Virtual Private Cloud (VPC) with a public subnet.

**What this creates**:
- 1 VPC with a custom CIDR block
- 1 Public Subnet inside the VPC
- 1 Internet Gateway (for internet access)
- 1 Route Table with a route to the internet

### main.tf

```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "terraform-demo-vpc"
    ManagedBy = "terraform"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-igw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "terraform-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

### variables.tf

```hcl
variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}
```

### outputs.tf

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}
```

---

## Example 4 — Multi-Resource Deployment (EC2 + Security Group + VPC)

**Goal**: Deploy a full stack — VPC, subnet, security group, and an EC2 instance — together in one configuration.

**What this creates**:
- 1 VPC
- 1 Public subnet
- 1 Internet Gateway + Route Table
- 1 Security Group (allows SSH on port 22 and HTTP on port 80)
- 1 EC2 instance inside the VPC

### main.tf

```hcl
# --- Networking ---

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "demo-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
  tags = { Name = "demo-public-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "demo-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group ---

resource "aws_security_group" "web_sg" {
  name        = "demo-web-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  tags = { Name = "demo-web-sg" }
}

# --- EC2 Instance ---

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = {
    Name      = "demo-web-server"
    ManagedBy = "terraform"
  }
}
```

### variables.tf

```hcl
variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}
```

### outputs.tf

```hcl
output "web_server_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Visit http://<this-ip> to see nginx running"
}

output "vpc_id" {
  value = aws_vpc.main.id
}
```

### How to run

```bash
terraform init
terraform plan
terraform apply

# Open http://<web_server_public_ip> in your browser
# You should see the nginx welcome page

terraform destroy   # IMPORTANT — avoid charges!
```

---

> Next: [State Management →](07-state-management.md)
