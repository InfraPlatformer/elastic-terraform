# =============================================================================
# ADVANCED ELASTIC TERRAFORM INFRASTRUCTURE DEPLOYMENT SCRIPT
# =============================================================================
# This script deploys the complete Elasticsearch infrastructure on AWS
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "development",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# =============================================================================
# CONFIGURATION
# =============================================================================
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Colors for output
$Colors = @{
    Info    = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
    Header  = "Magenta"
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor $Colors.Header
    Write-Host " $Title" -ForegroundColor $Colors.Header
    Write-Host "=" * 80 -ForegroundColor $Colors.Header
    Write-Host ""
}

function Write-Step {
    param(
        [string]$Step,
        [string]$Status = "Info"
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
    Write-Host "$Step" -ForegroundColor $Colors[$Status]
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Test-AWSConnection {
    try {
        $identity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
        if ($identity.Arn) {
            Write-ColorOutput "✓ AWS Identity: $($identity.Arn)" "Success"
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# =============================================================================
# PRE-DEPLOYMENT CHECKS
# =============================================================================
Write-Header "PRE-DEPLOYMENT VALIDATION"

Write-Step "Checking required tools..." "Info"
$requiredTools = @("terraform", "aws", "kubectl")
$missingTools = @()

foreach ($tool in $requiredTools) {
    if (Test-Command $tool) {
        Write-ColorOutput "✓ $tool is available" "Success"
    } else {
        Write-ColorOutput "✗ $tool is missing" "Error"
        $missingTools += $tool
    }
}

if ($missingTools.Count -gt 0) {
    Write-ColorOutput "`nMissing required tools: $($missingTools -join ', ')" "Error"
    Write-ColorOutput "Please install the missing tools and try again." "Error"
    exit 1
}

Write-Step "Checking AWS connection..." "Info"
if (-not (Test-AWSConnection)) {
    Write-ColorOutput "✗ AWS connection failed" "Error"
    Write-ColorOutput "Please configure AWS credentials and try again." "Error"
    exit 1
}

Write-Step "Checking Terraform configuration..." "Info"
if (-not (Test-Path "main.tf")) {
    Write-ColorOutput "✗ main.tf not found" "Error"
    exit 1
}

if (-not (Test-Path "backend.tf")) {
    Write-ColorOutput "✗ backend.tf not found" "Error"
    exit 1
}

# =============================================================================
# INFRASTRUCTURE DEPLOYMENT
# =============================================================================
Write-Header "INFRASTRUCTURE DEPLOYMENT"

if (-not $SkipValidation) {
    Write-Step "Validating Terraform configuration..." "Info"
    try {
        terraform validate
        Write-ColorOutput "✓ Configuration validation passed" "Success"
    }
    catch {
        Write-ColorOutput "✗ Configuration validation failed" "Error"
        exit 1
    }
}

Write-Step "Initializing Terraform..." "Info"
try {
    terraform init -reconfigure
    Write-ColorOutput "✓ Terraform initialization completed" "Success"
}
catch {
    Write-ColorOutput "✗ Terraform initialization failed" "Error"
    exit 1
}

Write-Step "Creating deployment plan..." "Info"
try {
    $planFile = "tfplan-$Environment"
    terraform plan -var-file="environments/$Environment/terraform.tfvars" -out="$planFile"
    Write-ColorOutput "✓ Deployment plan created: $planFile" "Success"
}
catch {
    Write-ColorOutput "✗ Failed to create deployment plan" "Error"
    exit 1
}

if ($DryRun) {
    Write-Header "DRY RUN COMPLETED"
    Write-ColorOutput "This was a dry run. No infrastructure was deployed." "Info"
    Write-ColorOutput "To deploy, run: terraform apply `"$planFile`"" "Info"
    exit 0
}

# =============================================================================
# DEPLOYMENT CONFIRMATION
# =============================================================================
Write-Header "DEPLOYMENT CONFIRMATION"
Write-ColorOutput "Ready to deploy the following infrastructure:" "Info"
Write-ColorOutput "• AWS VPC with public/private subnets" "Info"
Write-ColorOutput "• EKS cluster with Elasticsearch node groups" "Info"
Write-ColorOutput "• Monitoring stack (Prometheus, Grafana, Alertmanager)" "Info"
Write-ColorOutput "• Kibana deployment with RBAC" "Info"
Write-ColorOutput "• Security groups and IAM roles" "Info"
Write-ColorOutput "• VPC endpoints for ECR and S3" "Info"

$confirmation = Read-Host "`nDo you want to proceed with the deployment? (yes/no)"
if ($confirmation -ne "yes") {
    Write-ColorOutput "Deployment cancelled by user." "Warning"
    exit 0
}

# =============================================================================
# EXECUTE DEPLOYMENT
# =============================================================================
Write-Header "EXECUTING DEPLOYMENT"

Write-Step "Applying Terraform configuration..." "Info"
try {
    terraform apply "$planFile"
    Write-ColorOutput "✓ Infrastructure deployment completed successfully!" "Success"
}
catch {
    Write-ColorOutput "✗ Infrastructure deployment failed" "Error"
    Write-ColorOutput "Check the logs above for details." "Error"
    exit 1
}

# =============================================================================
# POST-DEPLOYMENT VERIFICATION
# =============================================================================
Write-Header "POST-DEPLOYMENT VERIFICATION"

Write-Step "Getting cluster information..." "Info"
try {
    $clusterName = terraform output -raw aws_cluster_info | ConvertFrom-Json | Select-Object -ExpandProperty name
    Write-ColorOutput "✓ EKS cluster: $clusterName" "Success"
}
catch {
    Write-ColorOutput "⚠ Could not retrieve cluster information" "Warning"
}

Write-Step "Updating kubectl configuration..." "Info"
try {
    aws eks update-kubeconfig --region us-west-2 --name $clusterName
    Write-ColorOutput "✓ kubectl configuration updated" "Success"
}
catch {
    Write-ColorOutput "⚠ Could not update kubectl configuration" "Warning"
}

Write-Step "Checking cluster status..." "Info"
try {
    kubectl get nodes
    Write-ColorOutput "✓ Cluster nodes are accessible" "Success"
}
catch {
    Write-ColorOutput "⚠ Could not verify cluster nodes" "Warning"
}

# =============================================================================
# DEPLOYMENT COMPLETE
# =============================================================================
Write-Header "DEPLOYMENT COMPLETE"
Write-ColorOutput "🎉 Your Elasticsearch infrastructure has been successfully deployed!" "Success"
Write-ColorOutput "" "Info"
Write-ColorOutput "Next steps:" "Info"
Write-ColorOutput "1. Access Kibana: kubectl port-forward -n kibana svc/kibana-external 5601:5601" "Info"
Write-ColorOutput "2. Access Grafana: kubectl port-forward -n monitoring svc/prometheus-operator-grafana 3000:80" "Info"
Write-ColorOutput "3. Access Prometheus: kubectl port-forward -n monitoring svc/prometheus-operator-kube-p-prometheus 9090:9090" "Info"
Write-ColorOutput "" "Info"
Write-ColorOutput "For more information, check the outputs:" "Info"
Write-ColorOutput "terraform output" "Info"

# Clean up plan file
if (Test-Path "$planFile") {
    Remove-Item "$planFile" -Force
    Write-ColorOutput "✓ Cleaned up temporary files" "Success"
}
