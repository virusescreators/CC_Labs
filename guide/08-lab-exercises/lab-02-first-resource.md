# Lab 02 — Create Your First Terraform Resource

## Objective

Use Terraform to create an S3 bucket on AWS.

---

## Steps

1. Create a new directory:
```bash
mkdir my-first-terraform
cd my-first-terraform
```

2. Create `main.tf`:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "student-bucket-<your-name>-2024"   # Must be globally unique

  tags = {
    Name = "my-first-terraform-bucket"
  }
}
```

3. Run:
```bash
terraform init
terraform plan
terraform apply
```

4. Verify in AWS Console → S3

5. Clean up:
```bash
terraform destroy
```

---

## Deliverable

Screenshot of `terraform apply` output and the bucket visible in the AWS Console.
