output "lb_public_ip" {
  description = "The public IP of the Load Balancer"
  value       = azurerm_public_ip.lab10_lb_pip.ip_address
}
