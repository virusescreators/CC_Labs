output "web_server_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Visit http://<this-ip> to see nginx running"
}

output "vpc_id" {
  value = aws_vpc.main.id
}
