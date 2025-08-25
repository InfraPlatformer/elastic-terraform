# 🚀 Local Development Setup Guide

## 📋 Overview

This guide helps you set up the Elasticsearch Terraform project for local development without requiring AWS credentials or S3 backend access.

## 🔧 Prerequisites

- Terraform >= 1.5.0 installed
- PowerShell or Command Prompt
- Git (for version control)

## 🚀 Quick Start for Local Development

### Step 1: Use Local Backend (Current Setup)

The project is currently configured to use a local backend for development:

```bash
# Navigate to the project directory
cd "C:\Users\alamz\Desktop\Elastic and Terraform\advanced-elastic-terraform"

# Clean up any existing Terraform state
Remove-Item -Recurse -Force .terraform -ErrorAction SilentlyContinue
Remove-Item .terraform.lock.hcl -ErrorAction SilentlyContinue
Remove-Item terraform.tfstate* -ErrorAction SilentlyContinue

# Initialize Terraform with local backend
terraform init
```

### Step 2: Validate Configuration

```bash
# Validate the Terraform configuration
terraform validate

# Check the plan without applying
terraform plan
```

## 🔄 Switching Between Local and S3 Backend

### For Local Development (Current)
- `backend.tf` is commented out
- `backend-local.tf` is active
- State is stored locally in `terraform.tfstate`

### For Production/Team Development
1. Comment out `backend-local.tf`
2. Uncomment `backend.tf`
3. Ensure AWS credentials are configured
4. Run `terraform init -migrate-state`

## 🔑 AWS Credentials Setup (When Ready for S3 Backend)

### Option 1: AWS CLI Configuration
```bash
# Install AWS CLI if not already installed
# Download from: https://aws.amazon.com/cli/

# Configure AWS credentials
aws configure

# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (us-west-2)
# - Default output format (json)
```

### Option 2: Environment Variables
```powershell
# Set environment variables in PowerShell
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_DEFAULT_REGION="us-west-2"

# Or set them permanently in Windows
[Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID", "your-access-key", "User")
[Environment]::SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", "your-secret-key", "User")
[Environment]::SetEnvironmentVariable("AWS_DEFAULT_REGION", "us-west-2", "User")
```

### Option 3: AWS Credentials File
Create `~/.aws/credentials`:
```ini
[default]
aws_access_key_id = your-access-key
aws_secret_access_key = your-secret-key
region = us-west-2
```

## 🏗️ Infrastructure Setup

### Step 1: Create S3 Bucket (When Using S3 Backend)
```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://elastic-terraform-state-2024-alamz --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket elastic-terraform-state-2024-alamz \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket elastic-terraform-state-2024-alamz \
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

### Step 2: Create DynamoDB Table (When Using S3 Backend)
```bash
# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-west-2
```

## 🧪 Testing Your Setup

### Local Testing
```bash
# Test local configuration
terraform plan -var-file=environments/development/terraform.tfvars

# Apply to local environment (if desired)
terraform apply -var-file=environments/development/terraform.tfvars
```

### Validation Commands
```bash
# Check Terraform version
terraform version

# List available commands
terraform -help

# Check current state
terraform show

# List resources
terraform state list
```

## 🆘 Troubleshooting

### Common Issues

#### 1. "No valid credential sources found"
**Cause**: AWS credentials not configured
**Solution**: Use local backend or configure AWS credentials

#### 2. "Backend configuration changed"
**Cause**: Switching between local and S3 backend
**Solution**: Run `terraform init -migrate-state`

#### 3. "Module not found"
**Cause**: Terraform modules not initialized
**Solution**: Run `terraform init`

#### 4. "State file locked"
**Cause**: Another process is using Terraform
**Solution**: Wait or force unlock with `terraform force-unlock <lock-id>`

### Debug Commands
```bash
# Enable debug logging
$env:TF_LOG="DEBUG"
$env:TF_LOG_PATH="terraform.log"

# Run Terraform with verbose output
terraform plan -detailed-exitcode

# Check backend configuration
terraform show
```

## 📁 File Structure for Development

```
advanced-elastic-terraform/
├── backend.tf              # S3 backend (commented for local dev)
├── backend-local.tf        # Local backend (active for local dev)
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── modules/                # Terraform modules
├── environments/           # Environment-specific configurations
│   ├── development/        # Development environment
│   ├── staging/           # Staging environment
│   └── production/        # Production environment
└── docs/                  # Documentation
```

## 🔄 Next Steps

1. **Start with local development** using the current setup
2. **Test your configuration** with `terraform plan`
3. **Set up AWS credentials** when ready for production
4. **Migrate to S3 backend** for team collaboration
5. **Deploy to staging/production** environments

## 📞 Support

If you encounter issues:
1. Check this troubleshooting guide
2. Review Terraform documentation
3. Check AWS credentials and permissions
4. Verify backend configuration
