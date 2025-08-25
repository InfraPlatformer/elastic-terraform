# =============================================================================
# COMPREHENSIVE INFRASTRUCTURE MONITORING SCRIPT
# =============================================================================
# This script provides real-time monitoring of your Elastic Stack infrastructure
# including EKS cluster, networking, security groups, IAM roles, and applications

param(
    [string]$Region = "us-west-2",
    [string]$ClusterName = "advanced-elastic-staging-aws",
    [int]$RefreshInterval = 30,
    [switch]$Continuous = $true
)

# Colors for output
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Get-Timestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

function Test-AWSConnection {
    try {
        $identity = aws sts get-caller-identity --query "Account" --output text 2>$null
        if ($identity) {
            Write-ColorOutput "✅ AWS Connection: Active (Account: $identity)" "Success"
            return $true
        } else {
            Write-ColorOutput "❌ AWS Connection: Failed" "Error"
            return $false
        }
    } catch {
        Write-ColorOutput "❌ AWS Connection: Failed - $($_.Exception.Message)" "Error"
        return $false
    }
}

function Get-EKSClusterStatus {
    try {
        $cluster = aws eks describe-cluster --name $ClusterName --region $Region --query "cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}" --output json 2>$null | ConvertFrom-Json
        
        if ($cluster) {
            $statusColor = if ($cluster.Status -eq "ACTIVE") { "Success" } else { "Warning" }
            Write-ColorOutput "🔍 EKS Cluster Status:" "Header"
            Write-ColorOutput "   Name: $($cluster.Name)" "Info"
            Write-ColorOutput "   Status: $($cluster.Status)" $statusColor
            Write-ColorOutput "   Version: $($cluster.Version)" "Info"
            Write-ColorOutput "   Endpoint: $($cluster.Endpoint)" "Info"
            return $cluster
        } else {
            Write-ColorOutput "❌ EKS Cluster: Not found or inaccessible" "Error"
            return $null
        }
    } catch {
        Write-ColorOutput "❌ EKS Cluster Status Check Failed: $($_.Exception.Message)" "Error"
        return $null
    }
}

function Get-NodeGroupStatus {
    try {
        $nodegroups = aws eks list-nodegroups --cluster-name $ClusterName --region $Region --query "nodegroups" --output json 2>$null | ConvertFrom-Json
        
        Write-ColorOutput "🔍 EKS Node Groups:" "Header"
        if ($nodegroups -and $nodegroups.Count -gt 0) {
            foreach ($ng in $nodegroups) {
                $ngDetails = aws eks describe-nodegroup --cluster-name $ClusterName --nodegroup-name $ng --region $Region --query "nodegroup.{Name:nodegroupName,Status:status,InstanceTypes:instanceTypes,DesiredCapacity:scalingConfig.desiredSize,MaxCapacity:scalingConfig.maxSize}" --output json 2>$null | ConvertFrom-Json
                
                if ($ngDetails) {
                    $statusColor = if ($ngDetails.Status -eq "ACTIVE") { "Success" } else { "Warning" }
                    Write-ColorOutput "   Node Group: $($ngDetails.Name)" "Info"
                    Write-ColorOutput "   Status: $($ngDetails.Status)" $statusColor
                    Write-ColorOutput "   Instance Types: $($ngDetails.InstanceTypes -join ', ')" "Info"
                    Write-ColorOutput "   Capacity: $($ngDetails.DesiredCapacity)/$($ngDetails.MaxCapacity)" "Info"
                }
            }
        } else {
            Write-ColorOutput "   ⚠️  No node groups found" "Warning"
        }
    } catch {
        Write-ColorOutput "❌ Node Group Status Check Failed: $($_.Exception.Message)" "Error"
    }
}

function Get-SecurityGroupStatus {
    try {
        Write-ColorOutput "🔍 Security Groups Status:" "Header"
        
        # Get VPC ID first
        $vpcId = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=staging-elastic-vpc" --query "Vpcs[0].VpcId" --output text --region $Region 2>$null
        
        if ($vpcId -and $vpcId -ne "None") {
            $sgs = aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" "Name=tag:Project,Values=advanced-elastic" --query "SecurityGroups[].{Name:GroupName,ID:GroupId,Description:Description,Rules:length(IpPermissions)}" --output json --region $Region 2>$null | ConvertFrom-Json
            
            if ($sgs) {
                foreach ($sg in $sgs) {
                    Write-ColorOutput "   $($sg.Name) ($($sg.ID))" "Info"
                    Write-ColorOutput "     Description: $($sg.Description)" "Info"
                    Write-ColorOutput "     Ingress Rules: $($sg.Rules)" "Info"
                }
            } else {
                Write-ColorOutput "   ⚠️  No security groups found" "Warning"
            }
        } else {
            Write-ColorOutput "   ❌ VPC not found" "Error"
        }
    } catch {
        Write-ColorOutput "❌ Security Group Status Check Failed: $($_.Exception.Message)" "Error"
    }
}

