output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance hosting the application"
  value       = aws_instance.lab13_ec2.public_ip
}

output "application_url" {
  description = "The URL to access the deployed application"
  value       = "http://${aws_instance.lab13_ec2.public_ip}"
}

output "ssh_private_key" {
  description = "Private key for SSH access to the EC2 instance"
  value       = tls_private_key.lab13_key.private_key_pem
  sensitive   = true
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket managing pipeline artifacts"
  value       = aws_s3_bucket.lab13_bucket.bucket
}

output "codepipeline_console_url" {
  description = "AWS Console Link to monitor the Continuous Deployment Pipeline"
  value       = "https://us-east-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.lab13_pipeline.name}/view?region=us-east-1"
}
