# AWS Provider Setup

This directory contains the Terraform configuration needed to connect to AWS.

## Files

| File | Purpose |
|------|---------|
| `provider.tf` | AWS provider and version constraints |
| `variables.tf` | Input variables (region) |
| `main.tf` | Placeholder for resources |
| `outputs.tf` | Placeholder for outputs |

## Quick Start

```bash
aws configure           # Set up credentials
terraform init          # Download the AWS provider
terraform validate      # Check syntax
```
