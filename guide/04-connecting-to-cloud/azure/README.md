# Azure Provider Setup

This directory contains the Terraform configuration needed to connect to Azure.

## Files

| File | Purpose |
|------|---------|
| `provider.tf` | AzureRM provider and version constraints |
| `variables.tf` | Input variables (location) |
| `main.tf` | Placeholder for resources |
| `outputs.tf` | Placeholder for outputs |

## Quick Start

```bash
az login                # Authenticate with Azure
terraform init          # Download the AzureRM provider
terraform validate      # Check syntax
```
