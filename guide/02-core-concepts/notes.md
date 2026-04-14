# Core Concepts — Extended Notes

## Variable Types

Terraform supports several variable types:

```hcl
# String
variable "name" {
  type    = string
  default = "my-server"
}

# Number
variable "count" {
  type    = number
  default = 3
}

# Boolean
variable "enable_monitoring" {
  type    = bool
  default = true
}

# List
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# Map
variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Team        = "engineering"
  }
}
```

## Ways to Set Variable Values

Variables can be set in multiple ways (in order of precedence):

| Method | Priority | Example |
|--------|----------|---------|
| `-var` flag | Highest | `terraform apply -var="name=prod"` |
| `-var-file` flag | High | `terraform apply -var-file="prod.tfvars"` |
| `*.auto.tfvars` | Medium | Auto-loaded if file exists |
| `terraform.tfvars` | Medium | Auto-loaded if file exists |
| `TF_VAR_*` env vars | Low | `export TF_VAR_name=prod` |
| Variable defaults | Lowest | `default = "dev"` in variable block |

## Resource Dependencies

Terraform automatically infers dependencies between resources:

```hcl
# Terraform knows the subnet depends on the VPC
# It will create the VPC first, then the subnet
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id   # ← implicit dependency
  cidr_block = "10.0.1.0/24"
}
```

For explicit dependencies (when there's no direct reference):
```hcl
resource "aws_instance" "web" {
  # ...
  depends_on = [aws_s3_bucket.logs]  # ← explicit dependency
}
```

## Locals

**Locals** are computed values you can reference multiple times:

```hcl
locals {
  common_tags = {
    Project     = "CC-Labs"
    ManagedBy   = "terraform"
    Environment = var.environment
  }
}

resource "aws_instance" "web" {
  tags = local.common_tags
}
```

## Count and For Each

Create multiple resources from a single block:

```hcl
# Using count
resource "aws_instance" "server" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = { Name = "server-${count.index}" }
}

# Using for_each
resource "aws_s3_bucket" "buckets" {
  for_each = toset(["logs", "data", "backups"])
  bucket   = "my-${each.key}-bucket"
}
```

---

> Back to: [README](README.md)
