# --- RDS Primary Instance Outputs ---

output "rds_endpoint" {
  value       = aws_db_instance.lab5_rds.endpoint
  description = "RDS MySQL primary endpoint (host:port)"
}

output "rds_address" {
  value       = aws_db_instance.lab5_rds.address
  description = "RDS MySQL primary hostname"
}

output "rds_port" {
  value       = aws_db_instance.lab5_rds.port
  description = "RDS MySQL port"
}

output "rds_database_name" {
  value       = aws_db_instance.lab5_rds.db_name
  description = "RDS database name"
}

output "rds_username" {
  value       = aws_db_instance.lab5_rds.username
  description = "RDS master username"
}

output "rds_connection_command" {
  value       = "mysql -h ${aws_db_instance.lab5_rds.address} -P 3306 -u lab5admin -p lab5db"
  description = "MySQL CLI connection command (you will be prompted for password)"
}

# --- Snapshot Output ---

output "rds_snapshot_id" {
  value       = aws_db_snapshot.lab5_snapshot.db_snapshot_identifier
  description = "Manual snapshot identifier"
}

output "rds_snapshot_arn" {
  value       = aws_db_snapshot.lab5_snapshot.db_snapshot_arn
  description = "Manual snapshot ARN"
}

# --- Read Replica Outputs ---

output "rds_read_replica_endpoint" {
  value       = aws_db_instance.lab5_read_replica.endpoint
  description = "RDS read replica endpoint (host:port)"
}

output "rds_read_replica_address" {
  value       = aws_db_instance.lab5_read_replica.address
  description = "RDS read replica hostname"
}

# --- Parameter Group Output ---

output "rds_parameter_group_name" {
  value       = aws_db_parameter_group.lab5_params.name
  description = "Custom parameter group name"
}

# --- Networking Outputs ---

output "vpc_id" {
  value       = aws_vpc.lab5_vpc.id
  description = "VPC ID for RDS"
}

output "security_group_id" {
  value       = aws_security_group.lab5_rds_sg.id
  description = "Security Group ID for RDS"
}
