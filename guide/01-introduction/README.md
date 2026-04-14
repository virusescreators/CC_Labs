# 01 — Introduction to Terraform

## What is Infrastructure as Code (IaC)?

Infrastructure as Code means managing and provisioning computing infrastructure through machine-readable configuration files rather than through manual processes or interactive tools.

Think of it this way:
- A developer writes **application code** to describe how software behaves.
- An infrastructure engineer writes **infrastructure code** to describe how servers, networks, and databases are set up.

## Where Does Terraform Fit?

There are several IaC tools available:

| Tool | Made By | Language | Cloud Support |
|---|---|---|---|
| **Terraform** | HashiCorp | HCL | Multi-cloud (AWS, Azure, GCP, etc.) |
| CloudFormation | AWS | JSON/YAML | AWS only |
| ARM Templates | Microsoft | JSON | Azure only |
| Pulumi | Pulumi | Python/JS/Go | Multi-cloud |
| Ansible | Red Hat | YAML | Multi-cloud (config mgmt focus) |

Terraform is the **industry-standard** for multi-cloud IaC.

## How Terraform Works — The Big Picture

```
You write .tf files
        ↓
Terraform reads them
        ↓
Terraform talks to cloud APIs
        ↓
Cloud creates/updates/deletes infrastructure
        ↓
Terraform saves the result in a state file
```

## Key Terraform File Types

| File | Purpose |
|---|---|
| `main.tf` | Primary resource definitions |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Values to display after apply |
| `provider.tf` | Cloud provider configuration |
| `backend.tf` | Remote state configuration |
| `terraform.tfvars` | Actual variable values (do not commit secrets!) |
| `terraform.tfstate` | State file (auto-generated, do not edit manually) |

---

> See [`notes.md`](notes.md) for extended notes.  
> Next: [`02-core-concepts/`](../02-core-concepts/)
