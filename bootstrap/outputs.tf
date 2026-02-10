output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "The name of the S3 bucket to store Terraform state"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table for state locking"
}

output "github_deployer_access_key_id" {
  value       = aws_iam_access_key.github_deployer.id
  description = "Access Key ID for the github_deployer user"
}

output "github_deployer_secret_access_key" {
  value       = aws_iam_access_key.github_deployer.secret
  description = "Secret Access Key for the github_deployer user"
  sensitive   = true
}
