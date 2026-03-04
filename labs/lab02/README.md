# Lab 02 — Regions, Availability Zones & Global Services

## Objective

Understand the difference between regional, AZ-specific, and global services by creating one of each.

---

## AWS

**Resources created:**

| Resource | Type | Description |
|----------|------|-------------|
| `aws_vpc` | Regional | VPC `Lab2-Regional-VPC` with CIDR `10.0.0.0/16` |
| `aws_subnet` | AZ-Specific | Subnet in `us-east-1a` with CIDR `10.0.1.0/24` |
| `aws_s3_bucket` | Regional | S3 bucket with a random suffix |
| `aws_iam_group` | Global | IAM group `Lab2-Global-Group` |

**Key outputs:**
- `vpc_id` — VPC ID (regional resource)
- `subnet_az` — Subnet availability zone (AZ-specific)
- `s3_bucket_region` — S3 bucket region (regional)
- `iam_group_name` — IAM group name (global)

---

## Azure

**Resources created:**

| Resource | Type | Description |
|----------|------|-------------|
| `azurerm_resource_group` | Container | Resource Group `Lab2-RG` in East US |
| `azurerm_virtual_network` | Regional | VNet `Lab2-Regional-VNet` with address space `10.0.0.0/16` |
| `azurerm_subnet` | Regional | Subnet `Lab2-Subnet` with prefix `10.0.1.0/24` |
| `azurerm_storage_account` | Global namespace | Storage account with globally unique name |
| `azuread_group` | Global | Azure AD group `Lab2-Global-Group` |

**Key outputs:**
- `resource_group_name` — Resource group name
- `vnet_name` — Virtual network name (regional)
- `subnet_name` — Subnet name
- `storage_account_name` — Storage account name (global namespace)
- `azure_ad_group_name` — Azure AD group name (global)

---

## Deployment

```
Actions → Deploy Labs → Lab 2 → aws/azure → apply
```