function Get-NetworkingStatus {
    try {
        Write-ColorOutput "🔍 Networking Status:" "Header"
        
        # VPC Status
        $vpc = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=staging-elastic-vpc" --query "Vpcs[0].{ID:VpcId,CIDR:CidrBlock,State:State}" --output json --region $Region 2>$null | ConvertFrom-Json
        
        if ($vpc -and $vpc.ID -ne "None") {
            Write-ColorOutput "   VPC: $($vpc.ID) ($($vpc.CIDR)) - $($vpc.State)" "Info"
            
            # Subnets
            $subnets = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$($vpc.ID)" --query "Subnets[].{ID:SubnetId,CIDR:CidrBlock,AvailabilityZone:AvailabilityZone,State:State}" --output json --region $Region 2>$null | ConvertFrom-Json
            
            if ($subnets) {
                Write-ColorOutput "   Subnets:" "Info"
                foreach ($subnet in $subnets) {
                    $stateColor = if ($subnet.State -eq "available") { "Success" } else { "Warning" }
                    Write-ColorOutput "     $($subnet.ID) ($($subnet.CIDR)) - $($subnet.AvailabilityZone) - $($subnet.State)" $stateColor
                }
            }
            
            # NAT Gateways
            $natGateways = aws ec2 describe-nat-gateways --filters "Name=vpc-id,Values=$($vpc.ID)" --query "NatGateways[].{ID:NatGatewayId,State:State,Subnet:SubnetId}" --output json --region $Region 2>$null | ConvertFrom-Json
            
            if ($natGateways) {
                Write-ColorOutput "   NAT Gateways:" "Info"
                foreach ($nat in $natGateways) {
                    $stateColor = if ($nat.State -eq "available") { "Success" } else { "Warning" }
                    Write-ColorOutput "     $($nat.ID) - $($nat.State) - Subnet: $($nat.Subnet)" $stateColor
                }
            }
        } else {
            Write-ColorOutput "   ❌ VPC not found" "Error"
        }
    } catch {
        Write-ColorOutput "❌ Networking Status Check Failed: $($_.Exception.Message)" "Error"
    }
}

function Get-IAMRoleStatus {
    try {
        Write-ColorOutput "🔍 IAM Roles Status:" "Header"
        
        $clusterRole = aws iam get-role --role-name "${ClusterName}-cluster-role" --query "Role.{Name:RoleName,Arn:Arn,CreateDate:CreateDate}" --output json --region $Region 2>$null | ConvertFrom-Json
        
        if ($clusterRole) {
            Write-ColorOutput "   Cluster Role: $($clusterRole.Name)" "Info"
            Write-ColorOutput "     ARN: $($clusterRole.Arn)" "Info"
            Write-ColorOutput "     Created: $($clusterRole.CreateDate)" "Info"
            
            # Check attached policies
            $policies = aws iam list-attached-role-policies --role-name $clusterRole.Name --query "AttachedPolicies[].PolicyName" --output json --region $Region 2>$null | ConvertFrom-Json
            if ($policies) {
                Write-ColorOutput "     Policies: $($policies -join ', ')" "Info"
            }
        } else {
            Write-ColorOutput "   ❌ Cluster IAM role not found" "Error"
        }
        
        $nodesRole = aws iam get-role --role-name "${ClusterName}-nodes-role" --query "Role.{Name:RoleName,Arn:Arn,CreateDate:CreateDate}" --output json --region $Region 2>$null | ConvertFrom-Json
        
        if ($nodesRole) {
            Write-ColorOutput "   Nodes Role: $($nodesRole.Name)" "Info"
            Write-ColorOutput "     ARN: $($nodesRole.Arn)" "Info"
            Write-ColorOutput "     Created: $($nodesRole.CreateDate)" "Info"
            
            # Check attached policies
            $policies = aws iam list-attached-role-policies --role-name $nodesRole.Name --query "AttachedPolicies[].PolicyName" --output json --region $Region 2>$null | ConvertFrom-Json
            if ($policies) {
                Write-ColorOutput "     Policies: $($policies -join ', ')" "Info"
            }
        } else {
            Write-ColorOutput "   ❌ Nodes IAM role not found" "Error"
        }
    } catch {
        Write-ColorOutput "❌ IAM Role Status Check Failed: $($_.Exception.Message)" "Error"
    }
}

