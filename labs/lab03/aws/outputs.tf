output "primary_bucket_name" {
  value       = aws_s3_bucket.lab3_bucket.id
  description = "Name of the primary S3 bucket"
}

output "primary_bucket_arn" {
  value       = aws_s3_bucket.lab3_bucket.arn
  description = "ARN of the primary S3 bucket"
}

output "secondary_bucket_name" {
  value       = aws_s3_bucket.lab3_bucket_secondary.id
  description = "Name of the secondary S3 bucket"
}

output "ebs_volume_id" {
  value       = aws_ebs_volume.lab3_volume.id
  description = "ID of the EBS Volume"
}

output "efs_file_system_id" {
  value       = aws_efs_file_system.lab3_efs.id
  description = "ID of the EFS File System"
}

output "versioning_status" {
  value       = aws_s3_bucket_versioning.lab3_versioning.versioning_configuration[0].status
  description = "Versioning status of the primary bucket"
}

output "lifecycle_rules" {
  value       = aws_s3_bucket_lifecycle_configuration.lab3_lifecycle.rule[*].id
  description = "List of lifecycle rule IDs applied to the primary bucket"
}

output "bucket_policy_applied" {
  value       = true
  description = "Whether a public read policy is applied to the primary bucket"
}

output "public_access_block_status" {
  value = {
    block_public_acls       = aws_s3_bucket_public_access_block.lab3_public_access.block_public_acls
    block_public_policy     = aws_s3_bucket_public_access_block.lab3_public_access.block_public_policy
    ignore_public_acls      = aws_s3_bucket_public_access_block.lab3_public_access.ignore_public_acls
    restrict_public_buckets = aws_s3_bucket_public_access_block.lab3_public_access.restrict_public_buckets
  }
  description = "Public access block settings for the primary bucket"
}
