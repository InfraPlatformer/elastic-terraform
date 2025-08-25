# =============================================================================
# KMS ENCRYPTION FOR PRODUCTION SECURITY - TEMPORARILY DISABLED
# =============================================================================
# ALL KMS RESOURCES ARE TEMPORARILY DISABLED DUE TO IAM PERMISSION ISSUES
# 
# The user 'aws-el' lacks kms:TagResource permission, which prevents:
# - Creating KMS keys
# - Tagging KMS resources
# - Enabling encryption at rest
#
# TO RE-ENABLE: Add the following IAM permissions to user 'aws-el':
# {
#     "Effect": "Allow",
#     "Action": [
#         "kms:CreateKey",
#         "kms:TagResource",
#         "kms:DescribeKey",
#         "kms:ScheduleKeyDeletion",
#         "kms:EnableKeyRotation",
#         "kms:DisableKeyRotation"
#     ],
#     "Resource": "*"
# }
# =============================================================================

# KMS Key for EKS Encryption - TEMPORARILY DISABLED
# resource "aws_kms_key" "eks_encryption" {
#   description             = "EKS Encryption Key for ${var.cluster_name}"
#   deletion_window_in_days = 30
#   enable_key_rotation     = true
#   
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#         Action   = "kms:*"
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow EKS to use the key"
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow EKS Node Groups to use the key"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "kms:ViaService" = "ec2.${data.aws_region.current.name}.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })
#
#   tags = merge(var.tags, {
#     Name = "${var.cluster_name}-eks-encryption-key"
#     Type = "KMS Encryption Key"
#     Purpose = "EKS Cluster Encryption"
#   })
# }

# KMS Key Alias - TEMPORARILY DISABLED
# resource "aws_kms_alias" "eks_encryption" {
#   name          = "alias/${var.cluster_name}-eks-encryption"
#   target_key_id = aws_kms_key.eks_encryption.key_id
# }

# KMS Key for EBS Volume Encryption - TEMPORARILY DISABLED
# resource "aws_kms_key" "ebs_encryption" {
#   description             = "EBS Volume Encryption Key for ${var.cluster_name}"
#   deletion_window_in_days = 30
#   enable_key_rotation     = true
#   
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#         Action   = "kms:*"
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow EKS to use the key for EBS volumes"
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow EC2 to use the key for EBS volumes"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "kms:ViaService" = "ec2.${data.aws_region.current.name}.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })
#
#   tags = merge(var.tags, {
#     Name = "${var.cluster_name}-ebs-encryption-key"
#     Type = "KMS Encryption Key"
#     Purpose = "EBS Volume Encryption"
#   })
# }

# KMS Key Alias for EBS - TEMPORARILY DISABLED
# resource "aws_kms_alias" "ebs_encryption" {
#   name          = "alias/${var.cluster_name}-ebs-encryption"
#   target_key_id = aws_kms_key.ebs_encryption.key_id
# }

# KMS Key for Application Secrets - TEMPORARILY DISABLED
# resource "aws_kms_key" "app_secrets" {
#   description             = "Application Secrets Encryption Key for ${var.cluster_name}"
#   deletion_window_in_days = 30
#   enable_key_rotation     = true
#   
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#         Action   = "kms:*"
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow EKS to use the key for secrets"
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
#
#   tags = merge(var.tags, {
#     Name = "${var.cluster_name}-app-secrets-key"
#     Type = "KMS Encryption Key"
#     Purpose = "Application Secrets Encryption"
#   })
# }

# KMS Key Alias for App Secrets - TEMPORARILY DISABLED
# resource "aws_kms_alias" "app_secrets" {
#   name          = "alias/${var.cluster_name}-app-secrets"
#   target_key_id = aws_kms_key.app_secrets.key_id
# }

# =============================================================================
# END OF KMS CONFIGURATION - ALL RESOURCES DISABLED
# =============================================================================
