terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
}

# --- Random suffix for globally unique bucket names ---
resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# TASK 1: Create S3 Buckets, EBS Volume, and EFS File System
# ============================================================

# --- S3 Bucket (Primary - used for versioning, lifecycle, and policy tasks) ---
resource "aws_s3_bucket" "lab3_bucket" {
  bucket = "lab3-bucket-${random_id.suffix.hex}"

  tags = {
    Name        = "Lab3-Primary-Bucket"
    Description = "Primary S3 bucket for Lab 3 tasks"
  }
}

# --- S3 Bucket (Secondary - demonstrates multiple bucket creation) ---
resource "aws_s3_bucket" "lab3_bucket_secondary" {
  bucket = "lab3-secondary-bucket-${random_id.suffix.hex}"

  tags = {
    Name        = "Lab3-Secondary-Bucket"
    Description = "Secondary S3 bucket for Lab 3"
  }
}

# --- EBS Volume ---
resource "aws_ebs_volume" "lab3_volume" {
  availability_zone = "us-east-1a"
  size              = 1 # 1 GB (Free Tier eligible)
  type              = "gp3"

  tags = {
    Name = "Lab3-EBS-Volume"
  }
}

# --- EFS File System ---
resource "aws_efs_file_system" "lab3_efs" {
  creation_token = "lab3-efs-${random_id.suffix.hex}"

  tags = {
    Name = "Lab3-EFS-FileSystem"
  }
}

# ============================================================
# TASK 2: Upload Files & S3 Versioning
# ============================================================

# --- Enable Versioning on the primary bucket ---
resource "aws_s3_bucket_versioning" "lab3_versioning" {
  bucket = aws_s3_bucket.lab3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- Upload sample files to the bucket ---
resource "aws_s3_object" "sample_file_1" {
  bucket  = aws_s3_bucket.lab3_bucket.id
  key     = "documents/sample1.txt"
  content = "This is sample file 1 - version 1. Lab 3 Cloud Computing."

  depends_on = [aws_s3_bucket_versioning.lab3_versioning]

  tags = {
    Name = "Sample-File-1"
  }
}

resource "aws_s3_object" "sample_file_2" {
  bucket  = aws_s3_bucket.lab3_bucket.id
  key     = "documents/sample2.txt"
  content = "This is sample file 2 - version 1. Lab 3 Cloud Computing."

  depends_on = [aws_s3_bucket_versioning.lab3_versioning]

  tags = {
    Name = "Sample-File-2"
  }
}

# Upload the same file to the secondary bucket (without versioning)
resource "aws_s3_object" "secondary_sample_file" {
  bucket  = aws_s3_bucket.lab3_bucket_secondary.id
  key     = "documents/sample1.txt"
  content = "This is a file in the secondary bucket (no versioning)."

  tags = {
    Name = "Secondary-Sample-File"
  }
}

# ============================================================
# TASK 3: S3 Lifecycle Rules
# ============================================================

resource "aws_s3_bucket_lifecycle_configuration" "lab3_lifecycle" {
  bucket = aws_s3_bucket.lab3_bucket.id

  # Rule 1: Transition objects through storage classes
  rule {
    id     = "transition-storage-classes"
    status = "Enabled"

    filter {
      prefix = "documents/"
    }

    # Move to Standard-IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Move to Glacier after 60 days
    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    # Move to Glacier Deep Archive after 90 days
    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }
  }

  # Rule 2: Auto-delete files after 30 days (for temp/ prefix)
  rule {
    id     = "auto-delete-after-30-days"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    expiration {
      days = 30
    }

    # Also clean up old versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [aws_s3_bucket_versioning.lab3_versioning]
}

# Upload a temp file to demonstrate the auto-delete lifecycle rule
resource "aws_s3_object" "temp_file" {
  bucket  = aws_s3_bucket.lab3_bucket.id
  key     = "temp/temporary-file.txt"
  content = "This file will be automatically deleted after 30 days by lifecycle rule."

  depends_on = [aws_s3_bucket_versioning.lab3_versioning]

  tags = {
    Name = "Temp-File-AutoDelete"
  }
}

# ============================================================
# TASK 4: Public Access & Bucket Policy
# ============================================================

# --- Public Access Block (Disabled to allow public policy) ---
# NOTE: By default S3 blocks all public access. We disable the block
#       here to demonstrate applying a public-read policy.
#       In production, always keep public access BLOCKED.
resource "aws_s3_bucket_public_access_block" "lab3_public_access" {
  bucket = aws_s3_bucket.lab3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# --- Bucket Policy: Allow public read access ---
# This policy grants anyone (Principal: "*") read access to all objects.
# WARNING: This is for lab/demo purposes only. Never do this in production.
resource "aws_s3_bucket_policy" "lab3_public_read_policy" {
  bucket = aws_s3_bucket.lab3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.lab3_bucket.arn}/*"
      }
    ]
  })

  # Must disable public access block before applying public policy
  depends_on = [aws_s3_bucket_public_access_block.lab3_public_access]
}
