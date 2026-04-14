variable "region" {
  default = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket"
  type        = string
  default     = "terraform-demo-bucket-12345" # Change this to something unique!
}
