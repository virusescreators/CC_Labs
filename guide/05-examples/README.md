# 05 — Hands-On Examples

Practical Terraform examples, progressing from simple to complex. Each example is a self-contained project you can `cd` into and run directly.

## Examples

| # | Directory | What It Creates |
|---|-----------|-----------------|
| 01 | [`example-01-ec2-instance/`](example-01-ec2-instance/) | A single EC2 instance (t2.micro) |
| 02 | [`example-02-s3-bucket/`](example-02-s3-bucket/) | An S3 bucket with versioning |
| 03 | [`example-03-vpc-network/`](example-03-vpc-network/) | VPC + Subnet + Internet Gateway |
| 04 | [`example-04-multi-resource/`](example-04-multi-resource/) | Full stack: VPC + SG + EC2 + Nginx |

## How to Run Any Example

```bash
cd example-XX-name/
terraform init
terraform plan
terraform apply
terraform destroy     # IMPORTANT — always clean up!
```

---

> Next: [`06-state-management/`](../06-state-management/)
