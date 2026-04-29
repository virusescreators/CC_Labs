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
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "random_id" "suffix" {
  byte_length = 4
}

# --- Resource Group ---
resource "azurerm_resource_group" "lab5_rg" {
  name     = "Lab5-RG"
  location = "East US"
}

# ============================================================
# TASK 1: Azure Database for MySQL Flexible Server
# ============================================================
# Azure equivalent of Amazon RDS MySQL
# Uses Burstable B1ms SKU (cost-effective for labs)

resource "azurerm_mysql_flexible_server" "lab5_mysql" {
  name                   = "lab5-mysql-${random_id.suffix.hex}"
  resource_group_name    = azurerm_resource_group.lab5_rg.name
  location               = azurerm_resource_group.lab5_rg.location
  administrator_login    = "lab5admin"
  administrator_password = "Lab5Pass2026!"

  sku_name = "B_Standard_B1ms" # Burstable tier (cheapest)
  version  = "8.0.21"

  storage {
    size_gb = 20
  }

  # ============================================================
  # TASK 6: Automated Backups
  # ============================================================
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false # Keep costs low for lab

  tags = {
    Name = "Lab5-MySQL-FlexibleServer"
  }
}

# --- Database ---
resource "azurerm_mysql_flexible_database" "lab5_db" {
  name                = "lab5db"
  resource_group_name = azurerm_resource_group.lab5_rg.name
  server_name         = azurerm_mysql_flexible_server.lab5_mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# --- Firewall Rule: Allow all IPs (Lab only) ---
resource "azurerm_mysql_flexible_server_firewall_rule" "lab5_allow_all" {
  name                = "AllowAll"
  resource_group_name = azurerm_resource_group.lab5_rg.name
  server_name         = azurerm_mysql_flexible_server.lab5_mysql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

# ============================================================
# TASK 4: Modify Database Parameters (Server Configurations)
# ============================================================

resource "azurerm_mysql_flexible_server_configuration" "max_connections" {
  name                = "max_connections"
  resource_group_name = azurerm_resource_group.lab5_rg.name
  server_name         = azurerm_mysql_flexible_server.lab5_mysql.name
  value               = "100"
}

resource "azurerm_mysql_flexible_server_configuration" "slow_query_log" {
  name                = "slow_query_log"
  resource_group_name = azurerm_resource_group.lab5_rg.name
  server_name         = azurerm_mysql_flexible_server.lab5_mysql.name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "long_query_time" {
  name                = "long_query_time"
  resource_group_name = azurerm_resource_group.lab5_rg.name
  server_name         = azurerm_mysql_flexible_server.lab5_mysql.name
  value               = "2"
}

resource "azurerm_mysql_flexible_server_configuration" "character_set_server" {
  name                = "character_set_server"
  resource_group_name = azurerm_resource_group.lab5_rg.name
  server_name         = azurerm_mysql_flexible_server.lab5_mysql.name
  value               = "utf8mb4"
}

# ============================================================
# TASK 6: Read Replica
# ============================================================
# Azure MySQL Flexible Server read replica

resource "azurerm_mysql_flexible_server" "lab5_mysql_replica" {
  name                = "lab5-mysql-replica-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.lab5_rg.name
  location            = azurerm_resource_group.lab5_rg.location

  # Link to primary server as replication source
  source_server_id = azurerm_mysql_flexible_server.lab5_mysql.id
  create_mode      = "Replica"

  sku_name = "B_Standard_B1ms"
  version  = "8.0.21"

  storage {
    size_gb = 20
  }

  tags = {
    Name = "Lab5-MySQL-ReadReplica"
  }
}

# ============================================================
# TASK 2: Connect to MySQL Flexible Server
# ============================================================
# After deploying, connect using any of these methods:
#
#   MySQL CLI:
#     mysql -h <server_fqdn> -u lab5admin -p lab5db
#
#   Python (pymysql):
#     import pymysql
#     conn = pymysql.connect(
#         host='<server_fqdn>',
#         user='lab5admin',
#         password='Lab5Pass2026!',
#         database='lab5db',
#         port=3306,
#         ssl={'ca': '/path/to/DigiCertGlobalRootCA.crt.pem'}
#     )
#
#   Node.js (mysql2):
#     const mysql = require('mysql2');
#     const conn = mysql.createConnection({
#         host: '<server_fqdn>',
#         user: 'lab5admin',
#         password: 'Lab5Pass2026!',
#         database: 'lab5db',
#         port: 3306,
#         ssl: { rejectUnauthorized: true }
#     });
#
#   GUI (MySQL Workbench / DBeaver / Azure Data Studio):
#     Host: <server_fqdn>
#     Port: 3306
#     User: lab5admin
#     Password: Lab5Pass2026!

# ============================================================
# TASK 3: Create and Manage Tables
# ============================================================
# After connecting, run these SQL commands:
#
#   CREATE TABLE students (
#       student_id VARCHAR(10) PRIMARY KEY,
#       name VARCHAR(100) NOT NULL,
#       department VARCHAR(100),
#       gpa DECIMAL(3,2),
#       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
#   );
#
#   INSERT INTO students VALUES
#       ('S001', 'Ali Khan', 'Computer Science', 3.80, NOW()),
#       ('S002', 'Sara Ahmed', 'Computer Science', 3.50, NOW()),
#       ('S003', 'Usman Tariq', 'Electrical Engineering', 3.20, NOW()),
#       ('S004', 'Fatima Noor', 'Mechanical Engineering', 3.90, NOW());
#
#   SELECT * FROM students;
#   SELECT * FROM students WHERE department = 'Computer Science';
#   UPDATE students SET gpa = 3.85 WHERE student_id = 'S001';
#   DELETE FROM students WHERE student_id = 'S003';

# ============================================================
# TASK 5: Snapshot (Backup & Restore)
# ============================================================
# Azure MySQL Flexible Server uses automated backups by default.
# Manual Restore via Azure Portal:
#
#   1. Go to Azure Portal > MySQL Flexible Server > lab5-mysql-xxx
#   2. Click "Backup and Restore" in the left menu
#   3. Select a point-in-time restore point
#   4. Click "Restore" → provide a new server name (e.g., lab5-mysql-restored)
#   5. The restored server will appear as a new resource
#
# Via Azure CLI:
#   az mysql flexible-server restore \
#     --resource-group Lab5-RG \
#     --name lab5-mysql-restored \
#     --source-server lab5-mysql-xxx \
#     --restore-point-in-time "2026-03-10T12:00:00Z"

# ============================================================
# TASK 7: Migrate a Local MySQL Database to Azure MySQL
# ============================================================
# Steps to migrate using mysqldump:
#
#   1. Export from local MySQL:
#      mysqldump -u root -p local_database > local_backup.sql
#
#   2. Import into Azure MySQL Flexible Server:
#      mysql -h <server_fqdn> -u lab5admin -p lab5db < local_backup.sql
#
#   3. Verify migration:
#      mysql -h <server_fqdn> -u lab5admin -p -e "USE lab5db; SHOW TABLES;"
#
# Alternative: Use Azure Database Migration Service (DMS) for
# zero-downtime migration with continuous replication.

# ============================================================
# Comparison: AWS RDS vs Azure MySQL Flexible Server
# ============================================================
#
# | Feature          | AWS RDS MySQL                    | Azure MySQL Flexible Server       |
# |-----------------|----------------------------------|-----------------------------------|
# | Type            | Managed Relational DB            | Managed Relational DB             |
# | Engine          | MySQL 8.0                        | MySQL 8.0                         |
# | HA              | Multi-AZ standby                 | Zone-redundant HA                 |
# | Read Replicas   | Up to 5                          | Up to 10                          |
# | Backups         | Automated + manual snapshots     | Automated + point-in-time restore |
# | Scaling         | Vertical (instance resize)       | Vertical (SKU change)             |
# | Parameters      | DB Parameter Groups              | Server Configurations             |
# | Pricing         | Instance hours + storage         | vCore + storage                   |
# | Free Tier       | db.t3.micro (750 hrs/mo)         | B1ms (750 hrs/mo, 12 months)      |
#
