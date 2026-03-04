# Lab 03 — S3 Buckets, Volumes, File Systems & Policies

## Objective

Create storage buckets, a volume, and a file system. Explore versioning, lifecycle rules, and public access policies.

---

## AWS

### Task 1 — Storage Resources

| Resource | Description |
|----------|-------------|
| `aws_s3_bucket` (primary) | Main bucket for versioning, lifecycle, and policy tasks |
| `aws_s3_bucket` (secondary) | Secondary bucket to demonstrate multiple buckets |
| `aws_ebs_volume` | 1 GB `gp3` EBS volume in `us-east-1a` |
| `aws_efs_file_system` | Elastic File System with unique creation token |

### Task 2 — Versioning & File Uploads

- Versioning **enabled** on the primary bucket
- 3 sample `.txt` files uploaded to both buckets

### Task 3 — Lifecycle Rules

| Rule | Prefix | Action |
|------|--------|--------|
| `transition-storage-classes` | `documents/` | Standard → Standard-IA (30d) → Glacier (60d) → Deep Archive (90d) |
| `auto-delete-after-30-days` | `temp/` | Delete objects + old versions after 30 days |

### Task 4 — Public Access & Bucket Policy

- Public access block **disabled**, bucket policy grants `s3:GetObject` to `Principal: "*"`
- ⚠️ Lab only — keep public access blocked in production

---

## Azure

### Task 1 — Storage Resources

| Resource | AWS Equivalent | Description |
|----------|---------------|-------------|
| `azurerm_storage_account` | — | Storage account (hosts blobs + file shares) |
| `azurerm_storage_container` (primary) | S3 Bucket | Blob container with public read access |
| `azurerm_storage_container` (secondary) | S3 Bucket | Blob container with private access |
| `azurerm_managed_disk` | EBS Volume | 1 GB Standard LRS managed disk |
| `azurerm_storage_share` | EFS | Azure Files share (1 GB) |

### Task 2 — Versioning & File Uploads

- Blob versioning **enabled** at the storage account level
- 4 sample blobs uploaded to both containers

### Task 3 — Lifecycle Rules

| Rule | Prefix | Action |
|------|--------|--------|
| `transition-access-tiers` | `documents/` | Hot → Cool (30d) → Archive (90d) |
| `auto-delete-temp-blobs` | `temp/` | Delete blobs + snapshots + versions after 30 days |

### Task 4 — Public / Private Access

- Primary container: `blob` access level (public read)
- Secondary container: `private` access level
- Azure uses container access levels, SAS tokens, and RBAC instead of bucket policies

---

## Deployment

```
Actions → Deploy Labs → Lab 3 → aws/azure → apply
```
