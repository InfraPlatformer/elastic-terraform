# =============================================================================
# TERRAFORM ISSUE RESOLUTION SCRIPT
# =============================================================================
# This script helps resolve the identified Terraform deployment issues
# Run this script after applying the fixes to the configuration files
# =============================================================================

param(
    [switch]$CheckStatus,
    [switch]$ImportCluster,
    [switch]$VerifyFixes,
    [switch]$FullResolution
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor $Blue
    Write-Host " $Title" -ForegroundColor $Blue
    Write-Host "=" * 80 -ForegroundColor $Blue
}

function Write-Section {
    param([string]$Title)
    Write-Host "`n--- $Title ---" -ForegroundColor $Yellow
}

function Test-TerraformCommand {
    try {
        $version = terraform version
        Write-ColorOutput "✅ Terraform is available: $($version[0])" $Green
        return $true
    }
    catch {
        Write-ColorOutput "❌ Terraform command not found. Please install Terraform first." $Red
        return $false
    }
}

function Test-AWSCLI {
    try {
        $version = aws --version
        Write-ColorOutput "✅ AWS CLI is available: $version" $Green
        return $true
    }
    catch {
        Write-ColorOutput "❌ AWS CLI not found. Please install AWS CLI first." $Red
        return $false
    }
}

function Check-TerraformStatus {
    Write-Section "Checking Terraform Status"
    
    try {
        # Check if we're in a Terraform directory
        if (-not (Test-Path "main.tf")) {
            Write-ColorOutput "❌ Not in a Terraform directory. Please run this script from the terraform project root." $Red
            return $false
        }
        
        # Check current state
        Write-ColorOutput "📊 Checking current Terraform state..." $Blue
        terraform state list | Out-String | Write-Host
        
        # Check for any pending changes
        Write-ColorOutput "📋 Checking for pending changes..." $Blue
        $plan = terraform plan -detailed-exitcode 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ No changes needed. Infrastructure is up to date." $Green
        }
        elseif ($LASTEXITCODE -eq 1) {
            Write-ColorOutput "❌ Error occurred during plan." $Red
            Write-Host $plan
        }
        elseif ($LASTEXITCODE -eq 2) {
            Write-ColorOutput "⚠️ Changes detected. Run 'terraform plan' to see details." $Yellow
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "❌ Error checking Terraform status: $($_.Exception.Message)" $Red
        return $false
    }
}

function Check-EKSClusterStatus {
    Write-Section "Checking EKS Cluster Status"
    
    try {
        Write-ColorOutput "🔍 Checking if EKS cluster exists..." $Blue
        
        $clusterName = "advanced-elastic-staging-aws"
        $region = "us-west-2"
        
        $clusterInfo = aws eks describe-cluster --name $clusterName --region $region --query 'cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}' --output table 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ EKS cluster found:" $Green
            Write-Host $clusterInfo
            
            # Check if cluster is in Terraform state
            $inState = terraform state list | Select-String "eks_cluster"
            if ($inState) {
                Write-ColorOutput "✅ Cluster is managed by Terraform" $Green
            } else {
                Write-ColorOutput "⚠️ Cluster exists in AWS but NOT in Terraform state" $Yellow
                Write-ColorOutput "   You need to import it using: terraform import module.aws_eks.aws_eks_cluster.main $clusterName" $Yellow
            }
        } else {
            Write-ColorOutput "❌ EKS cluster not found or error occurred:" $Red
            Write-Host $clusterInfo
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "❌ Error checking EKS cluster: $($_.Exception.Message)" $Red
        return $false
    }
}

function Import-EKSCluster {
    Write-Section "Importing EKS Cluster into Terraform State"
    
    try {
        $clusterName = "advanced-elastic-staging-aws"
        
        Write-ColorOutput "📥 Importing EKS cluster '$clusterName' into Terraform state..." $Blue
        
        # Check if cluster exists first
        $clusterExists = aws eks describe-cluster --name $clusterName --region us-west-2 --query 'cluster.status' --output text 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Cluster '$clusterName' does not exist. Cannot import." $Red
            return $false
        }
        
        Write-ColorOutput "✅ Cluster exists with status: $clusterExists" $Green
        
        # Import the cluster
        Write-ColorOutput "🔄 Running terraform import..." $Blue
        terraform import "module.aws_eks.aws_eks_cluster.main" $clusterName
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Successfully imported EKS cluster into Terraform state!" $Green
            
            # Verify import
            Write-ColorOutput "🔍 Verifying import..." $Blue
            $imported = terraform state list | Select-String "eks_cluster"
            if ($imported) {
                Write-ColorOutput "✅ Cluster confirmed in Terraform state" $Green
            }
        } else {
            Write-ColorOutput "❌ Failed to import cluster. Check the error above." $Red
            return $false
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "❌ Error importing EKS cluster: $($_.Exception.Message)" $Red
        return $false
    }
}

