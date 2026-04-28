output "load_balancer_public_ip" {
  description = "The public IP address of the Load Balancer"
  value       = azurerm_public_ip.lab9_lb_pip.ip_address
}

output "private_key" {
  description = "The private key to SSH into the VMs (requires adding inbound NAT rules or a Bastion to use)"
  value       = tls_private_key.lab9_key.private_key_pem
  sensitive   = true
}
