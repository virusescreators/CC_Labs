output "storage_account_name" {
  value       = azurerm_storage_account.lab3_storage.name
  description = "Name of the Storage Account"
}

output "primary_container_name" {
  value       = azurerm_storage_container.lab3_container.name
  description = "Name of the primary blob container (public read)"
}

output "secondary_container_name" {
  value       = azurerm_storage_container.lab3_container_secondary.name
  description = "Name of the secondary blob container (private)"
}

output "primary_container_access_type" {
  value       = azurerm_storage_container.lab3_container.container_access_type
  description = "Access type of the primary container"
}

output "managed_disk_id" {
  value       = azurerm_managed_disk.lab3_disk.id
  description = "ID of the Managed Disk (EBS equivalent)"
}

output "file_share_name" {
  value       = azurerm_storage_share.lab3_fileshare.name
  description = "Name of the Azure Files share (EFS equivalent)"
}

output "blob_versioning_enabled" {
  value       = true
  description = "Whether blob versioning is enabled on the storage account"
}

output "lifecycle_rules" {
  value       = azurerm_storage_management_policy.lab3_lifecycle.rule[*].name
  description = "List of lifecycle rule names"
}
