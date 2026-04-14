# 02 — Core Concepts of Terraform

## 1. Providers

A **provider** is a plugin that lets Terraform talk to a specific platform or service. Each provider exposes resources you can manage.

```hcl
# Telling Terraform to use the AWS provider
provider "aws" {
  region = "us-east-1"
}
```

Common providers:
- `hashicorp/aws` — Amazon Web Services
- `hashicorp/azurerm` — Microsoft Azure
- `hashicorp/google` — Google Cloud Platform
- `hashicorp/kubernetes` — Kubernetes clusters

---

## 2. Resources

A **resource** is the most important element in Terraform. It defines a single piece of infrastructure (a server, a database, a network, etc.).

```hcl
resource "aws_instance" "my_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

Structure:
```
resource "<PROVIDER_RESOURCE_TYPE>" "<LOCAL_NAME>" {
  argument = value
}
```

---

## 3. Variables

**Variables** make your code reusable and flexible.

```hcl
# Declaration in variables.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# Usage in main.tf
resource "aws_instance" "server" {
  instance_type = var.instance_type
}
```

---

## 4. Outputs

**Outputs** display useful values after Terraform runs (like an IP address or URL).

```hcl
output "server_ip" {
  value       = aws_instance.server.public_ip
  description = "The public IP of the server"
}
```

---

## 5. State

Terraform keeps a **state file** (`terraform.tfstate`) to track what it has created. This is how Terraform knows what exists and what needs to change.

> ⚠️ Never edit the state file manually. Use Terraform commands.

---

## 6. Data Sources

**Data sources** let you read information from existing infrastructure (not created by you).

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}
```

---

> Next: [Terraform Operations →](03-terraform-operations.md)
