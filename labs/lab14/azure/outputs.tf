output "resource_group_name" {
  description = "The name of the resource group containing Lab 14 resources"
  value       = azurerm_resource_group.lab14_rg.name
}

output "vm_public_ip" {
  description = "The public IP address of the monitored Virtual Machine"
  value       = azurerm_public_ip.lab14_pip.ip_address
}

output "ssh_private_key" {
  description = "Private key for SSH access to the VM"
  value       = tls_private_key.lab14_key.private_key_pem
  sensitive   = true
}

output "log_analytics_workspace_name" {
  description = "The name of the Azure Log Analytics Workspace collecting performance logs and syslogs"
  value       = azurerm_log_analytics_workspace.lab14_law.name
}
