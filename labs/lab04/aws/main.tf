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
# TASKS 2-4: DynamoDB Table with Partition Key
# ============================================================

resource "aws_dynamodb_table" "lab4_table" {
  name         = "Lab4-Students"
  billing_mode = "PAY_PER_REQUEST" # On-demand (Free Tier friendly)
  hash_key     = "StudentID"       # Partition Key
  range_key    = "CourseID"        # Sort Key

  attribute {
    name = "StudentID"
    type = "S"
  }

  attribute {
    name = "CourseID"
    type = "S"
  }

  # Task 5: Attribute used by GSI
  attribute {
    name = "Department"
    type = "S"
  }

  # ============================================================
  # TASK 5: Global Secondary Index
  # ============================================================
  # Allows querying by Department instead of StudentID
  global_secondary_index {
    name            = "DepartmentIndex"
    hash_key        = "Department"
    range_key       = "StudentID"
    projection_type = "ALL"
  }

  # ============================================================
  # TASK 6: DynamoDB Streams
  # ============================================================
  # Captures changes (inserts, updates, deletes) in real-time
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES" # Captures both old and new item images

  tags = {
    Name = "Lab4-Students-Table"
  }
}

# ============================================================
# TASK 3: Insert Items into the DynamoDB Table
# ============================================================

resource "aws_dynamodb_table_item" "student_1" {
  table_name = aws_dynamodb_table.lab4_table.name
  hash_key   = aws_dynamodb_table.lab4_table.hash_key
  range_key  = aws_dynamodb_table.lab4_table.range_key

  item = <<ITEM
{
  "StudentID":  {"S": "S001"},
  "CourseID":   {"S": "CS101"},
  "Name":       {"S": "Ali Khan"},
  "Department": {"S": "Computer Science"},
  "GPA":        {"N": "3.8"}
}
ITEM
}

resource "aws_dynamodb_table_item" "student_2" {
  table_name = aws_dynamodb_table.lab4_table.name
  hash_key   = aws_dynamodb_table.lab4_table.hash_key
  range_key  = aws_dynamodb_table.lab4_table.range_key

  item = <<ITEM
{
  "StudentID":  {"S": "S002"},
  "CourseID":   {"S": "CS102"},
  "Name":       {"S": "Sara Ahmed"},
  "Department": {"S": "Computer Science"},
  "GPA":        {"N": "3.5"}
}
ITEM
}

resource "aws_dynamodb_table_item" "student_3" {
  table_name = aws_dynamodb_table.lab4_table.name
  hash_key   = aws_dynamodb_table.lab4_table.hash_key
  range_key  = aws_dynamodb_table.lab4_table.range_key

  item = <<ITEM
{
  "StudentID":  {"S": "S003"},
  "CourseID":   {"S": "EE201"},
  "Name":       {"S": "Usman Tariq"},
  "Department": {"S": "Electrical Engineering"},
  "GPA":        {"N": "3.2"}
}
ITEM
}

resource "aws_dynamodb_table_item" "student_4" {
  table_name = aws_dynamodb_table.lab4_table.name
  hash_key   = aws_dynamodb_table.lab4_table.hash_key
  range_key  = aws_dynamodb_table.lab4_table.range_key

  item = <<ITEM
{
  "StudentID":  {"S": "S004"},
  "CourseID":   {"S": "ME301"},
  "Name":       {"S": "Fatima Noor"},
  "Department": {"S": "Mechanical Engineering"},
  "GPA":        {"N": "3.9"}
}
ITEM
}

# ============================================================
# TASKS 7-8: DocumentDB Cluster (MongoDB-compatible)
# ============================================================

# --- VPC for DocumentDB ---
resource "aws_vpc" "lab4_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Lab4-DocumentDB-VPC"
  }
}

resource "aws_subnet" "lab4_subnet_a" {
  vpc_id            = aws_vpc.lab4_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Lab4-Subnet-A"
  }
}

resource "aws_subnet" "lab4_subnet_b" {
  vpc_id            = aws_vpc.lab4_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Lab4-Subnet-B"
  }
}

# --- Security Group for DocumentDB ---
resource "aws_security_group" "lab4_docdb_sg" {
  name        = "lab4-docdb-sg"
  description = "Allow MongoDB traffic for DocumentDB"
  vpc_id      = aws_vpc.lab4_vpc.id

  ingress {
    description = "MongoDB port"
    from_port   = 27017
    to_port     = 27017
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
    Name = "Lab4-DocumentDB-SG"
  }
}

# --- DocumentDB Subnet Group ---
resource "aws_docdb_subnet_group" "lab4_docdb_subnet_group" {
  name       = "lab4-docdb-subnet-group"
  subnet_ids = [aws_subnet.lab4_subnet_a.id, aws_subnet.lab4_subnet_b.id]

  tags = {
    Name = "Lab4-DocumentDB-SubnetGroup"
  }
}

# --- DocumentDB Cluster ---
resource "aws_docdb_cluster" "lab4_docdb" {
  cluster_identifier      = "lab4-docdb-cluster"
  engine                  = "docdb"
  master_username         = "lab4admin"
  master_password         = "Lab4Pass2026!" # Change in production — use secrets manager
  backup_retention_period = 1
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_docdb_subnet_group.lab4_docdb_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.lab4_docdb_sg.id]

  tags = {
    Name = "Lab4-DocumentDB-Cluster"
  }
}

# --- DocumentDB Instance ---
resource "aws_docdb_cluster_instance" "lab4_docdb_instance" {
  identifier         = "lab4-docdb-instance-1"
  cluster_identifier = aws_docdb_cluster.lab4_docdb.id
  instance_class     = "db.t3.medium" # Smallest available for DocumentDB

  tags = {
    Name = "Lab4-DocumentDB-Instance"
  }
}

# ============================================================
# TASKS 9-11: DocumentDB Collection, Documents & Index
# ============================================================
# NOTE: Terraform does not manage MongoDB collections/documents natively.
# After deploying, connect to DocumentDB via MongoDB Compass or mongosh:
#
#   Connection String (from output):
#     mongodb://lab4admin:Lab4Pass2026!@<endpoint>:27017/?tls=true&tlsCAFile=global-bundle.pem&retryWrites=false
#
#   Task 9 — Create collection & insert documents:
#     use lab4db
#     db.createCollection("students")
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
#   Task 11 — Create an index:
#     db.students.createIndex({ department: 1 })
#     db.students.createIndex({ gpa: -1 })
#
# ============================================================

# ============================================================
# TASK 12: Comparison Notes — DynamoDB vs DocumentDB
# ============================================================
#
# | Feature        | DynamoDB                          | DocumentDB                          |
# |---------------|-----------------------------------|-------------------------------------|
# | Type          | Key-Value / Wide Column (NoSQL)   | Document Store (MongoDB-compatible) |
# | Latency       | Single-digit ms (consistent)      | Low ms (depends on instance size)   |
# | Scalability   | Fully managed, auto-scales        | Manual instance scaling             |
# | Durability    | Multi-AZ replication by default   | Multi-AZ with replica instances     |
# | Query Model   | Partition/Sort key + GSI          | Rich MongoDB query language         |
# | Streams       | DynamoDB Streams (CDC)            | Change Streams (MongoDB-style)      |
# | Best For      | High-throughput, simple lookups   | Complex queries, document nesting   |
# | Pricing       | Pay-per-request or provisioned    | Instance hours + storage            |
#
