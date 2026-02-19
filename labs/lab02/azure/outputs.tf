output "resource_group_name" {
  value       = azurerm_resource_group.lab2_rg.name
  description = "Resource Group Name"
}

output "vnet_name" {
  value       = azurerm_virtual_network.lab2_vnet.name
  description = "Regional Resource: Virtual Network Name"
}

output "subnet_name" {
  value       = azurerm_subnet.lab2_subnet.name
  description = "Subnet Name"
}

output "storage_account_name" {
  value       = azurerm_storage_account.lab2_storage.name
  description = "Global Namespace: Storage Account Name"
}

output "azure_ad_group_name" {
  value       = azuread_group.lab2_global_group.display_name
  description = "Global Resource: Azure AD Group Name"
}
