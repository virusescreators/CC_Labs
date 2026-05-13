output "vm_public_ip" {
  description = "The public IP address of the Virtual Machine"
  value       = azurerm_public_ip.lab12_pip.ip_address
}

output "react_app_url" {
  description = "The URL to access the React application"
  value       = "http://${azurerm_public_ip.lab12_pip.ip_address}"
}

output "ssh_private_key" {
  description = "Private key for SSH access"
  value       = tls_private_key.lab12_key.private_key_pem
  sensitive   = true
}
