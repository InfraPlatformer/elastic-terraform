# =============================================================================
# BACKUP AND DISASTER RECOVERY CONFIGURATION
# =============================================================================

# Random suffix for unique bucket names
resource "random_id" "backup_bucket_suffix" {
  byte_length = 8
}

# S3 Bucket for Elasticsearch Backups
resource "aws_s3_bucket" "elasticsearch_backups" {
  bucket = "advanced-elastic-backups-${random_id.backup_bucket_suffix.hex}"
  
  tags = merge(var.tags, {
    Name = "elasticsearch-backups-${random_id.backup_bucket_suffix.hex}"
    Type = "Backup Storage"
    Purpose = "Elasticsearch Snapshots"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "elasticsearch_backups" {
  bucket = aws_s3_bucket.elasticsearch_backups.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "elasticsearch_backups" {
  bucket = aws_s3_bucket.elasticsearch_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# S3 Bucket Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "elasticsearch_backups" {
  bucket = aws_s3_bucket.elasticsearch_backups.id

  rule {
    id     = "backup-lifecycle"
    status = "Enabled"

    filter {
      prefix = "elasticsearch/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555  # 7 years
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "elasticsearch_backups" {
  bucket = aws_s3_bucket.elasticsearch_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "elasticsearch_backups" {
  bucket = aws_s3_bucket.elasticsearch_backups.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.elasticsearch_backups.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid    = "DenyIncorrectEncryptionHeader"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.elasticsearch_backups.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.elasticsearch_backups.arn}/*"
        Condition = {
          Null = {
            "s3:x-amz-server-side-encryption" = "true"
          }
        }
      }
    ]
  })
}

# IAM Role for Elasticsearch Backup
resource "aws_iam_role" "elasticsearch_backup" {
  name = "${var.cluster_name}-elasticsearch-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-elasticsearch-backup-role"
    Type = "IAM Role"
    Purpose = "Elasticsearch Backup"
  })
}

# IAM Policy for S3 Backup Access
resource "aws_iam_policy" "elasticsearch_backup" {
  name        = "${var.cluster_name}-elasticsearch-backup-policy"
  description = "Policy for Elasticsearch backup operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.elasticsearch_backups.arn,
          "${aws_s3_bucket.elasticsearch_backups.arn}/*"
        ]
      }
    ]
  })
}

# Attach Backup Policy to Role
resource "aws_iam_role_policy_attachment" "elasticsearch_backup" {
  role       = aws_iam_role.elasticsearch_backup.name
  policy_arn = aws_iam_policy.elasticsearch_backup.arn
}

# Kubernetes Secret for S3 Backup Configuration
resource "kubernetes_secret" "elasticsearch_backup_config" {
  depends_on = [var.eks_cluster]
  metadata {
    name      = "elasticsearch-backup-config"
    namespace = "elasticsearch"
    labels = {
      app = "elasticsearch"
    }
  }

  data = {
    "s3-backup-bucket" = aws_s3_bucket.elasticsearch_backups.bucket
    "s3-backup-region" = var.aws_region
    "s3-backup-role"   = aws_iam_role.elasticsearch_backup.arn
  }

  type = "Opaque"
}

# Elasticsearch Snapshot Repository Configuration
resource "kubernetes_config_map" "elasticsearch_snapshot_repo" {
  depends_on = [var.eks_cluster]
  metadata {
    name      = "elasticsearch-snapshot-repo"
    namespace = "elasticsearch"
    labels = {
      app = "elasticsearch"
    }
  }

  data = {
    "snapshot-repo.yml" = yamlencode({
      type = "s3"
      settings = {
        bucket = aws_s3_bucket.elasticsearch_backups.bucket
        region = var.aws_region
        base_path = "elasticsearch/snapshots"
        compress = true
        server_side_encryption = true
        canned_acl = "private"
      }
    })
  }
}

# CronJob for Automated Backups
resource "kubernetes_manifest" "elasticsearch_backup_cronjob" {
  depends_on = [var.eks_cluster]
  manifest = {
    apiVersion = "batch/v1"
    kind = "CronJob"
    metadata = {
      name = "elasticsearch-backup"
      namespace = "elasticsearch"
      labels = {
        app = "elasticsearch"
      }
    }
    spec = {
      schedule = "0 2 * * *"  # Daily at 2 AM
      concurrencyPolicy = "Forbid"
      successfulJobsHistoryLimit = 3
      failedJobsHistoryLimit = 1
      jobTemplate = {
        spec = {
          template = {
            spec = {
              serviceAccountName = "elasticsearch-backup"
              containers = [
                {
                  name = "backup"
                  image = "curlimages/curl:latest"
                  command = [
                    "/bin/sh"
                  ]
                  args = [
                    "-c",
                    "curl -X PUT 'http://elasticsearch-master:9200/_snapshot/s3_repository/snapshot_$(date +%Y%m%d_%H%M%S)?wait_for_completion=true'"
                  ]
                  env = [
                    {
                      name = "ES_HOST"
                      value = "elasticsearch-master"
                    }
                  ]
                }
              ]
              restartPolicy = "OnFailure"
            }
          }
        }
      }
    }
  }
}

# Service Account for Backup Operations
resource "kubernetes_service_account" "elasticsearch_backup" {
  depends_on = [var.eks_cluster]
  metadata {
    name      = "elasticsearch-backup"
    namespace = "elasticsearch"
    labels = {
      app = "elasticsearch"
    }
  }
}

# Cluster Role for Backup Operations
resource "kubernetes_cluster_role" "elasticsearch_backup" {
  depends_on = [var.eks_cluster]
  metadata {
    name = "elasticsearch-backup"
    labels = {
      app = "elasticsearch"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }
}

# Cluster Role Binding for Backup Operations
resource "kubernetes_cluster_role_binding" "elasticsearch_backup" {
  depends_on = [var.eks_cluster]
  metadata {
    name = "elasticsearch-backup"
    labels = {
      app = "elasticsearch"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "elasticsearch-backup"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "elasticsearch-backup"
    namespace = "elasticsearch"
  }
}
