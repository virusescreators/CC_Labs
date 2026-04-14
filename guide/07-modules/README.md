# 07 — Terraform Modules

## What is a Module?

A **module** is a reusable package of Terraform code. Instead of repeating the same resource blocks across multiple projects, you create a module once and call it wherever needed.

Think of modules like functions in programming — write once, use many times.

## Module Structure

```
sample-module/
├── main.tf       # Resources the module creates
├── variables.tf  # Inputs the module accepts
└── outputs.tf    # Values the module returns
```

## How to Call a Module

```hcl
module "web_server" {
  source        = "./sample-module"    # Local module
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

## Terraform Registry

The Terraform Registry ([registry.terraform.io](https://registry.terraform.io)) has thousands of pre-built modules for common use cases:

- `terraform-aws-modules/vpc/aws` — VPC setup
- `terraform-aws-modules/eks/aws` — Kubernetes (EKS)
- `terraform-aws-modules/rds/aws` — Relational databases

## Sample Module

See [`sample-module/`](sample-module/) for a working example.

---

> See [`notes.md`](notes.md) for extended notes.  
> Next: [`08-lab-exercises/`](../08-lab-exercises/)
