# =============================================================================
# INFRASTRUCTURE VALIDATION SCRIPT
# =============================================================================
# This script validates the health of the Elastic Stack infrastructure
# and provides comprehensive status information for troubleshooting
# =============================================================================

param(
    [string]$Environment = "staging",
    [string]$Region = "us-west-2",
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
    Info    = "Cyan"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Test-AWSCommand {
    try {
        aws --version | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Test-KubectlCommand {
    try {
        kubectl version --client | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Get-InfrastructureStatus {
    param(
        [string]$ClusterName,
        [string]$Region
    )
    
    Write-ColorOutput "🔍 Checking EKS Cluster Status..." "Info"
    
    try {
        $clusterInfo = aws eks describe-cluster --cluster-name $ClusterName --region $Region --query "cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}" --output json | ConvertFrom-Json
        
        Write-ColorOutput "✅ Cluster: $($clusterInfo.Name)" "Success"
        Write-ColorOutput "   Status: $($clusterInfo.Status)" "Success"
        Write-ColorOutput "   Version: $($clusterInfo.Version)" "Success"
        Write-ColorOutput "   Endpoint: $($clusterInfo.Endpoint)" "Success"
        
        return $clusterInfo
    }
    catch {
        Write-ColorOutput "❌ Failed to get cluster information: $_" "Error"
        return $null
    }
}

function Get-NodeGroupStatus {
    param(
        [string]$ClusterName,
        [string]$Region
    )
    
    Write-ColorOutput "🔍 Checking Node Group Status..." "Info"
    
    try {
        $nodegroups = aws eks list-nodegroups --cluster-name $ClusterName --region $Region --query "nodegroups" --output json | ConvertFrom-Json
        
        foreach ($ng in $nodegroups) {
            $ngInfo = aws eks describe-nodegroup --cluster-name $ClusterName --nodegroup-name $ng --region $Region --query "nodegroup.{Name:nodegroupName,Status:status,InstanceTypes:instanceTypes,ScalingConfig:scalingConfig}" --output json | ConvertFrom-Json
            
            $statusColor = if ($ngInfo.Status -eq "ACTIVE") { "Success" } else { "Warning" }
            Write-ColorOutput "✅ Node Group: $($ngInfo.Name)" $statusColor
            Write-ColorOutput "   Status: $($ngInfo.Status)" $statusColor
            Write-ColorOutput "   Instance Types: $($ngInfo.InstanceTypes -join ', ')" $statusColor
            Write-ColorOutput "   Desired Size: $($ngInfo.ScalingConfig.desiredSize)" $statusColor
        }
        
        return $nodegroups
    }
    catch {
        Write-ColorOutput "❌ Failed to get node group information: $_" "Error"
        return $null
    }
}

function Get-SecurityGroupStatus {
    param(
        [string]$ClusterName,
        [string]$Region
    )
    
    Write-ColorOutput "🔍 Checking Security Groups..." "Info"
    
    try {
        # Get cluster security group
        $clusterSG = aws eks describe-cluster --cluster-name $ClusterName --region $Region --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text
        
        if ($clusterSG) {
            $sgInfo = aws ec2 describe-security-groups --group-ids $clusterSG --region $Region --query "SecurityGroups[0].{GroupId:GroupId,GroupName:GroupName,Description:Description}" --output json | ConvertFrom-Json
            
            Write-ColorOutput "✅ Cluster Security Group: $($sgInfo.GroupName)" "Success"
            Write-ColorOutput "   ID: $($sgInfo.GroupId)" "Success"
            Write-ColorOutput "   Description: $($sgInfo.Description)" "Success"
        }
        
        # Get node security groups
        $nodegroups = aws eks list-nodegroups --cluster-name $ClusterName --region $Region --query "nodegroups" --output json | ConvertFrom-Json
        
        foreach ($ng in $nodegroups) {
            $ngInfo = aws eks describe-nodegroup --cluster-name $ClusterName --nodegroup-name $ng --region $Region --query "nodegroup.resources.remoteAccessSecurityGroup" --output text
            
            if ($ngInfo -and $ngInfo -ne "None") {
                $sgInfo = aws ec2 describe-security-groups --group-ids $ngInfo --region $Region --query "SecurityGroups[0].{GroupId:GroupId,GroupName:GroupName,Description:Description}" --output json | ConvertFrom-Json
                
                Write-ColorOutput "✅ Node Security Group: $($sgInfo.GroupName)" "Success"
                Write-ColorOutput "   ID: $($sgInfo.GroupId)" "Success"
                Write-ColorOutput "   Description: $($sgInfo.Description)" "Success"
            }
        }
    }
    catch {
        Write-ColorOutput "❌ Failed to get security group information: $_" "Error"
    }
}

function Get-IAMRoleStatus {
    param(
        [string]$ClusterName
    )
    
    Write-ColorOutput "🔍 Checking IAM Roles..." "Info"
    
    try {
        $clusterRole = aws eks describe-cluster --cluster-name $ClusterName --region $Region --query "cluster.roleArn" --output text
        $roleName = ($clusterRole -split "/")[-1]
        
        $attachedPolicies = aws iam list-attached-role-policies --role-name $roleName --query "AttachedPolicies[].PolicyName" --output json | ConvertFrom-Json
        
        Write-ColorOutput "✅ Cluster IAM Role: $roleName" "Success"
        foreach ($policy in $attachedPolicies) {
            Write-ColorOutput "   Policy: $policy" "Success"
        }
        
        # Check node role
        $nodegroups = aws eks list-nodegroups --cluster-name $ClusterName --region $Region --query "nodegroups" --output json | ConvertFrom-Json
        
        foreach ($ng in $nodegroups) {
            $ngInfo = aws eks describe-nodegroup --cluster-name $ClusterName --nodegroup-name $ng --region $Region --query "nodegroup.nodeRole" --output text
            $nodeRoleName = ($ngInfo -split "/")[-1]
            
            $nodeAttachedPolicies = aws iam list-attached-role-policies --role-name $nodeRoleName --query "AttachedPolicies[].PolicyName" --output json | ConvertFrom-Json
            $inlinePolicies = aws iam list-role-policies --role-name $nodeRoleName --query "PolicyNames" --output json | ConvertFrom-Json
            
            Write-ColorOutput "✅ Node IAM Role: $nodeRoleName" "Success"
            foreach ($policy in $nodeAttachedPolicies) {
                Write-ColorOutput "   Attached Policy: $policy" "Success"
            }
            foreach ($policy in $inlinePolicies) {
                Write-ColorOutput "   Inline Policy: $policy" "Success"
            }
        }
    }
    catch {
        Write-ColorOutput "❌ Failed to get IAM role information: $_" "Error"
    }
}

function Test-KubernetesConnection {
    param(
        [string]$ClusterName,
        [string]$Region
    )
    
    Write-ColorOutput "🔍 Testing Kubernetes Connection..." "Info"
    
    try {
        # Update kubeconfig
        aws eks update-kubeconfig --region $Region --name $ClusterName | Out-Null
        
        # Test connection
        $nodes = kubectl get nodes --output json | ConvertFrom-Json
        
        Write-ColorOutput "✅ Kubernetes connection successful" "Success"
        Write-ColorOutput "   Total Nodes: $($nodes.items.Count)" "Success"
        
        foreach ($node in $nodes.items) {
            $status = $node.status.conditions | Where-Object { $_.type -eq "Ready" }
            $statusColor = if ($status.status -eq "True") { "Success" } else { "Warning" }
            Write-ColorOutput "   Node: $($node.metadata.name) - $($status.status)" $statusColor
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "❌ Failed to connect to Kubernetes: $_" "Error"
        return $false
    }
}

function Get-InfrastructureHealth {
    param(
        [string]$ClusterName,
        [string]$Region
    )
    
    Write-ColorOutput "🏥 Infrastructure Health Check" "Info"
    Write-ColorOutput "=================================" "Info"
    
    $health = @{
        Cluster        = $false
        NodeGroups     = $false
        SecurityGroups = $false
        IAMRoles       = $false
        Kubernetes     = $false
    }
    
    # Check cluster
    $clusterInfo = Get-InfrastructureStatus -ClusterName $ClusterName -Region $Region
    $health.Cluster = $clusterInfo.Status -eq "ACTIVE"
    
    # Check node groups
    $nodegroups = Get-NodeGroupStatus -ClusterName $ClusterName -Region $Region
    $health.NodeGroups = $nodegroups -ne $null
    
    # Check security groups
    Get-SecurityGroupStatus -ClusterName $ClusterName -Region $Region
    $health.SecurityGroups = $true
    
    # Check IAM roles
    Get-IAMRoleStatus -ClusterName $ClusterName
    $health.IAMRoles = $true
    
    # Check Kubernetes connection
    $health.Kubernetes = Test-KubernetesConnection -ClusterName $ClusterName -Region $Region
    
    # Summary
    Write-ColorOutput "=================================" "Info"
    Write-ColorOutput "🏥 Health Summary:" "Info"
    
    $overallHealth = $true
    foreach ($component in $health.Keys) {
        $status = if ($health[$component]) { "✅" } else { "❌" }
        $color = if ($health[$component]) { "Success" } else { "Error" }
        Write-ColorOutput "   $component`: $status" $color
        
        if (-not $health[$component]) {
            $overallHealth = $false
        }
    }
    
    Write-ColorOutput "=================================" "Info"
    if ($overallHealth) {
        Write-ColorOutput "🎉 All systems are healthy!" "Success"
    } else {
        Write-ColorOutput "⚠️  Some issues detected. Check the output above." "Warning"
    }
    
    return $overallHealth
}

# Main execution
Write-ColorOutput "🚀 Advanced Elastic Terraform Infrastructure Validation" "Info"
Write-ColorOutput "=======================================================" "Info"

# Check prerequisites
if (-not (Test-AWSCommand)) {
    Write-ColorOutput "❌ AWS CLI not found. Please install AWS CLI and configure credentials." "Error"
    exit 1
}

if (-not (Test-KubectlCommand)) {
    Write-ColorOutput "⚠️  kubectl not found. Kubernetes connection tests will be skipped." "Warning"
}

# Set cluster name
$clusterName = "advanced-elastic-$Environment-aws"

Write-ColorOutput "🔧 Environment: $Environment" "Info"
Write-ColorOutput "🌍 Region: $Region" "Info"
Write-ColorOutput "🏗️  Cluster: $clusterName" "Info"
Write-ColorOutput ""

# Run health check
$isHealthy = Get-InfrastructureHealth -ClusterName $clusterName -Region $Region

# Exit with appropriate code
if ($isHealthy) {
    exit 0
} else {
    exit 1
}
