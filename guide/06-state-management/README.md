# 06 — State Management

## What is Terraform State?

Terraform stores the current state of your infrastructure in a file called `terraform.tfstate`.

This file is how Terraform:
- Knows what resources it has created
- Detects drift (changes made outside Terraform)
- Plans what needs to change on the next `apply`

## Local vs Remote State

| | Local State | Remote State |
|---|---|---|
| Location | Your machine | Cloud storage (S3, Azure Blob, GCS) |
| Team usage | ❌ Problematic | ✅ Shared access |
| Locking | ❌ No | ✅ Prevents simultaneous changes |
| Security | ❌ Risk of exposure | ✅ Encrypted at rest |

## Remote Backend Example (AWS S3 + DynamoDB)

See [`backend.tf`](backend.tf) for the configuration.

### Setup Steps

1. Create an S3 bucket for state:
```bash
aws s3api create-bucket --bucket my-terraform-state-bucket --region us-east-1
```

2. Create a DynamoDB table for state locking:
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

3. Add `backend.tf` to your project and run `terraform init` again.

## Important Rules

- **Never commit** `terraform.tfstate` or `terraform.tfstate.backup` to Git
- Add `*.tfstate` and `*.tfstate.backup` to your `.gitignore`
- Use remote state for all team projects

---

> See [`notes.md`](notes.md) for extended notes.  
> Next: [`07-modules/`](../07-modules/)
