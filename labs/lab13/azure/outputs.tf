output "resource_group_name" {
  description = "The name of the resource group containing Lab 13 resources"
  value       = azurerm_resource_group.lab13_rg.name
}

output "web_app_name" {
  description = "The globally unique name of the Azure Linux Web App"
  value       = azurerm_linux_web_app.lab13_webapp.name
}

output "production_url" {
  description = "The public production URL of your Web Application"
  value       = "https://${azurerm_linux_web_app.lab13_webapp.default_hostname}"
}

output "staging_url" {
  description = "The public staging URL of your Web Application slot"
  value       = "https://${azurerm_linux_web_app_slot.lab13_staging_slot.default_hostname}"
}
