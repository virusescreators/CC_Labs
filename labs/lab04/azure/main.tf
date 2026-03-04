terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {}
}

provider "azurerm" {
  features {}
}

resource "random_id" "suffix" {
  byte_length = 4
}

# --- Resource Group ---
resource "azurerm_resource_group" "lab4_rg" {
  name     = "Lab4-RG"
  location = "East US"
}

# ============================================================
# TASKS 2-6: Cosmos DB with Table API (DynamoDB equivalent)
# ============================================================

# --- Cosmos DB Account (Table API) ---
resource "azurerm_cosmosdb_account" "lab4_table_account" {
  name                = "lab4-table-${random_id.suffix.hex}"
  location            = azurerm_resource_group.lab4_rg.location
  resource_group_name = azurerm_resource_group.lab4_rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  capabilities {
    name = "EnableTable"
  }

  # Free Tier — only one per subscription
  enable_free_tier = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.lab4_rg.location
    failover_priority = 0
  }

  tags = {
    Name = "Lab4-CosmosDB-Table"
  }
}

# --- Cosmos DB Table (DynamoDB Table equivalent) ---
resource "azurerm_cosmosdb_table" "lab4_students_table" {
  name                = "Lab4Students"
  resource_group_name = azurerm_resource_group.lab4_rg.name
  account_name        = azurerm_cosmosdb_account.lab4_table_account.name

  # Task 5 equivalent: Cosmos DB Table API auto-indexes all properties
  # No need for explicit secondary indexes — all fields are queryable

  # Task 6 equivalent: Change Feed is enabled by default on Cosmos DB
  # It works similarly to DynamoDB Streams
}

# --- Tasks 3-4: Insert items & query ---
# NOTE: Terraform does not support inserting items into Cosmos DB Table API.
# After deploying, use Azure Storage Explorer or the Azure Portal:
#
#   Task 3 — Insert items via Azure Portal > Cosmos DB > Data Explorer:
#     PartitionKey: "CS"    RowKey: "S001"   Name: "Ali Khan"        GPA: 3.8
#     PartitionKey: "CS"    RowKey: "S002"   Name: "Sara Ahmed"      GPA: 3.5
#     PartitionKey: "EE"    RowKey: "S003"   Name: "Usman Tariq"     GPA: 3.2
#     PartitionKey: "ME"    RowKey: "S004"   Name: "Fatima Noor"     GPA: 3.9
#
#   Task 4 — Query by partition key:
#     In Data Explorer, filter: PartitionKey eq 'CS'
#

# ============================================================
# TASKS 7-11: Cosmos DB with MongoDB API (DocumentDB equivalent)
# ============================================================

# --- Cosmos DB Account (MongoDB API) ---
resource "azurerm_cosmosdb_account" "lab4_mongo_account" {
  name                = "lab4-mongo-${random_id.suffix.hex}"
  location            = azurerm_resource_group.lab4_rg.location
  resource_group_name = azurerm_resource_group.lab4_rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.lab4_rg.location
    failover_priority = 0
  }

  tags = {
    Name = "Lab4-CosmosDB-MongoDB"
  }
}

# --- MongoDB Database ---
resource "azurerm_cosmosdb_mongo_database" "lab4_db" {
  name                = "lab4db"
  resource_group_name = azurerm_resource_group.lab4_rg.name
  account_name        = azurerm_cosmosdb_account.lab4_mongo_account.name
}

# --- MongoDB Collection (Task 9) ---
resource "azurerm_cosmosdb_mongo_collection" "lab4_students" {
  name                = "students"
  resource_group_name = azurerm_resource_group.lab4_rg.name
  account_name        = azurerm_cosmosdb_account.lab4_mongo_account.name
  database_name       = azurerm_cosmosdb_mongo_database.lab4_db.name
  shard_key           = "department"

  # Task 11: Create indexes
  index {
    keys   = ["_id"]
    unique = true
  }

  index {
    keys = ["department"]
  }

  index {
    keys = ["gpa"]
  }
}

# --- Tasks 8-10: Connect & query via MongoDB Compass ---
# After deploying, get the connection string from:
#   Azure Portal > Cosmos DB > lab4-mongo-xxx > Connection String
#
#   Task 8 — Connect using MongoDB Compass:
#     Use the Primary Connection String from the portal
#
#   Task 9 — Insert documents (via Compass or mongosh):
#     use lab4db
#     db.students.insertMany([
#       { name: "Ali Khan",     department: "CS",  gpa: 3.8 },
#       { name: "Sara Ahmed",   department: "CS",  gpa: 3.5 },
#       { name: "Usman Tariq",  department: "EE",  gpa: 3.2 },
#       { name: "Fatima Noor",  department: "ME",  gpa: 3.9 }
#     ])
#
#   Task 10 — Query data:
#     db.students.find({ department: "CS" })
#     db.students.find({ gpa: { $gte: 3.5 } })
#

# ============================================================
# TASK 12: DynamoDB vs DocumentDB vs Azure Cosmos DB
# ============================================================
#
# | Feature        | AWS DynamoDB          | AWS DocumentDB          | Azure Cosmos DB (Table) | Azure Cosmos DB (MongoDB) |
# |---------------|----------------------|------------------------|------------------------|--------------------------|
# | Type          | Key-Value NoSQL      | Document Store         | Key-Value (Table API)  | Document Store           |
# | Latency       | Single-digit ms      | Low ms                 | Single-digit ms        | Low ms                   |
# | Scalability   | Auto-scales          | Manual scaling         | Auto-scales            | Auto-scales              |
# | Durability    | Multi-AZ default     | Multi-AZ with replicas | Global distribution    | Global distribution      |
# | Streams/Feed  | DynamoDB Streams     | Change Streams         | Change Feed            | Change Feed              |
# | Indexing      | Explicit (GSI/LSI)   | MongoDB indexes        | Auto-indexed           | Configurable indexes     |
# | Pricing       | Pay-per-request      | Instance hours         | RU/s based             | RU/s based               |
#
