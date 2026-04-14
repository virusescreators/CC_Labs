# Modules — Extended Notes

## Module Sources

Modules can come from different sources:

```hcl
# Local path
module "web" {
  source = "./modules/web-server"
}

# Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}

# GitHub
module "lambda" {
  source = "github.com/user/terraform-aws-lambda"
}

# S3 bucket
module "config" {
  source = "s3::https://s3-eu-west-1.amazonaws.com/bucket/module.zip"
}
```

## Module Best Practices

1. **Keep modules focused** — one module per logical component (VPC, compute, database)
2. **Always version** — pin module versions in production (`version = "5.0.0"`)
3. **Document inputs/outputs** — use `description` on all variables and outputs
4. **Don't hardcode** — pass everything through variables for maximum reusability
5. **Use `terraform-aws-modules`** — battle-tested community modules for AWS

## Module Outputs as Inputs

Chain modules together by using outputs from one as inputs to another:

```hcl
module "network" {
  source = "./modules/network"
  vpc_cidr = "10.0.0.0/16"
}

module "compute" {
  source    = "./modules/compute"
  subnet_id = module.network.public_subnet_id   # ← output from network module
}
```

## Nested Modules

Modules can call other modules:

```
root/
├── main.tf        # Calls "app" module
└── modules/
    └── app/
        ├── main.tf    # Calls "database" module
        └── modules/
            └── database/
                └── main.tf
```

---

> Back to: [README](README.md)
