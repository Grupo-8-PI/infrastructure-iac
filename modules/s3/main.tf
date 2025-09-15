# Variables
variable "staging_bucket_name" {
  description = "Nome do bucket S3 de staging"
  type        = string
  default     = "staging-bucket-aej"
}

variable "trusted_bucket_name" {
  description = "Nome do bucket S3 trusted"
  type        = string
  default     = "trusted-bucket-aej"
}

variable "cured_bucket_name" {
  description = "Nome do bucket S3 cured"
  type        = string
  default     = "cured-bucket-aej"
}

# Resources
resource "aws_s3_bucket" "staging" {
  bucket = var.staging_bucket_name
  
  tags = {
    Name = "staging"
  }
}

resource "aws_s3_bucket" "trusted" {
  bucket = var.trusted_bucket_name
  
  tags = {
    Name = "trusted"
  }
}

resource "aws_s3_bucket" "cured" {
  bucket = var.cured_bucket_name
  
  tags = {
    Name = "cured"
  }
}

# Outputs
output "staging_bucket_id" {
  description = "ID do bucket S3 staging"
  value       = aws_s3_bucket.staging.id
}

output "trusted_bucket_id" {
  description = "ID do bucket S3 trusted"
  value       = aws_s3_bucket.trusted.id
}

output "cured_bucket_id" {
  description = "ID do bucket S3 cured"
  value       = aws_s3_bucket.cured.id
}
