# 🚀 Terraform Backend Setup Guide

## 📋 Prerequisites

Before running `terraform init`, you need to create the S3 bucket and DynamoDB table for state management.

## 🔧 Step 1: Create S3 Bucket

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://elastic-terraform-state-2024 --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket elastic-terraform-state-2024 \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket elastic-terraform-state-2024 \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'
```

## 🔒 Step 2: Create DynamoDB Table

```bash
# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-west-2
```

## ⚙️ Step 3: Customize Backend Configuration

Edit `backend.tf` and update these values:

```hcl
terraform {
  backend "s3" {
    bucket = "YOUR-UNIQUE-BUCKET-NAME"        # Must be globally unique
    key    = "advanced-elastic/terraform.tfstate"
    region = "YOUR-AWS-REGION"                # Your preferred region
    
    # Enable state locking and consistency checking
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    
    # Enable versioning for state file recovery
    versioning = true
  }
}
```

## 🚀 Step 4: Initialize Terraform

```bash
# Initialize with the new backend configuration
terraform init
```

## 🔍 Step 5: Verify Backend Configuration

```bash
# Check backend configuration
terraform show
```

## 📝 Important Notes

- **Bucket Name**: Must be globally unique across all AWS accounts
- **Region**: Should match your infrastructure region
- **DynamoDB Table**: Required for state locking (prevents concurrent modifications)
- **Encryption**: Enabled by default for security
- **Versioning**: Allows you to recover previous state versions

## 🆘 Troubleshooting

### Bucket Already Exists
If the bucket name is taken, choose a different unique name:
```bash
aws s3 mb s3://elastic-terraform-state-2024-YOURNAME --region us-west-2
```

### Permission Issues
Ensure your AWS credentials have these permissions:
- S3: CreateBucket, PutBucketVersioning, PutBucketEncryption
- DynamoDB: CreateTable, DescribeTable

### Region Mismatch
Make sure the backend region matches where you create the bucket and table.












