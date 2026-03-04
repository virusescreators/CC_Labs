# --- DynamoDB Outputs ---

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.lab4_table.name
  description = "Name of the DynamoDB table"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.lab4_table.arn
  description = "ARN of the DynamoDB table"
}

output "dynamodb_stream_arn" {
  value       = aws_dynamodb_table.lab4_table.stream_arn
  description = "ARN of the DynamoDB Stream"
}

output "dynamodb_gsi_name" {
  value       = "DepartmentIndex"
  description = "Name of the Global Secondary Index"
}

# --- DocumentDB Outputs ---

output "docdb_cluster_endpoint" {
  value       = aws_docdb_cluster.lab4_docdb.endpoint
  description = "DocumentDB cluster endpoint (use for MongoDB Compass)"
}

output "docdb_cluster_port" {
  value       = aws_docdb_cluster.lab4_docdb.port
  description = "DocumentDB cluster port"
}

output "docdb_connection_string" {
  value       = "mongodb://lab4admin:Lab4Pass2026!@${aws_docdb_cluster.lab4_docdb.endpoint}:27017/?tls=true&tlsCAFile=global-bundle.pem&retryWrites=false"
  description = "Connection string for MongoDB Compass (download global-bundle.pem from AWS)"
  sensitive   = true
}

# --- Networking Outputs ---

output "vpc_id" {
  value       = aws_vpc.lab4_vpc.id
  description = "VPC ID for DocumentDB"
}

output "security_group_id" {
  value       = aws_security_group.lab4_docdb_sg.id
  description = "Security Group ID for DocumentDB"
}
