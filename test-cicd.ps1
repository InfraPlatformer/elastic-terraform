# 🧪 CI/CD Pipeline Test Script
# This script tests your CI/CD configuration before pushing to GitHub

Write-Host "🧪 Testing CI/CD Pipeline Configuration" -ForegroundColor Blue
Write-Host "=====================================" -ForegroundColor Blue

$errors = @()
$warnings = @()

# Test 1: Check if we're in the right directory
Write-Host "`n1️⃣  Checking project structure..." -ForegroundColor White
if (Test-Path ".github/workflows/terraform-deploy.yml") {
    Write-Host "   ✅ GitHub Actions workflow found" -ForegroundColor Green
} else {
    $errors += "GitHub Actions workflow missing"
    Write-Host "   ❌ GitHub Actions workflow missing" -ForegroundColor Red
}

# Test 2: Check environment configurations
Write-Host "`n2️⃣  Checking environment configurations..." -ForegroundColor White
$environments = @("development", "staging", "production")
foreach ($env in $environments) {
    $configPath = "environments/$env/terraform.tfvars"
    if (Test-Path $configPath) {
        Write-Host "   ✅ $env environment config found" -ForegroundColor Green
    } else {
        $warnings += "$env environment configuration missing"
        Write-Host "   ⚠️  $env environment config missing" -ForegroundColor Yellow
    }
}

# Test 3: Check Terraform files
Write-Host "`n3️⃣  Checking Terraform configuration..." -ForegroundColor White
if (Test-Path "main.tf") {
    Write-Host "   ✅ main.tf found" -ForegroundColor Green
} else {
    $errors += "main.tf missing"
    Write-Host "   ❌ main.tf missing" -ForegroundColor Red
}

if (Test-Path "variables.tf") {
    Write-Host "   ✅ variables.tf found" -ForegroundColor Green
} else {
    $warnings += "variables.tf missing"
    Write-Host "   ⚠️  variables.tf missing" -ForegroundColor Yellow
}

# Test 4: Check Helm values
Write-Host "`n4️⃣  Checking Helm configurations..." -ForegroundColor White
if (Test-Path "elasticsearch-values.yaml") {
    Write-Host "   ✅ Elasticsearch values found" -ForegroundColor Green
} else {
    $warnings += "elasticsearch-values.yaml missing"
    Write-Host "   ⚠️  Elasticsearch values missing" -ForegroundColor Yellow
}

if (Test-Path "kibana-values.yaml") {
    Write-Host "   ✅ Kibana values found" -ForegroundColor Green
} else {
    $warnings += "kibana-values.yaml missing"
    Write-Host "   ⚠️  Kibana values missing" -ForegroundColor Yellow
}

# Test 5: Check documentation
Write-Host "`n5️⃣  Checking documentation..." -ForegroundColor White
$docs = @("README.md", "QUICK_START.md", "PROJECT_SUMMARY.md", "PRESENTATION_TEMPLATE.md")
foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-Host "   ✅ $doc found" -ForegroundColor Green
    } else {
        $warnings += "$doc missing"
        Write-Host "   ⚠️  $doc missing" -ForegroundColor Yellow
    }
}

# Test 6: Check CI/CD documentation
Write-Host "`n6️⃣  Checking CI/CD documentation..." -ForegroundColor White
if (Test-Path ".github/SETUP_SECRETS.md") {
    Write-Host "   ✅ CI/CD setup guide found" -ForegroundColor Green
} else {
    $warnings += "CI/CD setup guide missing"
    Write-Host "   ⚠️  CI/CD setup guide missing" -ForegroundColor Yellow
}

# Summary
Write-Host "`n📊 Test Results Summary" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

if ($errors.Count -eq 0) {
    Write-Host "✅ All critical tests passed!" -ForegroundColor Green
} else {
    Write-Host "❌ Critical errors found:" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "   • $err" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   • $warning" -ForegroundColor Yellow
    }
}

# Recommendations
Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "=============" -ForegroundColor Cyan

if ($errors.Count -eq 0) {
    Write-Host "✅ Your CI/CD pipeline is ready for GitHub!" -ForegroundColor Green
    Write-Host "`n🚀 To deploy:" -ForegroundColor White
    Write-Host "   1. Create GitHub repository" -ForegroundColor Gray
    Write-Host "   2. Configure secrets (see .github/SETUP_SECRETS.md)" -ForegroundColor Gray
    Write-Host "   3. Push to 'develop' branch to trigger deployment" -ForegroundColor Gray
} else {
    Write-Host "❌ Fix the critical errors before proceeding" -ForegroundColor Red
    Write-Host "   See the error list above for details" -ForegroundColor Gray
}

if ($warnings.Count -gt 0) {
    Write-Host "`n💡 Consider addressing warnings for better setup:" -ForegroundColor Yellow
    Write-Host "   These won't prevent deployment but improve the experience" -ForegroundColor Gray
}

Write-Host "`n📚 For detailed setup instructions, run:" -ForegroundColor Cyan
Write-Host "   .\setup-cicd.ps1" -ForegroundColor White
