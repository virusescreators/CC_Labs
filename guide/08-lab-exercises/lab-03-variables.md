# Lab 03 — Variables and Outputs

## Objective

Refactor Lab 02 to use variables and outputs.

---

## Steps

1. Split your code into separate files:

**variables.tf**
```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "region" {
  default = "us-east-1"
}
```

**outputs.tf**
```hcl
output "bucket_arn" {
  value = aws_s3_bucket.my_bucket.arn
}
```

**terraform.tfvars**
```hcl
bucket_name = "student-bucket-yourname-2024"
```

2. Run:
```bash
terraform apply
terraform output
```

---

## Deliverable

Show the `terraform output` result with the bucket ARN displayed.
