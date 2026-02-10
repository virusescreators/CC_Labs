resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --- Terraform State Storage ---

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state-${random_id.bucket_suffix.hex}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# --- Terraform State Locking ---

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# --- GitHub Deployer IAM User ---

resource "aws_iam_user" "github_deployer" {
  name = "github_deployer"
  path = "/system/"
}

resource "aws_iam_access_key" "github_deployer" {
  user = aws_iam_user.github_deployer.name
}

# Policy for the deployer user
# Note: In a production environment, you should least-privilege this.
# For this lab/learning environment, we are giving AdministratorAccess
# to ensure it can create all necessary resources for the labs (EC2, VPC, IAM, etc.)
resource "aws_iam_user_policy_attachment" "github_deployer_admin" {
  user       = aws_iam_user.github_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