function Verify-FixesApplied {
    Write-Section "Verifying Fixes Applied"
    
    try {
        # Check if security group duplicate rules are fixed
        Write-ColorOutput "🔍 Checking security group configuration..." $Blue
        $sgFile = "modules/networking/security-groups.tf"
        
        if (Test-Path $sgFile) {
            $duplicateRules = Select-String -Path $sgFile -Pattern "from_port.*443.*to_port.*443" | Measure-Object
            if ($duplicateRules.Count -le 1) {
                Write-ColorOutput "✅ Security group duplicate rules fixed" $Green
            } else {
                Write-ColorOutput "❌ Security group still has duplicate rules" $Red
            }
        }
        
        # Check if KMS resources are commented out
        Write-ColorOutput "🔍 Checking KMS configuration..." $Blue
        $kmsFile = "modules/elasticsearch/kms.tf"
        
        if (Test-Path $kmsFile) {
            $kmsResources = Select-String -Path $kmsFile -Pattern "^resource.*aws_kms_key" | Measure-Object
            if ($kmsResources.Count -eq 0) {
                Write-ColorOutput "✅ KMS resources temporarily disabled" $Green
            } else {
                Write-ColorOutput "⚠️ KMS resources still active - may cause permission errors" $Yellow
            }
        }
        
        Write-ColorOutput "✅ Fix verification complete" $Green
        return $true
    }
    catch {
        Write-ColorOutput "❌ Error verifying fixes: $($_.Exception.Message)" $Red
        return $false
    }
}

function Show-ResolutionSteps {
    Write-Header "ISSUE RESOLUTION STEPS"
    
    Write-ColorOutput "`n📋 Here's what you need to do to resolve the issues:" $Blue
    
    Write-ColorOutput "`n1️⃣ IMMEDIATE - Apply the fixes:" $Yellow
    Write-ColorOutput "   terraform plan" $Blue
    Write-ColorOutput "   terraform apply" $Blue
    
    Write-ColorOutput "`n2️⃣ NEXT - Import existing EKS cluster:" $Yellow
    Write-ColorOutput "   terraform import module.aws_eks.aws_eks_cluster.main advanced-elastic-staging-aws" $Blue
    
    Write-ColorOutput "`n3️⃣ URGENT - Fix IAM permissions for KMS:" $Yellow
    Write-ColorOutput "   Add kms:TagResource permission to user 'aws-el'" $Blue
    Write-ColorOutput "   Re-enable KMS resources in kms.tf" $Blue
    
    Write-ColorOutput "`n4️⃣ FINAL - Re-enable encryption:" $Yellow
    Write-ColorOutput "   Uncomment KMS resources" $Blue
    Write-ColorOutput "   terraform plan && terraform apply" $Blue
    
    Write-ColorOutput "`n📚 For detailed information, see: ISSUE_RESOLUTION_PLAN.md" $Blue
}

# Main execution logic
function Main {
    Write-Header "TERRAFORM ISSUE RESOLUTION SCRIPT"
    
    # Check prerequisites
    if (-not (Test-TerraformCommand)) { return }
    if (-not (Test-AWSCLI)) { return }
    
    # Execute based on parameters
    if ($CheckStatus) {
        Check-TerraformStatus
        Check-EKSClusterStatus
    }
    elseif ($ImportCluster) {
        Import-EKSCluster
    }
    elseif ($VerifyFixes) {
        Verify-FixesApplied
    }
    elseif ($FullResolution) {
        Check-TerraformStatus
        Check-EKSClusterStatus
        Verify-FixesApplied
        Show-ResolutionSteps
    }
    else {
        # Default: show help and current status
        Write-ColorOutput "`n🔧 Terraform Issue Resolution Script" $Blue
        Write-ColorOutput "Usage:" $Yellow
        Write-ColorOutput "  .\resolve-issues.ps1 -CheckStatus    # Check current status" $Blue
        Write-ColorOutput "  .\resolve-issues.ps1 -ImportCluster  # Import existing EKS cluster" $Blue
        Write-ColorOutput "  .\resolve-issues.ps1 -VerifyFixes    # Verify fixes are applied" $Blue
        Write-ColorOutput "  .\resolve-issues.ps1 -FullResolution # Complete status check and resolution steps" $Blue
        
        Write-ColorOutput "`n📊 Current Status:" $Yellow
        Check-TerraformStatus
        Check-EKSClusterStatus
    }
}

# Execute main function
Main
