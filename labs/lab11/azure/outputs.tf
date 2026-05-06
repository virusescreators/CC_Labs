output "agw_public_ip" {
  description = "The public IP of the Application Gateway"
  value       = azurerm_public_ip.lab11_agw_pip.ip_address
}

output "app_url" {
  description = "URL to reach the Frontend App path"
  value       = "http://${azurerm_public_ip.lab11_agw_pip.ip_address}/app/"
}

output "api_url" {
  description = "URL to reach the Backend API path"
  value       = "http://${azurerm_public_ip.lab11_agw_pip.ip_address}/api/"
}
