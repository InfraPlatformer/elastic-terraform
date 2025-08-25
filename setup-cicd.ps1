# 🚀 CI/CD Setup Script for Advanced Elasticsearch Terraform
# This script helps you set up the complete CI/CD pipeline

Write-Host "🚀 Setting up CI/CD Pipeline for Advanced Elasticsearch Terraform" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path ".github/workflows/terraform-deploy.yml")) {
    Write-Host "❌ Error: Please run this script from the project root directory" -ForegroundColor Red
    Write-Host "   Expected: .github/workflows/terraform-deploy.yml" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ CI/CD workflow file found!" -ForegroundColor Green

# Check environment configurations
$environments = @("development", "staging", "production")
foreach ($env in $environments) {
    $configPath = "environments/$env/terraform.tfvars"
    if (Test-Path $configPath) {
        Write-Host "✅ $env environment configuration found" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Warning: $env environment configuration missing" -ForegroundColor Yellow
    }
}

Write-Host "`n📋 Next Steps to Complete CI/CD Setup:" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

Write-Host "1️⃣  Set up GitHub Repository:" -ForegroundColor White
Write-Host "   - Create a new repository on GitHub" -ForegroundColor Gray
Write-Host "   - Push this code to the repository" -ForegroundColor Gray

Write-Host "`n2️⃣  Configure GitHub Secrets:" -ForegroundColor White
Write-Host "   - Go to Repository → Settings → Secrets and variables → Actions" -ForegroundColor Gray
Write-Host "   - Add these secrets:" -ForegroundColor Gray
Write-Host "     • AWS_ACCESS_KEY_ID" -ForegroundColor Gray
Write-Host "     • AWS_SECRET_ACCESS_KEY" -ForegroundColor Gray
Write-Host "     • AWS_ACCESS_KEY_ID_STAGING" -ForegroundColor Gray
Write-Host "     • AWS_SECRET_ACCESS_KEY_STAGING" -ForegroundColor Gray
Write-Host "     • AWS_ACCESS_KEY_ID_PROD" -ForegroundColor Gray
Write-Host "     • AWS_SECRET_ACCESS_KEY_PROD" -ForegroundColor Gray

Write-Host "`n3️⃣  Set up Environment Protection Rules:" -ForegroundColor White
Write-Host "   - Development: 0 reviewers required" -ForegroundColor Gray
Write-Host "   - Staging: 1 reviewer required" -ForegroundColor Gray
Write-Host "   - Production: 2 reviewers required" -ForegroundColor Gray

Write-Host "`n4️⃣  Create AWS IAM User:" -ForegroundColor White
Write-Host "   - Create IAM user with EKS and EC2 permissions" -ForegroundColor Gray
Write-Host "   - Generate access keys for each environment" -ForegroundColor Gray

Write-Host "`n5️⃣  Test the Pipeline:" -ForegroundColor White
Write-Host "   - Push to 'develop' branch to trigger development deployment" -ForegroundColor Gray
Write-Host "   - Check GitHub Actions tab for pipeline execution" -ForegroundColor Gray

Write-Host "`n🔧 Quick Commands:" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

Write-Host "Git Setup:" -ForegroundColor White
Write-Host "git init" -ForegroundColor Gray
Write-Host "git add ." -ForegroundColor Gray
Write-Host "git commit -m 'Initial CI/CD setup'" -ForegroundColor Gray
Write-Host "git branch -M main" -ForegroundColor Gray
Write-Host "git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git" -ForegroundColor Gray
Write-Host "git push -u origin main" -ForegroundColor Gray

Write-Host "`nCreate Development Branch:" -ForegroundColor White
Write-Host "git checkout -b develop" -ForegroundColor Gray
Write-Host "git push -u origin develop" -ForegroundColor Gray

Write-Host "`n📚 Documentation:" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "• README.md - Complete project guide" -ForegroundColor Gray
Write-Host "• QUICK_START.md - 15-minute setup guide" -ForegroundColor Gray
Write-Host "• .github/SETUP_SECRETS.md - Detailed secrets setup" -ForegroundColor Gray
Write-Host "• PRESENTATION_TEMPLATE.md - Professional presentation" -ForegroundColor Gray

Write-Host "`n🎯 What Happens After Setup:" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "✅ Push to 'develop' → Auto-deploys to Development environment" -ForegroundColor Green
Write-Host "✅ Merge to 'main' → Auto-deploys to Staging environment" -ForegroundColor Green
Write-Host "✅ Manual trigger → Deploys to Production (with approval)" -ForegroundColor Green
Write-Host "✅ Security scanning → Automated vulnerability detection" -ForegroundColor Green
Write-Host "✅ Testing → Integration tests after deployment" -ForegroundColor Green

Write-Host "`n🚀 Your CI/CD pipeline will be fully automated!" -ForegroundColor Green
Write-Host "   Development: 15 minutes vs 2+ hours manual" -ForegroundColor Gray
Write-Host "   Staging: 10 minutes vs 1+ hour manual" -ForegroundColor Gray
Write-Host "   Production: Manual approval for safety" -ForegroundColor Gray

Write-Host "`nNeed help? Check the documentation or create an issue in the repository." -ForegroundColor Yellow
