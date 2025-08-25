# =============================================================================
# PRODUCTION DEPLOYMENT SCRIPT
# =============================================================================

param(
    [string]$Environment = "staging",
    [switch]$ValidateOnly = $false,
    [switch]$SkipPrompts = $false
)

# Colors for output
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-Header {
    param([string]$Message)
    Write-Host "`n🔍 $Message" -ForegroundColor $Colors.Header
    Write-Host ("=" * ($Message.Length + 4)) -ForegroundColor $Colors.Header
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor $Colors.Success
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor $Colors.Warning
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor $Colors.Error
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️ $Message" -ForegroundColor $Colors.Info
}

# Pre-deployment validation
Write-Header "PRODUCTION DEPLOYMENT VALIDATION"

# Check AWS credentials
Write-Info "Checking AWS credentials..."
try {
    $identity = aws sts get-caller-identity --query "Account" --output text 2>$null
    if ($identity) {
        Write-Success "AWS credentials valid (Account: $identity)"
    } else {
        Write-Error "AWS credentials invalid"
        exit 1
    }
} catch {
    Write-Error "Failed to validate AWS credentials"
    exit 1
}

# Check Terraform installation
Write-Info "Checking Terraform installation..."
try {
    $tfVersion = terraform version -json | ConvertFrom-Json
    Write-Success "Terraform version: $($tfVersion.terraform_version)"
} catch {
    Write-Error "Terraform not found or not working"
    exit 1
}

# Check current directory
if (-not (Test-Path "main.tf")) {
    Write-Error "Not in Terraform project directory"
    exit 1
}

Write-Success "Pre-deployment validation passed"

if ($ValidateOnly) {
    Write-Header "VALIDATION ONLY MODE"
    Write-Info "Running terraform validate..."
    terraform validate
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Configuration validation passed"
    } else {
        Write-Error "Configuration validation failed"
        exit 1
    }
    exit 0
}

# Production deployment confirmation
if (-not $SkipPrompts) {
    Write-Header "PRODUCTION DEPLOYMENT CONFIRMATION"
    Write-Warning "You are about to deploy to PRODUCTION environment: $Environment"
    Write-Warning "This will create/modify production infrastructure"
    
    $confirmation = Read-Host "Type 'YES' to confirm deployment"
    if ($confirmation -ne "YES") {
        Write-Info "Deployment cancelled by user"
        exit 0
    }
}

# Deployment phases
Write-Header "STARTING PRODUCTION DEPLOYMENT"

# Phase 1: Validate configuration
Write-Info "Phase 1: Validating configuration..."
terraform validate
if ($LASTEXITCODE -ne 0) {
    Write-Error "Configuration validation failed"
    exit 1
}
Write-Success "Configuration validation passed"

# Phase 2: Plan deployment
Write-Info "Phase 2: Planning deployment..."
terraform plan -out=production-plan.tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment planning failed"
    exit 1
}
Write-Success "Deployment plan created"

# Phase 3: Apply infrastructure
Write-Info "Phase 3: Applying infrastructure..."
terraform apply production-plan.tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Error "Infrastructure deployment failed"
    exit 1
}
Write-Success "Infrastructure deployed successfully"

# Phase 4: Post-deployment validation
Write-Header "POST-DEPLOYMENT VALIDATION"

# Check EKS cluster status
Write-Info "Checking EKS cluster status..."
$clusterName = terraform output -raw cluster_name 2>$null
if ($clusterName) {
    $clusterStatus = aws eks describe-cluster --name $clusterName --region us-west-2 --query "cluster.status" --output text 2>$null
    if ($clusterStatus -eq "ACTIVE") {
        Write-Success "EKS cluster is ACTIVE"
    } else {
        Write-Warning "EKS cluster status: $clusterStatus"
    }
} else {
    Write-Warning "Could not retrieve cluster name from outputs"
}

# Check node groups
Write-Info "Checking EKS node groups..."
$nodeGroups = aws eks list-nodegroups --cluster-name $clusterName --region us-west-2 --query "nodegroups" --output text 2>$null
if ($nodeGroups) {
    Write-Success "Node groups found: $nodeGroups"
} else {
    Write-Warning "No node groups found"
}

# Check security groups
Write-Info "Checking security groups..."
$securityGroups = aws ec2 describe-security-groups --filters "Name=group-name,Values=*elastic*" --query "SecurityGroups[].GroupName" --output text 2>$null
if ($securityGroups) {
    Write-Success "Security groups created: $securityGroups"
} else {
    Write-Warning "No security groups found"
}

# Phase 5: Health checks
Write-Header "INFRASTRUCTURE HEALTH CHECKS"

# Run the quick status script
Write-Info "Running infrastructure health check..."
& .\quick-status.ps1

# Final status
Write-Header "DEPLOYMENT COMPLETE"
Write-Success "Production infrastructure has been deployed successfully!"
Write-Info "Next steps:"
Write-Info "1. Access Kibana dashboard"
Write-Info "2. Configure monitoring alerts"
Write-Info "3. Test backup procedures"
Write-Info "4. Review security configurations"

# Cleanup
if (Test-Path "production-plan.tfplan") {
    Remove-Item "production-plan.tfplan"
    Write-Info "Deployment plan file cleaned up"
}
