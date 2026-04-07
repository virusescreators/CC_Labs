# --- Resource Group Output ---

output "resource_group_name" {
  value       = azurerm_resource_group.lab7_rg.name
  description = "Resource Group name"
}

# --- VNet Outputs ---

output "vnet_id" {
  value       = azurerm_virtual_network.lab7_vnet.id
  description = "Virtual Network ID"
}

output "vnet_name" {
  value       = azurerm_virtual_network.lab7_vnet.name
  description = "Virtual Network name"
}

output "vnet_address_space" {
  value       = azurerm_virtual_network.lab7_vnet.address_space
  description = "Virtual Network address space"
}

# --- Subnet Outputs ---

output "public_subnet_id" {
  value       = azurerm_subnet.lab7_public_subnet.id
  description = "Public subnet ID"
}

output "public_subnet_address_prefix" {
  value       = azurerm_subnet.lab7_public_subnet.address_prefixes
  description = "Public subnet address prefix"
}

output "private_subnet_id" {
  value       = azurerm_subnet.lab7_private_subnet.id
  description = "Private subnet ID"
}

output "private_subnet_address_prefix" {
  value       = azurerm_subnet.lab7_private_subnet.address_prefixes
  description = "Private subnet address prefix"
}

# --- Route Table Outputs ---

output "public_route_table_id" {
  value       = azurerm_route_table.lab7_public_rt.id
  description = "Public route table ID"
}

output "private_route_table_id" {
  value       = azurerm_route_table.lab7_private_rt.id
  description = "Private route table ID"
}

# --- NSG Outputs ---

output "public_nsg_id" {
  value       = azurerm_network_security_group.lab7_public_nsg.id
  description = "Public NSG ID"
}

output "private_nsg_id" {
  value       = azurerm_network_security_group.lab7_private_nsg.id
  description = "Private NSG ID"
}
