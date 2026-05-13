output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.lab12_ec2.public_ip
}

output "react_app_url" {
  description = "The URL to access the React application"
  value       = "http://${aws_instance.lab12_ec2.public_ip}"
}

output "ssh_private_key" {
  description = "Private key for SSH access"
  value       = tls_private_key.lab12_key.private_key_pem
  sensitive   = true
}
