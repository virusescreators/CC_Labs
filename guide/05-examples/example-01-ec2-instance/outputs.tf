output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "public_ip" {
  description = "The public IP address of the instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_state" {
  description = "The current state of the instance"
  value       = aws_instance.web_server.instance_state
}
