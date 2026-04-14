# 04 — Terraform Commands Cheatsheet

A quick-reference card for all essential Terraform CLI commands.

---

## Core Workflow

| Command | Description |
|---|---|
| `terraform init` | Initialize directory, download providers |
| `terraform validate` | Check syntax and configuration |
| `terraform fmt` | Format code to style standards |
| `terraform plan` | Preview changes (dry run) |
| `terraform plan -out=plan.tfplan` | Save plan to file |
| `terraform apply` | Apply changes to cloud |
| `terraform apply -auto-approve` | Apply without confirmation prompt |
| `terraform apply plan.tfplan` | Apply a saved plan |
| `terraform destroy` | Destroy all managed infrastructure |
| `terraform destroy -target=<resource>` | Destroy a specific resource |

---

## Inspection & State

| Command | Description |
|---|---|
| `terraform show` | Show current state |
| `terraform state list` | List resources in state |
| `terraform state show <resource>` | Show details of a resource in state |
| `terraform output` | Display output values |
| `terraform import <resource> <id>` | Import existing resource into state |
| `terraform refresh` | Sync state with real infrastructure |
| `terraform graph` | Generate dependency graph (DOT format) |

---

## Workspaces

| Command | Description |
|---|---|
| `terraform workspace list` | List workspaces |
| `terraform workspace new <name>` | Create new workspace |
| `terraform workspace select <name>` | Switch workspace |

---

## Lifecycle Order

```
init → validate → fmt → plan → apply → (manage) → destroy
```

---

> Back to: [Terraform Operations](03-terraform-operations.md) · Next: [Cloud Provider Setup →](05-cloud-provider-setup.md)
