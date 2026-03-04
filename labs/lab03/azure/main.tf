terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {}
}

provider "azurerm" {
  features {}
}

resource "random_id" "suffix" {
  byte_length = 4
}

# --- Resource Group ---
resource "azurerm_resource_group" "lab3_rg" {
  name     = "Lab3-RG"
  location = "East US"
}

# ============================================================
# TASK 1: Blob Storage (S3), Managed Disk (EBS), Azure Files (EFS)
# ============================================================

# --- Storage Account (required for Blob Storage & Azure Files) ---
resource "azurerm_storage_account" "lab3_storage" {
  name                     = "lab3store${random_id.suffix.hex}"
  resource_group_name      = azurerm_resource_group.lab3_rg.name
  location                 = azurerm_resource_group.lab3_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Task 2: Enable blob versioning
  blob_properties {
    versioning_enabled = true

    # Task 3: Lifecycle rule — delete blobs after 30 days
    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = {
    Name = "Lab3-StorageAccount"
  }
}

# --- Blob Container (S3 Bucket equivalent) — Primary ---
resource "azurerm_storage_container" "lab3_container" {
  name                  = "lab3-primary-container"
  storage_account_name  = azurerm_storage_account.lab3_storage.name
  container_access_type = "blob" # Task 4: public read access at blob level
}

# --- Blob Container — Secondary ---
resource "azurerm_storage_container" "lab3_container_secondary" {
  name                  = "lab3-secondary-container"
  storage_account_name  = azurerm_storage_account.lab3_storage.name
  container_access_type = "private"
}

# --- Upload sample blobs ---
resource "azurerm_storage_blob" "sample_file_1" {
  name                   = "documents/sample1.txt"
  storage_account_name   = azurerm_storage_account.lab3_storage.name
  storage_container_name = azurerm_storage_container.lab3_container.name
  type                   = "Block"
  source_content         = "This is sample file 1 - version 1. Lab 3 Cloud Computing."
}

resource "azurerm_storage_blob" "sample_file_2" {
  name                   = "documents/sample2.txt"
  storage_account_name   = azurerm_storage_account.lab3_storage.name
  storage_container_name = azurerm_storage_container.lab3_container.name
  type                   = "Block"
  source_content         = "This is sample file 2 - version 1. Lab 3 Cloud Computing."
}

resource "azurerm_storage_blob" "secondary_sample_file" {
  name                   = "documents/sample1.txt"
  storage_account_name   = azurerm_storage_account.lab3_storage.name
  storage_container_name = azurerm_storage_container.lab3_container_secondary.name
  type                   = "Block"
  source_content         = "This is a file in the secondary container (private access)."
}

resource "azurerm_storage_blob" "temp_file" {
  name                   = "temp/temporary-file.txt"
  storage_account_name   = azurerm_storage_account.lab3_storage.name
  storage_container_name = azurerm_storage_container.lab3_container.name
  type                   = "Block"
  source_content         = "This file will be automatically deleted after 30 days by lifecycle rule."
}

# --- Managed Disk (EBS Volume equivalent) ---
resource "azurerm_managed_disk" "lab3_disk" {
  name                 = "Lab3-Managed-Disk"
  location             = azurerm_resource_group.lab3_rg.location
  resource_group_name  = azurerm_resource_group.lab3_rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1

  tags = {
    Name = "Lab3-Managed-Disk"
  }
}

# --- Azure Files Share (EFS equivalent) ---
resource "azurerm_storage_share" "lab3_fileshare" {
  name                 = "lab3-fileshare"
  storage_account_name = azurerm_storage_account.lab3_storage.name
  quota                = 1 # 1 GB

}

# ============================================================
# TASK 3: Lifecycle Management Policy
# ============================================================

resource "azurerm_storage_management_policy" "lab3_lifecycle" {
  storage_account_id = azurerm_storage_account.lab3_storage.id

  # Rule 1: Transition blobs through access tiers
  rule {
    name    = "transition-access-tiers"
    enabled = true

    filters {
      prefix_match = ["lab3-primary-container/documents/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        # Move to Cool tier after 30 days
        tier_to_cool_after_days_since_modification_greater_than = 30
        # Move to Archive tier after 90 days
        tier_to_archive_after_days_since_modification_greater_than = 90
      }
    }
  }

  # Rule 2: Auto-delete temp blobs after 30 days
  rule {
    name    = "auto-delete-temp-blobs"
    enabled = true

    filters {
      prefix_match = ["lab3-primary-container/temp/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 30
      }
      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }
      version {
        delete_after_days_since_creation = 30
      }
    }
  }
}

# ============================================================
# TASK 4: Public / Private Access
# ============================================================
# The primary container has container_access_type = "blob" (public read for blobs).
# The secondary container has container_access_type = "private".
#
# To toggle public access at the storage account level, set:
#   allow_blob_public_access = true/false
# on the azurerm_storage_account resource.
#
# Azure does not use "bucket policies" like AWS. Instead, access is controlled via:
#   - Container access level (private / blob / container)
#   - Shared Access Signatures (SAS tokens)
#   - Azure RBAC (role assignments)
#   - Storage account firewall rules
