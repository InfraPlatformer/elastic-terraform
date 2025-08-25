# =============================================================================
# OUTPUTS FOR BACKUP MODULE
# =============================================================================

output "backup_bucket_name" {
  description = "Name of the S3 backup bucket"
  value       = aws_s3_bucket.elasticsearch_backups.bucket
}

output "backup_bucket_arn" {
  description = "ARN of the S3 backup bucket"
  value       = aws_s3_bucket.elasticsearch_backups.arn
}
