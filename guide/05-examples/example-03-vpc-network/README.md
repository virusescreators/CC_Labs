# Example 03 — Creating a VPC Network on AWS

**Goal**: Set up a Virtual Private Cloud (VPC) with a public subnet.

## What this creates

- 1 VPC with a custom CIDR block
- 1 Public Subnet inside the VPC
- 1 Internet Gateway (for internet access)
- 1 Route Table with a route to the internet

## How to run

```bash
cd example-03-vpc-network
terraform init
terraform plan
terraform apply
terraform destroy
```
