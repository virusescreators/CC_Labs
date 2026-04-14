# --- VPC Outputs ---

output "vpc_id" {
  value       = aws_vpc.lab8_vpc.id
  description = "Custom VPC ID"
}

output "vpc_cidr_block" {
  value       = aws_vpc.lab8_vpc.cidr_block
  description = "VPC CIDR block"
}

# --- Subnet Outputs ---

output "public_subnet_id" {
  value       = aws_subnet.lab8_public_subnet.id
  description = "Public subnet ID"
}

output "public_subnet_cidr" {
  value       = aws_subnet.lab8_public_subnet.cidr_block
  description = "Public subnet CIDR block"
}

output "private_subnet_id" {
  value       = aws_subnet.lab8_private_subnet.id
  description = "Private subnet ID"
}

output "private_subnet_cidr" {
  value       = aws_subnet.lab8_private_subnet.cidr_block
  description = "Private subnet CIDR block"
}

# --- Internet Gateway Output ---

output "internet_gateway_id" {
  value       = aws_internet_gateway.lab8_igw.id
  description = "Internet Gateway ID"
}

# --- Route Table Outputs ---

output "public_route_table_id" {
  value       = aws_route_table.lab8_public_rt.id
  description = "Public route table ID"
}

output "private_route_table_id" {
  value       = aws_route_table.lab8_private_rt.id
  description = "Private route table ID"
}

# --- Security Group Outputs ---

output "public_security_group_id" {
  value       = aws_security_group.lab8_public_sg.id
  description = "Public subnet security group ID"
}

output "private_security_group_id" {
  value       = aws_security_group.lab8_private_sg.id
  description = "Private subnet security group ID"
}

# --- EC2 Instance Outputs ---

output "public_ec2_instance_id" {
  value       = aws_instance.lab8_public_ec2.id
  description = "Public EC2 instance ID"
}

output "public_ec2_public_ip" {
  value       = aws_instance.lab8_public_ec2.public_ip
  description = "Public EC2 instance public IP address"
}

output "public_ec2_private_ip" {
  value       = aws_instance.lab8_public_ec2.private_ip
  description = "Public EC2 instance private IP address"
}

output "private_ec2_instance_id" {
  value       = aws_instance.lab8_private_ec2.id
  description = "Private EC2 instance ID"
}

output "private_ec2_private_ip" {
  value       = aws_instance.lab8_private_ec2.private_ip
  description = "Private EC2 instance private IP address (use to ping/SSH from public EC2)"
}

# --- SSH Key Output ---

output "private_key" {
  value       = tls_private_key.lab8_key.private_key_pem
  sensitive   = true
  description = "SSH private key — run: terraform output -raw private_key > lab8-key.pem"
}
