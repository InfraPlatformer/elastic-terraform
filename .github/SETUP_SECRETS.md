# 🔐 GitHub Actions Secrets Setup Guide

## 📋 **Required Secrets for CI/CD Pipeline**

### **1. AWS Credentials (Development Environment)**
```bash
AWS_ACCESS_KEY_ID=your_dev_access_key
AWS_SECRET_ACCESS_KEY=your_dev_secret_key
```

### **2. AWS Credentials (Staging Environment)**
```bash
AWS_ACCESS_KEY_ID_STAGING=your_staging_access_key
AWS_SECRET_ACCESS_KEY_STAGING=your_staging_secret_key
```

### **3. AWS Credentials (Production Environment)**
```bash
AWS_ACCESS_KEY_ID_PROD=your_prod_access_key
AWS_SECRET_ACCESS_KEY_PROD=your_prod_secret_key
```

## 🚀 **How to Set Up Secrets**

### **Option 1: GitHub Web Interface**
1. Go to your repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact names above

### **Option 2: GitHub CLI**
```bash
# Install GitHub CLI
gh auth login

# Add secrets
gh secret set AWS_ACCESS_KEY_ID --body "your_dev_access_key"
gh secret set AWS_SECRET_ACCESS_KEY --body "your_dev_secret_key"
gh secret set AWS_ACCESS_KEY_ID_STAGING --body "your_staging_access_key"
gh secret set AWS_SECRET_ACCESS_KEY_STAGING --body "your_staging_secret_key"
gh secret set AWS_ACCESS_KEY_ID_PROD --body "your_prod_access_key"
gh secret set AWS_SECRET_ACCESS_KEY_PROD --body "your_prod_secret_key"
```

## 🔧 **Environment Protection Rules**

### **Development Environment**
- **Required reviewers**: 0
- **Deployment branches**: `develop`, `feature/*`
- **Auto-deploy**: ✅ Enabled

### **Staging Environment**
- **Required reviewers**: 1
- **Deployment branches**: `main`
- **Auto-deploy**: ✅ Enabled

### **Production Environment**
- **Required reviewers**: 2
- **Deployment branches**: `main` (manual trigger only)
- **Auto-deploy**: ❌ Disabled (manual approval required)

## 📁 **Repository Structure for CI/CD**

```
.github/
├── workflows/
│   └── terraform-deploy.yml
├── SETUP_SECRETS.md
└── environments/
    ├── development/
    ├── staging/
    └── production/
```

## 🎯 **First-Time Setup Steps**

1. **Fork/Clone Repository**
   ```bash
   git clone https://github.com/yourusername/elastic-terraform.git
   cd elastic-terraform
   ```

2. **Set Up AWS IAM User**
   ```bash
   # Create IAM user with these policies:
   # - AmazonEKSClusterPolicy
   # - AmazonEKSServicePolicy
   # - AmazonEKSWorkerNodePolicy
   # - AmazonEC2FullAccess (for EKS node management)
   ```

3. **Configure GitHub Secrets**
   - Add all AWS credentials as secrets
   - Verify environment protection rules

4. **Push to Trigger First Run**
   ```bash
   git add .
   git commit -m "Initial CI/CD setup"
   git push origin develop
   ```

## 🔍 **Troubleshooting Common Issues**

### **Issue: AWS Credentials Invalid**
- Verify IAM user has correct permissions
- Check AWS region matches your configuration
- Ensure access keys are active

### **Issue: Terraform Plan Fails**
- Check `terraform.tfvars` syntax
- Verify all required variables are defined
- Check AWS service limits

### **Issue: Helm Deployment Fails**
- Verify Kubernetes cluster is ready
- Check Helm chart versions
- Validate `values.yaml` files

## 📊 **Monitoring Your Pipeline**

- **GitHub Actions**: View runs in Actions tab
- **AWS Console**: Monitor EKS cluster status
- **Kubernetes**: Check pod status with `kubectl`

## 🎉 **Success Indicators**

✅ **Development**: Auto-deploys on `develop` branch pushes
✅ **Staging**: Auto-deploys on `main` branch merges  
✅ **Production**: Manual approval required
✅ **Security**: Automated vulnerability scanning
✅ **Testing**: Integration tests run after deployment
✅ **Notifications**: GitHub notifications for all events

---

**Need Help?** Check the main README.md or create an issue in the repository.
