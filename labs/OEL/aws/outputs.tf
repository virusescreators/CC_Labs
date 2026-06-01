output "portfolio_alb_dns" {
  description = "The public DNS URL of the Application Load Balancer to access the portfolio web application"
  value       = "http://${aws_lb.portfolio_alb.dns_name}"
}

output "s3_bucket_name" {
  description = "The name of the created S3 storage bucket containing the portfolio assets"
  value       = aws_s3_bucket.portfolio_bucket.bucket
}

output "s3_resume_url" {
  description = "The public URL to download the CV/Resume from the S3 bucket"
  value       = "https://${aws_s3_bucket.portfolio_bucket.bucket_regional_domain_name}/${aws_s3_object.resume.key}"
}

output "s3_project_doc_url" {
  description = "The public URL to view project documentation from the S3 bucket"
  value       = "https://${aws_s3_bucket.portfolio_bucket.bucket_regional_domain_name}/${aws_s3_object.project_doc.key}"
}

output "cloudwatch_dashboard_name" {
  description = "The name of the CloudWatch dashboard created for monitoring"
  value       = aws_cloudwatch_dashboard.oel_dashboard.dashboard_name
}

output "cloudwatch_alarm_name" {
  description = "The name of the CloudWatch alarm checking for High CPU utilization"
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}
