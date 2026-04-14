# 05 — Connecting Terraform to Cloud Providers

Terraform communicates with cloud providers using **credentials**. Each provider has its own authentication method.

> ⚠️ **Security Rule**: Never hardcode credentials in `.tf` files. Use environment variables or a secrets manager.

---

## AWS

### Step 1 — Install AWS CLI

```bash
# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify
aws --version
```

### Step 2 — Configure Credentials

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format
```

Or set environment variables:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 3 — Provider Block

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region

  # Credentials are read from:
  # 1. Environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
  # 2. ~/.aws/credentials file (configured via `aws configure`)
  # 3. IAM instance profile (when running on EC2)
  # Never hardcode credentials here!
}
```

```hcl
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}
```

---

## Azure

### Step 1 — Install Azure CLI

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login
```

### Step 2 — Provider Block

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}

  # Credentials are read from:
  # 1. Environment variables: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
  # 2. Azure CLI login (`az login`)
  # 3. Managed Identity (when running on Azure VMs)
}
```

---

## GCP

### Step 1 — Install gcloud CLI

```bash
curl https://sdk.cloud.google.com | bash
gcloud init
gcloud auth application-default login
```

### Step 2 — Provider Block

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region

  # Credentials are read from:
  # 1. GOOGLE_APPLICATION_CREDENTIALS environment variable (path to service account JSON)
  # 2. gcloud CLI: `gcloud auth application-default login`
  # 3. Compute Engine default service account (when running on GCE)
}
```

```hcl
variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}
```

---

> Next: [Code Examples →](06-code-examples.md)
