output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance hosting the application"
  value       = aws_instance.lab14_ec2.public_ip
}

output "application_url" {
  description = "The url structure (for reference)"
  value       = "http://${aws_instance.lab14_ec2.public_ip}"
}

output "ssh_private_key" {
  description = "Private key for SSH access to the EC2 instance"
  value       = tls_private_key.lab14_key.private_key_pem
  sensitive   = true
}

output "cloudwatch_log_group_name" {
  description = "The name of the custom log group populated in CloudWatch Logs"
  value       = "lab14-ec2-custom-logs"
}
