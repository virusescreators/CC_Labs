output "resource_group_name" {
  description = "The name of the resource group containing OEL resources"
  value       = azurerm_resource_group.oel_rg.name
}

output "portfolio_load_balancer_ip" {
  description = "The public IP address of the Azure Load Balancer to access the portfolio web application"
  value       = azurerm_public_ip.oel_pip.ip_address
}

output "storage_account_name" {
  description = "The name of the Azure Storage Account containing the portfolio assets"
  value       = azurerm_storage_account.portfolio_storage.name
}

output "blob_resume_url" {
  description = "The public URL to download the CV/Resume from Azure Blob Storage"
  value       = "https://${azurerm_storage_account.portfolio_storage.name}.blob.core.windows.net/${azurerm_storage_container.assets_container.name}/${azurerm_storage_blob.resume.name}"
}

output "blob_project_doc_url" {
  description = "The public URL to view project documentation from Azure Blob Storage"
  value       = "https://${azurerm_storage_account.portfolio_storage.name}.blob.core.windows.net/${azurerm_storage_container.assets_container.name}/${azurerm_storage_blob.project_doc.name}"
}

output "monitor_workspace_name" {
  description = "The name of the Azure Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.oel_workspace.name
}

output "monitor_metric_alert_name" {
  description = "The name of the Azure Monitor CPU metric alert"
  value       = azurerm_monitor_metric_alert.oel_cpu_alert.name
}
