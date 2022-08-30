# Introducing Backend on S3 
resource "aws_s3_bucket" "awe-terraform_state" {
  bucket = "awe-terraform-bucket"
  # Enable versioning so we can see the full revision history of our state files
  versioning {
    enabled = true
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "awe-terraform_locks" {
  name         = "awe-terraform-bucket-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

 terraform {
   backend "s3" {
     bucket         = "awe-terraform-bucket"
     key            = "global/s3/terraform.tfstate"
     region         = "us-west-2"
     dynamodb_table = "awe-terraform-bucket-locks"
     encrypt        = true
   }
 }