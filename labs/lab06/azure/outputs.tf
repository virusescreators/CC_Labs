# --- VM Outputs ---

output "vm_name" {
  value       = azurerm_linux_virtual_machine.lab6_vm.name
  description = "Azure VM name"
}

output "vm_public_ip" {
  value       = azurerm_public_ip.lab6_public_ip.ip_address
  description = "Azure VM public IP address"
}

output "web_url" {
  value       = "http://${azurerm_public_ip.lab6_public_ip.ip_address}"
  description = "URL to access the web server"
}

output "ssh_connection_command" {
  value       = "ssh -i lab6-key.pem azureuser@${azurerm_public_ip.lab6_public_ip.ip_address}"
  description = "SSH connection command (save private key first)"
}

# --- Key Pair Outputs ---

output "private_key" {
  value       = tls_private_key.lab6_key.private_key_pem
  sensitive   = true
  description = "Private key PEM — run: terraform output -raw private_key > lab6-key.pem"
}

# --- Resource Group Output ---

output "resource_group_name" {
  value       = azurerm_resource_group.lab6_rg.name
  description = "Resource Group name"
}

# --- Networking Outputs ---

output "vnet_id" {
  value       = azurerm_virtual_network.lab6_vnet.id
  description = "Virtual Network ID"
}

output "nsg_id" {
  value       = azurerm_network_security_group.lab6_nsg.id
  description = "Network Security Group ID"
}