function Test-KubernetesConnection {
    try {
        Write-ColorOutput "🔍 Kubernetes Connection Test:" "Header"
        
        # Check if kubectl is available
        $kubectlVersion = kubectl version --client --output json 2>$null | ConvertFrom-Json
        
        if ($kubectlVersion) {
            Write-ColorOutput "   kubectl: Available (Client: $($kubectlVersion.clientVersion.gitVersion))" "Success"
            
            # Try to get cluster info
            $clusterInfo = kubectl cluster-info 2>$null
            if ($clusterInfo) {
                Write-ColorOutput "   Cluster Connection: ✅ Active" "Success"
                
                # Check namespaces
                $namespaces = kubectl get namespaces --output json 2>$null | ConvertFrom-Json
                if ($namespaces) {
                    Write-ColorOutput "   Namespaces:" "Info"
                    foreach ($ns in $namespaces.items) {
                        $statusColor = if ($ns.status.phase -eq "Active") { "Success" } else { "Warning" }
                        Write-ColorOutput "     $($ns.metadata.name) - $($ns.status.phase)" $statusColor
                    }
                }
            } else {
                Write-ColorOutput "   Cluster Connection: ❌ Failed" "Error"
            }
        } else {
            Write-ColorOutput "   kubectl: ❌ Not available" "Error"
        }
    } catch {
        Write-ColorOutput "❌ Kubernetes Connection Test Failed: $($_.Exception.Message)" "Error"
    }
}

function Get-ApplicationStatus {
    try {
        Write-ColorOutput "🔍 Application Status:" "Header"
        
        # Check if kubectl is working
        $clusterInfo = kubectl cluster-info 2>$null
        if (-not $clusterInfo) {
            Write-ColorOutput "   ⚠️  Cannot check applications - kubectl not connected" "Warning"
            return
        }
        
        # Check Kibana
        $kibanaPods = kubectl get pods -n kibana --output json 2>$null | ConvertFrom-Json
        if ($kibanaPods) {
            Write-ColorOutput "   Kibana:" "Info"
            foreach ($pod in $kibanaPods.items) {
                $statusColor = if ($pod.status.phase -eq "Running") { "Success" } else { "Warning" }
                Write-ColorOutput "     $($pod.metadata.name) - $($pod.status.phase)" $statusColor
            }
        } else {
            Write-ColorOutput "   Kibana: ⚠️  No pods found" "Warning"
        }
        
        # Check Monitoring
        $monitoringPods = kubectl get pods -n monitoring --output json 2>$null | ConvertFrom-Json
        if ($monitoringPods) {
            Write-ColorOutput "   Monitoring:" "Info"
            foreach ($pod in $monitoringPods.items) {
                $statusColor = if ($pod.status.phase -eq "Running") { "Success" } else { "Warning" }
                Write-ColorOutput "     $($pod.metadata.name) - $($pod.status.phase)" $statusColor
            }
        } else {
            Write-ColorOutput "   Monitoring: ⚠️  No pods found" "Warning"
        }
        
        # Check Services
        $services = kubectl get services --all-namespaces --output json 2>$null | ConvertFrom-Json
        if ($services) {
            Write-ColorOutput "   Load Balancer Services:" "Info"
            foreach ($svc in $services.items) {
                if ($svc.spec.type -eq "LoadBalancer") {
                    $externalIP = if ($svc.status.loadBalancer.ingress) { $svc.status.loadBalancer.ingress[0].hostname } else { "Pending" }
                    Write-ColorOutput "     $($svc.metadata.namespace)/$($svc.metadata.name) - $externalIP" "Info"
                }
            }
        }
    } catch {
        Write-ColorOutput "❌ Application Status Check Failed: $($_.Exception.Message)" "Error"
    }
}

