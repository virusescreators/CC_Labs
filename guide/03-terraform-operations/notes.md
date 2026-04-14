# Terraform Operations — Extended Notes

## Lifecycle Order (Detailed)

```
terraform init       →  Set up working directory
terraform validate   →  Check syntax (optional but recommended)
terraform fmt        →  Format code (optional but recommended)
terraform plan       →  Preview changes (dry run)
terraform apply      →  Make changes to real infrastructure
terraform show       →  Inspect current state
terraform output     →  Display output values
terraform destroy    →  Tear everything down
```

## Init in Detail

`terraform init` does three things:

1. **Downloads provider plugins** — e.g., `hashicorp/aws v5.x`
2. **Initializes the backend** — sets up state storage (local or remote)
3. **Downloads modules** — if you're using any external modules

The `.terraform/` directory is created after init. **Do not commit** this folder to Git.

## Plan Output Reading

```
# aws_instance.web will be created
+ resource "aws_instance" "web" {
    + ami           = "ami-0c55b159cbfafe1f0"
    + instance_type = "t2.micro"
    + id            = (known after apply)
    + public_ip     = (known after apply)
  }

Plan: 1 to add, 0 to change, 0 to destroy.
```

- `(known after apply)` — value will be assigned by the cloud provider after creation
- The summary at the bottom tells you the total adds, changes, and destroys

## Targeting Specific Resources

You can apply or destroy specific resources without affecting others:

```bash
# Apply only one resource
terraform apply -target=aws_instance.web

# Destroy only one resource
terraform destroy -target=aws_s3_bucket.logs
```

> ⚠️ Use targeting sparingly. It can lead to state drift if overused.

## Refreshing State

If someone manually changes infrastructure outside Terraform:

```bash
terraform refresh    # Deprecated in newer versions
terraform apply -refresh-only   # Recommended approach
```

This updates the state file to match current real-world infrastructure.

---

> Back to: [README](README.md)
