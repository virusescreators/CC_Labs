output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.lab9_alb.dns_name
}

output "private_key" {
  description = "The private key to SSH into the EC2 instances (for debugging)"
  value       = tls_private_key.lab9_key.private_key_pem
  sensitive   = true
}

output "instance_1_public_ip" {
  description = "The public IP of Instance A (Note: HTTP access is blocked directly to this IP, only SSH is allowed)"
  value       = aws_instance.lab9_instance_1.public_ip
}

output "instance_2_public_ip" {
  description = "The public IP of Instance B (Note: HTTP access is blocked directly to this IP, only SSH is allowed)"
  value       = aws_instance.lab9_instance_2.public_ip
}
