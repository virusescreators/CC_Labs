terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"   # Your S3 bucket
    key            = "global/terraform.tfstate"     # Path inside bucket
    region         = "us-east-1"
    encrypt        = true

    # DynamoDB table for state locking
    dynamodb_table = "terraform-state-lock"
  }
}
