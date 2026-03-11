# --- MySQL Flexible Server Outputs ---

output "mysql_server_fqdn" {
  value       = azurerm_mysql_flexible_server.lab5_mysql.fqdn
  description = "MySQL Flexible Server fully qualified domain name"
}

output "mysql_server_name" {
  value       = azurerm_mysql_flexible_server.lab5_mysql.name
  description = "MySQL Flexible Server name"
}

output "mysql_admin_login" {
  value       = azurerm_mysql_flexible_server.lab5_mysql.administrator_login
  description = "MySQL admin username"
}

output "mysql_database_name" {
  value       = azurerm_mysql_flexible_database.lab5_db.name
  description = "MySQL database name"
}

output "mysql_connection_command" {
  value       = "mysql -h ${azurerm_mysql_flexible_server.lab5_mysql.fqdn} -u lab5admin -p lab5db"
  description = "MySQL CLI connection command (you will be prompted for password)"
}

# --- Read Replica Outputs ---

output "mysql_replica_fqdn" {
  value       = azurerm_mysql_flexible_server.lab5_mysql_replica.fqdn
  description = "MySQL read replica fully qualified domain name"
}

output "mysql_replica_name" {
  value       = azurerm_mysql_flexible_server.lab5_mysql_replica.name
  description = "MySQL read replica server name"
}

# --- Resource Group Output ---

output "resource_group_name" {
  value       = azurerm_resource_group.lab5_rg.name
  description = "Resource Group name"
}