function Get-InfrastructureHealth {
    Write-ColorOutput "🏥 INFRASTRUCTURE HEALTH SUMMARY" "Header"
    Write-ColorOutput "===============================================" "Header"
    
    $health = @{
        AWSConnection = Test-AWSConnection
        EKSCluster = $false
        NodeGroups = $false
        SecurityGroups = $false
        Networking = $false
        IAMRoles = $false
        Kubernetes = $false
        Applications = $false
    }
    
    # Check EKS Cluster
    $cluster = Get-EKSClusterStatus
    $health.EKSCluster = $cluster -and $cluster.Status -eq "ACTIVE"
    
    # Check Node Groups
    $nodegroups = aws eks list-nodegroups --cluster-name $ClusterName --region $Region --query "nodegroups" --output json 2>$null | ConvertFrom-Json
    $health.NodeGroups = $nodegroups -and $nodegroups.Count -gt 0
    
    # Check Security Groups
    $vpcId = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=staging-elastic-vpc" --query "Vpcs[0].VpcId" --output text --region $Region 2>$null
    $sgs = aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" "Name=tag:Project,Values=advanced-elastic" --query "SecurityGroups" --output json --region $Region 2>$null | ConvertFrom-Json
    $health.SecurityGroups = $sgs -and $sgs.Count -gt 0
    
    # Check Networking
    $vpc = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=staging-elastic-vpc" --query "Vpcs[0].VpcId" --output text --region $Region 2>$null
    $health.Networking = $vpc -and $vpc -ne "None"
    
    # Check IAM Roles
    $clusterRole = aws iam get-role --role-name "${ClusterName}-cluster-role" --query "Role.RoleName" --output text --region $Region 2>$null
    $nodesRole = aws iam get-role --role-name "${ClusterName}-nodes-role" --query "Role.RoleName" --output text --region $Region 2>$null
    $health.IAMRoles = $clusterRole -and $nodesRole
    
    # Check Kubernetes
    $kubectlVersion = kubectl version --client --output json 2>$null | ConvertFrom-Json
    $health.Kubernetes = $kubectlVersion -ne $null
    
    # Check Applications
    $clusterInfo = kubectl cluster-info 2>$null
    if ($clusterInfo) {
        $kibanaPods = kubectl get pods -n kibana --output json 2>$null | ConvertFrom-Json
        $monitoringPods = kubectl get pods -n monitoring --output json 2>$null | ConvertFrom-Json
        $health.Applications = ($kibanaPods -and $kibanaPods.items.Count -gt 0) -or ($monitoringPods -and $monitoringPods.items.Count -gt 0)
    }
    
    # Display Health Summary
    Write-ColorOutput "`n📊 HEALTH STATUS:" "Header"
    foreach ($component in $health.Keys) {
        $status = if ($health[$component]) { "✅ HEALTHY" } else { "❌ UNHEALTHY" }
        $color = if ($health[$component]) { "Success" } else { "Error" }
        Write-ColorOutput "   $component`: $status" $color
    }
    
    $overallHealth = ($health.Values | Where-Object { $_ -eq $true }).Count / $health.Count * 100
    Write-ColorOutput "`n🏆 OVERALL HEALTH: $([math]::Round($overallHealth, 1))%" $(if ($overallHealth -ge 80) { "Success" } elseif ($overallHealth -ge 60) { "Warning" } else { "Error" })
    
    return $health
}

function Show-MonitoringDashboard {
    Clear-Host
    Write-ColorOutput "🚀 ELASTIC STACK INFRASTRUCTURE MONITORING DASHBOARD" "Header"
    Write-ColorOutput "================================================================" "Header"
    Write-ColorOutput "Timestamp: $(Get-Timestamp)" "Info"
    Write-ColorOutput "Region: $Region" "Info"
    Write-ColorOutput "Cluster: $ClusterName" "Info"
    Write-ColorOutput "Refresh Interval: $RefreshInterval seconds" "Info"
    Write-ColorOutput "================================================================" "Header"
    
    # Run all monitoring functions
    Get-InfrastructureHealth
    
    Write-ColorOutput "`n🔍 DETAILED STATUS:" "Header"
    Write-ColorOutput "================================================================" "Header"
    
    Get-EKSClusterStatus
    Get-NodeGroupStatus
    Get-SecurityGroupStatus
    Get-NetworkingStatus
    Get-IAMRoleStatus
    Test-KubernetesConnection
    Get-ApplicationStatus
    
    Write-ColorOutput "`n================================================================" "Header"
    Write-ColorOutput "Press Ctrl+C to stop monitoring" "Info"
    Write-ColorOutput "Next refresh in $RefreshInterval seconds..." "Info"
}

# Main monitoring loop
function Start-Monitoring {
    Write-ColorOutput "🚀 Starting Infrastructure Monitoring..." "Header"
    Write-ColorOutput "Press Ctrl+C to stop" "Info"
    
    if ($Continuous) {
        while ($true) {
            try {
                Show-MonitoringDashboard
                Start-Sleep -Seconds $RefreshInterval
            } catch {
                Write-ColorOutput "❌ Monitoring Error: $($_.Exception.Message)" "Error"
                Start-Sleep -Seconds 10
            }
        }
    } else {
        Show-MonitoringDashboard
    }
}

# Script execution
if ($MyInvocation.InvocationName -ne ".") {
    Start-Monitoring
}
