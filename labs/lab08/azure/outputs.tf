# --- Resource Group Output ---

output "resource_group_name" {
  value       = azurerm_resource_group.lab8_rg.name
  description = "Resource Group name"
}

# --- VNet Outputs ---

output "vnet_id" {
  value       = azurerm_virtual_network.lab8_vnet.id
  description = "Virtual Network ID"
}

output "vnet_name" {
  value       = azurerm_virtual_network.lab8_vnet.name
  description = "Virtual Network name"
}

output "vnet_address_space" {
  value       = azurerm_virtual_network.lab8_vnet.address_space
  description = "Virtual Network address space"
}

# --- Subnet Outputs ---

output "public_subnet_id" {
  value       = azurerm_subnet.lab8_public_subnet.id
  description = "Public subnet ID"
}

output "public_subnet_address_prefix" {
  value       = azurerm_subnet.lab8_public_subnet.address_prefixes
  description = "Public subnet address prefix"
}

output "private_subnet_id" {
  value       = azurerm_subnet.lab8_private_subnet.id
  description = "Private subnet ID"
}

output "private_subnet_address_prefix" {
  value       = azurerm_subnet.lab8_private_subnet.address_prefixes
  description = "Private subnet address prefix"
}

# --- Route Table Outputs ---

output "public_route_table_id" {
  value       = azurerm_route_table.lab8_public_rt.id
  description = "Public route table ID"
}

output "private_route_table_id" {
  value       = azurerm_route_table.lab8_private_rt.id
  description = "Private route table ID"
}

# --- NSG Outputs ---

output "public_nsg_id" {
  value       = azurerm_network_security_group.lab8_public_nsg.id
  description = "Public NSG ID"
}

output "private_nsg_id" {
  value       = azurerm_network_security_group.lab8_private_nsg.id
  description = "Private NSG ID"
}

# --- VM Outputs ---

output "public_vm_name" {
  value       = azurerm_linux_virtual_machine.lab8_public_vm.name
  description = "Public VM name"
}

output "public_vm_public_ip" {
  value       = azurerm_public_ip.lab8_public_ip.ip_address
  description = "Public VM public IP address"
}

output "public_vm_private_ip" {
  value       = azurerm_network_interface.lab8_public_nic.private_ip_address
  description = "Public VM private IP address"
}

output "private_vm_name" {
  value       = azurerm_linux_virtual_machine.lab8_private_vm.name
  description = "Private VM name"
}

output "private_vm_private_ip" {
  value       = azurerm_network_interface.lab8_private_nic.private_ip_address
  description = "Private VM private IP address (use to ping/SSH from public VM)"
}

# --- SSH Key Output ---

output "private_key" {
  value       = tls_private_key.lab8_key.private_key_pem
  sensitive   = true
  description = "SSH private key — run: terraform output -raw private_key > lab8-key.pem"
}
