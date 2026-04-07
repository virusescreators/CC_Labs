# --- VPC Outputs ---

output "vpc_id" {
  value       = aws_vpc.lab7_vpc.id
  description = "Custom VPC ID"
}

output "vpc_cidr_block" {
  value       = aws_vpc.lab7_vpc.cidr_block
  description = "VPC CIDR block"
}

# --- Subnet Outputs ---

output "public_subnet_id" {
  value       = aws_subnet.lab7_public_subnet.id
  description = "Public subnet ID"
}

output "public_subnet_cidr" {
  value       = aws_subnet.lab7_public_subnet.cidr_block
  description = "Public subnet CIDR block"
}

output "private_subnet_id" {
  value       = aws_subnet.lab7_private_subnet.id
  description = "Private subnet ID"
}

output "private_subnet_cidr" {
  value       = aws_subnet.lab7_private_subnet.cidr_block
  description = "Private subnet CIDR block"
}

# --- Internet Gateway Output ---

output "internet_gateway_id" {
  value       = aws_internet_gateway.lab7_igw.id
  description = "Internet Gateway ID"
}

# --- Route Table Outputs ---

output "public_route_table_id" {
  value       = aws_route_table.lab7_public_rt.id
  description = "Public route table ID"
}

output "private_route_table_id" {
  value       = aws_route_table.lab7_private_rt.id
  description = "Private route table ID"
}

# --- Security Group Outputs ---

output "public_security_group_id" {
  value       = aws_security_group.lab7_public_sg.id
  description = "Public subnet security group ID"
}

output "private_security_group_id" {
  value       = aws_security_group.lab7_private_sg.id
  description = "Private subnet security group ID"
}
