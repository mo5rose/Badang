# modules/storage/main.tf
resource "aws_s3_bucket" "datalake" {
  for_each = toset(["raw", "processed", "curated"])
  
  bucket = "datalake-${var.environment}-${each.key}"
  
  versioning {
    enabled = true
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  lifecycle_rule {
    enabled = true
    
    transition {
      days          = 90
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

resource "aws_efs_file_system" "datalake" {
  creation_token = "datalake-${var.environment}"
  encrypted      = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = {
    Name = "datalake-${var.environment}-efs"
  }
}