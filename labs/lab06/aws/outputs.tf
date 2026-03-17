# --- EC2 Instance Outputs ---

output "instance_id" {
  value       = aws_instance.lab6_ec2.id
  description = "EC2 instance ID"
}

output "instance_public_ip" {
  value       = aws_instance.lab6_ec2.public_ip
  description = "EC2 instance public IP address"
}

output "instance_public_dns" {
  value       = aws_instance.lab6_ec2.public_dns
  description = "EC2 instance public DNS name"
}

output "web_url" {
  value       = "http://${aws_instance.lab6_ec2.public_ip}"
  description = "URL to access the web server"
}

output "ssh_connection_command" {
  value       = "ssh -i lab6-key.pem ec2-user@${aws_instance.lab6_ec2.public_ip}"
  description = "SSH connection command (save private key first)"
}

# --- Key Pair Outputs ---

output "key_pair_name" {
  value       = aws_key_pair.lab6_keypair.key_name
  description = "Key pair name used for the instance"
}

output "private_key" {
  value       = tls_private_key.lab6_key.private_key_pem
  sensitive   = true
  description = "Private key PEM — run: terraform output -raw private_key > lab6-key.pem"
}

# --- Networking Outputs ---

output "vpc_id" {
  value       = aws_vpc.lab6_vpc.id
  description = "VPC ID"
}

output "security_group_id" {
  value       = aws_security_group.lab6_ec2_sg.id
  description = "Security Group ID"
}

output "ami_id" {
  value       = data.aws_ami.amazon_linux.id
  description = "AMI ID used for the instance"
}
