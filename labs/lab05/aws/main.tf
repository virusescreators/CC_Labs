terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# NETWORKING: VPC, Subnets, Security Group for RDS
# ============================================================

resource "aws_vpc" "lab5_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Lab5-RDS-VPC"
  }
}

resource "aws_internet_gateway" "lab5_igw" {
  vpc_id = aws_vpc.lab5_vpc.id

  tags = {
    Name = "Lab5-IGW"
  }
}

resource "aws_route_table" "lab5_public_rt" {
  vpc_id = aws_vpc.lab5_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab5_igw.id
  }

  tags = {
    Name = "Lab5-Public-RT"
  }
}

resource "aws_subnet" "lab5_subnet_a" {
  vpc_id            = aws_vpc.lab5_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Lab5-Subnet-A"
  }
}

resource "aws_subnet" "lab5_subnet_b" {
  vpc_id            = aws_vpc.lab5_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Lab5-Subnet-B"
  }
}

resource "aws_route_table_association" "lab5_rta_a" {
  subnet_id      = aws_subnet.lab5_subnet_a.id
  route_table_id = aws_route_table.lab5_public_rt.id
}

resource "aws_route_table_association" "lab5_rta_b" {
  subnet_id      = aws_subnet.lab5_subnet_b.id
  route_table_id = aws_route_table.lab5_public_rt.id
}

resource "aws_security_group" "lab5_rds_sg" {
  name        = "lab5-rds-sg"
  description = "Allow MySQL traffic for RDS"
  vpc_id      = aws_vpc.lab5_vpc.id

  ingress {
    description = "MySQL port"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Lab only — restrict in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab5-RDS-SG"
  }
}

resource "aws_db_subnet_group" "lab5_subnet_group" {
  name       = "lab5-rds-subnet-group"
  subnet_ids = [aws_subnet.lab5_subnet_a.id, aws_subnet.lab5_subnet_b.id]

  tags = {
    Name = "Lab5-RDS-SubnetGroup"
  }
}

# ============================================================
# TASK 4: Custom DB Parameter Group
# ============================================================
# Allows modifying database engine parameters

resource "aws_db_parameter_group" "lab5_params" {
  name   = "lab5-mysql-params"
  family = "mysql8.0"

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  tags = {
    Name = "Lab5-MySQL-ParameterGroup"
  }
}

# ============================================================
# TASK 1: Create an RDS MySQL Database
# ============================================================
# Free-tier eligible: db.t3.micro, 20 GB gp2, single-AZ

resource "aws_db_instance" "lab5_rds" {
  identifier     = "lab5-rds-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro" # Free Tier eligible

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "lab5db"
  username = "lab5admin"
  password = "Lab5Pass2026!" # Change in production — use Secrets Manager

  parameter_group_name   = aws_db_parameter_group.lab5_params.name
  db_subnet_group_name   = aws_db_subnet_group.lab5_subnet_group.name
  vpc_security_group_ids = [aws_security_group.lab5_rds_sg.id]

  publicly_accessible = true # Lab only — disable in production

  # ============================================================
  # TASK 6: Automated Backups
  # ============================================================
  backup_retention_period = 7             # Keep backups for 7 days
  backup_window           = "03:00-04:00" # UTC — daily backup window

  # General settings
  multi_az            = false # Single-AZ for free tier
  skip_final_snapshot = true  # Lab only — enable in production

  tags = {
    Name = "Lab5-RDS-MySQL"
  }
}

# ============================================================
# TASK 5: Manual Snapshot
# ============================================================
# Creates a manual snapshot of the RDS instance
# To restore: use AWS Console > RDS > Snapshots > Restore Snapshot

resource "aws_db_snapshot" "lab5_snapshot" {
  db_instance_identifier = aws_db_instance.lab5_rds.identifier
  db_snapshot_identifier = "lab5-rds-manual-snapshot"

  tags = {
    Name = "Lab5-RDS-ManualSnapshot"
  }
}

# ============================================================
# TASK 5 (continued): Restore from Snapshot
# ============================================================
# NOTE: Restoring from a snapshot creates a NEW RDS instance.
# Terraform does not support in-place restore. To restore manually:
#
#   1. Go to RDS Console > Snapshots
#   2. Select "lab5-rds-manual-snapshot"
#   3. Click "Restore Snapshot"
#   4. Provide a new DB instance identifier (e.g., lab5-rds-restored)
#   5. Configure settings and click "Restore DB Instance"
#
# To test via CLI:
#   aws rds restore-db-instance-from-db-snapshot \
#     --db-instance-identifier lab5-rds-restored \
#     --db-snapshot-identifier lab5-rds-manual-snapshot

# ============================================================
# TASK 6: Read Replica
# ============================================================
# Creates a read replica of the primary RDS instance

resource "aws_db_instance" "lab5_read_replica" {
  identifier          = "lab5-rds-read-replica"
  replicate_source_db = aws_db_instance.lab5_rds.identifier
  instance_class      = "db.t3.micro"

  publicly_accessible    = true # Lab only
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.lab5_rds_sg.id]

  tags = {
    Name = "Lab5-RDS-ReadReplica"
  }
}

# ============================================================
# TASK 2: Connect to RDS
# ============================================================
# After deploying, connect using any of these methods:
#
#   MySQL CLI:
#     mysql -h <rds_endpoint> -P 3306 -u lab5admin -p
#
#   Python (pymysql):
#     import pymysql
#     conn = pymysql.connect(
#         host='<rds_endpoint>',
#         user='lab5admin',
#         password='Lab5Pass2026!',
#         database='lab5db',
#         port=3306
#     )
#
#   Node.js (mysql2):
#     const mysql = require('mysql2');
#     const conn = mysql.createConnection({
#         host: '<rds_endpoint>',
#         user: 'lab5admin',
#         password: 'Lab5Pass2026!',
#         database: 'lab5db',
#         port: 3306
#     });
#
#   GUI (MySQL Workbench / DBeaver):
#     Host: <rds_endpoint>
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
# TASK 7: Migrate a Local MySQL Database to RDS
# ============================================================
# Steps to migrate using mysqldump:
#
#   1. Export from local MySQL:
#      mysqldump -u root -p local_database > local_backup.sql
#
#   2. Import into RDS:
#      mysql -h <rds_endpoint> -P 3306 -u lab5admin -p lab5db < local_backup.sql
#
#   3. Verify migration:
#      mysql -h <rds_endpoint> -P 3306 -u lab5admin -p -e "USE lab5db; SHOW TABLES;"
#
# Alternative: Use AWS Database Migration Service (DMS) for
# zero-downtime migration with continuous replication.

# ============================================================
# Aurora Notes (Reference Only — Not Free Tier)
# ============================================================
# Amazon Aurora is MySQL/PostgreSQL-compatible but NOT free-tier eligible.
# Key differences from standard RDS:
#   - Cluster-based: 1 writer + up to 15 read replicas
#   - Storage: auto-scales 10 GB → 128 TB, replicated 6x across 3 AZs
#   - Failover: < 30 seconds
#   - Aurora Serverless v2: auto-scales compute based on demand
#
# To create Aurora (will incur charges):
#   aws rds create-db-cluster \
#     --db-cluster-identifier lab5-aurora-cluster \
#     --engine aurora-mysql \
#     --master-username lab5admin \
#     --master-user-password Lab5Pass2026!
