output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.lab11_alb.dns_name
}

output "app_url" {
  description = "URL to reach the Frontend App path"
  value       = "http://${aws_lb.lab11_alb.dns_name}/app/"
}

output "api_url" {
  description = "URL to reach the Backend API path"
  value       = "http://${aws_lb.lab11_alb.dns_name}/api/"
}
