# =============================================================================
# DEPLOY FIXED INFRASTRUCTURE SCRIPT
# =============================================================================
# This script deploys the fixed infrastructure in the correct order
# to avoid CRD and security group issues
# =============================================================================

param(
    [switch]$CheckStatus,
    [switch]$DeployCore,
    [switch]$DeployMonitoring,
    [switch]$DeployAll,
    [switch]$DestroyAndRecreate
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

function Test-TerraformConfig {
    Write-ColorOutput "🔍 Validating Terraform configuration..." $Blue
    try {
        $result = terraform validate
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Terraform configuration is valid" $Green
            return $true
        } else {
            Write-ColorOutput "❌ Terraform validation failed" $Red
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Error validating Terraform configuration: $_" $Red
        return $false
    }
}

function Get-InfrastructureStatus {
    Write-ColorOutput "🔍 Checking infrastructure status..." $Blue
    
    # Check EKS cluster
    try {
        $clusterStatus = aws eks describe-cluster --name advanced-elastic-staging-aws --region us-west-2 --query 'cluster.status' --output text 2>$null
        if ($clusterStatus) {
            Write-ColorOutput "✅ EKS Cluster Status: $clusterStatus" $Green
        } else {
            Write-ColorOutput "⚠️ EKS Cluster not found or not accessible" $Yellow
        }
    } catch {
        Write-ColorOutput "❌ Error checking EKS cluster: $_" $Red
    }
    
    # Check security groups
    try {
        $securityGroups = aws ec2 describe-security-groups --filters "Name=group-name,Values=*staging-elastic-eks*" --query 'SecurityGroups[].{Name:GroupName, ID:GroupId}' --output table 2>$null
        if ($securityGroups) {
            Write-ColorOutput "✅ Security Groups Found:" $Green
            Write-Host $securityGroups
        } else {
            Write-ColorOutput "⚠️ No security groups found" $Yellow
        }
    } catch {
        Write-ColorOutput "❌ Error checking security groups: $_" $Red
    }
}

function Deploy-CoreInfrastructure {
    Write-ColorOutput "🚀 Deploying core infrastructure (networking + EKS)..." $Blue
    
    if (-not (Test-TerraformConfig)) {
        Write-ColorOutput "❌ Cannot deploy - Terraform configuration is invalid" $Red
        return $false
    }
    
    try {
        # Deploy networking first
        Write-ColorOutput "📡 Deploying networking infrastructure..." $Blue
        terraform apply -target="module.aws_networking" -auto-approve
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Networking deployment failed" $Red
            return $false
        }
        
        # Deploy EKS cluster
        Write-ColorOutput "☸️ Deploying EKS cluster..." $Blue
        terraform apply -target="module.aws_eks" -auto-approve
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ EKS deployment failed" $Red
            return $false
        }
        
        Write-ColorOutput "✅ Core infrastructure deployed successfully" $Green
        return $true
        
    } catch {
        Write-ColorOutput "❌ Error deploying core infrastructure: $_" $Red
        return $false
    }
}

function Deploy-MonitoringStack {
    Write-ColorOutput "📊 Deploying monitoring stack..." $Blue
    
    try {
        # Deploy monitoring components
        terraform apply -target="module.monitoring" -auto-approve
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Monitoring stack deployed successfully" $Green
            return $true
        } else {
            Write-ColorOutput "❌ Monitoring deployment failed" $Red
            return $false
        }
        
    } catch {
        Write-ColorOutput "❌ Error deploying monitoring stack: $_" $Red
        return $false
    }
}

function Deploy-AllInfrastructure {
    Write-ColorOutput "🚀 Deploying complete infrastructure..." $Blue
    
    try {
        terraform apply -auto-approve
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Complete infrastructure deployed successfully" $Green
            return $true
        } else {
            Write-ColorOutput "❌ Complete deployment failed" $Red
            return $false
        }
        
    } catch {
        Write-ColorOutput "❌ Error deploying complete infrastructure: $_" $Red
        return $false
    }
}

function Destroy-AndRecreate {
    Write-ColorOutput "🗑️ Destroying and recreating infrastructure..." $Yellow
    
    try {
        # Destroy specific problematic resources
        Write-ColorOutput "🗑️ Destroying problematic resources..." $Yellow
        terraform destroy -target="module.aws_eks.aws_eks_node_group.main[\"elasticsearch\"]" -auto-approve
        terraform destroy -target="module.aws_eks.aws_eks_node_group.main[\"monitoring\"]" -auto-approve
        
        # Deploy core infrastructure
        if (Deploy-CoreInfrastructure) {
            # Deploy monitoring
            if (Deploy-MonitoringStack) {
                # Deploy remaining components
                Deploy-AllInfrastructure
            }
        }
        
    } catch {
        Write-ColorOutput "❌ Error during destroy and recreate: $_" $Red
    }
}

# Main execution
Write-ColorOutput "🔧 Fixed Infrastructure Deployment Script" $Blue
Write-ColorOutput "=========================================" $Blue

if ($CheckStatus) {
    Get-InfrastructureStatus
} elseif ($DeployCore) {
    Deploy-CoreInfrastructure
} elseif ($DeployMonitoring) {
    Deploy-MonitoringStack
} elseif ($DeployAll) {
    Deploy-AllInfrastructure
} elseif ($DestroyAndRecreate) {
    Destroy-AndRecreate
} else {
    Write-ColorOutput "Usage:" $Blue
    Write-ColorOutput "  .\deploy-fixed-infrastructure.ps1 -CheckStatus" $Yellow
    Write-ColorOutput "  .\deploy-fixed-infrastructure.ps1 -DeployCore" $Yellow
    Write-ColorOutput "  .\deploy-fixed-infrastructure.ps1 -DeployMonitoring" $Yellow
    Write-ColorOutput "  .\deploy-fixed-infrastructure.ps1 -DeployAll" $Yellow
    Write-ColorOutput "  .\deploy-fixed-infrastructure.ps1 -DestroyAndRecreate" $Yellow
}

