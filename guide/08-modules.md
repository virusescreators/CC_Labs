# 08 — Terraform Modules

## What is a Module?

A **module** is a reusable package of Terraform code. Instead of repeating the same resource blocks across multiple projects, you create a module once and call it wherever needed.

Think of modules like functions in programming — write once, use many times.

---

## Module Structure

```
sample-module/
├── main.tf       # Resources the module creates
├── variables.tf  # Inputs the module accepts
└── outputs.tf    # Values the module returns
```

---

## How to Call a Module

```hcl
# Using a local module
module "web_server" {
  source        = "./sample-module"
  instance_type = "t2.micro"
  server_name   = "my-web-server"
}

# Using a module from Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

---

## Sample Module

### main.tf

```hcl
resource "aws_instance" "this" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name      = var.server_name
    ManagedBy = "terraform-module"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

### variables.tf

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "server_name" {
  description = "Name tag for the server"
  type        = string
}
```

### outputs.tf

```hcl
output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}
```

---

## Terraform Registry

The Terraform Registry ([registry.terraform.io](https://registry.terraform.io)) has thousands of pre-built modules for common use cases:

| Module | Purpose |
|---|---|
| `terraform-aws-modules/vpc/aws` | VPC setup |
| `terraform-aws-modules/eks/aws` | Kubernetes (EKS) |
| `terraform-aws-modules/rds/aws` | Relational databases |

---

> Next: [Lab Exercises →](09-lab-exercises.md)
