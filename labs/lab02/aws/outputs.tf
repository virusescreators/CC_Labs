output "vpc_id" {
  value       = aws_vpc.lab2_vpc.id
  description = "Regional Resource: VPC ID"
}

output "subnet_az" {
  value       = aws_subnet.lab2_subnet.availability_zone
  description = "AZ-Specific Resource: Subnet Availability Zone"
}

output "s3_bucket_region" {
  value       = aws_s3_bucket.lab2_bucket.region
  description = "Regional Resource: S3 Bucket Region"
}

output "iam_group_name" {
  value       = aws_iam_group.lab2_global_group.name
  description = "Global Resource: IAM Group Name"
}
