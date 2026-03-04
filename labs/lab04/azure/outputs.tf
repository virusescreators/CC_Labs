# --- Cosmos DB Table API Outputs ---

output "cosmosdb_table_account_name" {
  value       = azurerm_cosmosdb_account.lab4_table_account.name
  description = "Cosmos DB Table API account name"
}

output "cosmosdb_table_endpoint" {
  value       = azurerm_cosmosdb_account.lab4_table_account.endpoint
  description = "Cosmos DB Table API endpoint"
}

output "cosmosdb_table_name" {
  value       = azurerm_cosmosdb_table.lab4_students_table.name
  description = "Cosmos DB table name"
}

# --- Cosmos DB MongoDB API Outputs ---

output "cosmosdb_mongo_account_name" {
  value       = azurerm_cosmosdb_account.lab4_mongo_account.name
  description = "Cosmos DB MongoDB API account name"
}

output "cosmosdb_mongo_connection_string" {
  value       = azurerm_cosmosdb_account.lab4_mongo_account.connection_strings[0]
  description = "Connection string for MongoDB Compass"
  sensitive   = true
}

output "cosmosdb_mongo_database_name" {
  value       = azurerm_cosmosdb_mongo_database.lab4_db.name
  description = "MongoDB database name"
}

output "cosmosdb_mongo_collection_name" {
  value       = azurerm_cosmosdb_mongo_collection.lab4_students.name
  description = "MongoDB collection name"
}

output "resource_group_name" {
  value       = azurerm_resource_group.lab4_rg.name
  description = "Resource Group name"
}
