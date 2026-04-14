# 04 — Connecting Terraform to Cloud Providers

Terraform communicates with cloud providers using **credentials**. Each provider has its own authentication method.

## Supported Providers

| Provider | Directory | Auth Method |
|----------|-----------|-------------|
| AWS | [`aws/`](aws/) | AWS CLI / Environment vars / IAM role |
| Azure | [`azure/`](azure/) | Azure CLI / Service Principal |
| GCP | [`gcp/`](gcp/) | gcloud CLI / Service Account JSON |

Each subdirectory contains a ready-to-use `provider.tf` and `variables.tf`.

---

> See [`notes.md`](notes.md) for authentication details.  
> Next: [`05-examples/`](../05-examples/)
