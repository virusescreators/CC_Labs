# State Management — Extended Notes

## State File Structure

The `terraform.tfstate` file is JSON. A simplified example:

```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "resources": [
    {
      "type": "aws_instance",
      "name": "web",
      "instances": [
        {
          "attributes": {
            "id": "i-0abc1234567890def",
            "ami": "ami-0c55b159cbfafe1f0",
            "instance_type": "t2.micro",
            "public_ip": "3.91.45.67"
          }
        }
      ]
    }
  ]
}
```

## State Locking

When using a remote backend, Terraform **locks** the state file during operations to prevent conflicts:

```
User A runs: terraform apply  →  LOCK acquired
User B runs: terraform apply  →  ERROR: state is locked by User A
User A finishes                →  LOCK released
User B runs: terraform apply  →  LOCK acquired → proceeds
```

DynamoDB provides this locking mechanism for the S3 backend.

## State Commands

```bash
# List all resources tracked in state
terraform state list

# Show details of a specific resource
terraform state show aws_instance.web

# Move a resource (rename without destroying)
terraform state mv aws_instance.old aws_instance.new

# Remove a resource from state (without destroying the actual resource)
terraform state rm aws_instance.web

# Pull remote state to local for inspection
terraform state pull > state.json
```

## Handling State Drift

If someone manually changes infrastructure in the console:

```bash
# Option 1: Refresh state to match reality
terraform apply -refresh-only

# Option 2: Import the changed resource
terraform import aws_instance.web i-0abc1234567890def

# Option 3: Force Terraform's desired state
terraform apply   # will detect and fix the drift
```

---

> Back to: [README](README.md)
