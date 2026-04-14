# Example 01 — Launching an EC2 Instance on AWS

**Goal**: Create a single EC2 (virtual machine) instance on AWS.

## What this creates

- 1 EC2 instance (t2.micro — free tier eligible)

## How to run

```bash
cd example-01-ec2-instance

terraform init
terraform plan
terraform apply

# Expected output:
# instance_id = "i-0abc1234..."
# public_ip   = "3.91.xx.xx"

terraform destroy   # IMPORTANT — avoid charges!
```
