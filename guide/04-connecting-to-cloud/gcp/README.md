# GCP Provider Setup

This directory contains the Terraform configuration needed to connect to Google Cloud Platform.

## Files

| File | Purpose |
|------|---------|
| `provider.tf` | Google provider and version constraints |
| `variables.tf` | Input variables (project, region) |
| `main.tf` | Placeholder for resources |
| `outputs.tf` | Placeholder for outputs |

## Quick Start

```bash
gcloud auth application-default login   # Authenticate
terraform init                           # Download the Google provider
terraform validate                       # Check syntax
```
