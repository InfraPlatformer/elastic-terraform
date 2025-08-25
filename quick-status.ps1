# Quick Infrastructure Status Check
# Run this for immediate status without continuous monitoring

Write-Host "🔍 QUICK INFRASTRUCTURE STATUS CHECK" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# Check AWS Connection
Write-Host "`n🔍 Checking AWS Connection..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --query "Account" --output text 2>$null
    if ($identity) {
        Write-Host "✅ AWS Connection: Active (Account: $identity)" -ForegroundColor Green
    } else {
        Write-Host "❌ AWS Connection: Failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ AWS Connection: Failed" -ForegroundColor Red
}

# Check EKS Cluster
Write-Host "`n🔍 Checking EKS Cluster..." -ForegroundColor Yellow
try {
    $cluster = aws eks describe-cluster --name "advanced-elastic-staging-aws" --region "us-west-2" --query "cluster.{Name:name,Status:status,Version:version}" --output json 2>$null | ConvertFrom-Json
    
    if ($cluster) {
        $statusColor = if ($cluster.Status -eq "ACTIVE") { "Green" } else { "Yellow" }
        Write-Host "✅ EKS Cluster: $($cluster.Name)" -ForegroundColor Green
        Write-Host "   Status: $($cluster.Status)" -ForegroundColor $statusColor
        Write-Host "   Version: $($cluster.Version)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ EKS Cluster: Not found or inaccessible" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ EKS Cluster Check Failed" -ForegroundColor Red
}

# Check Node Groups
Write-Host "`n🔍 Checking Node Groups..." -ForegroundColor Yellow
try {
    $nodegroups = aws eks list-nodegroups --cluster-name "advanced-elastic-staging-aws" --region "us-west-2" --query "nodegroups" --output json 2>$null | ConvertFrom-Json
    
    if ($nodegroups -and $nodegroups.Count -gt 0) {
        Write-Host "✅ Node Groups: $($nodegroups.Count) found" -ForegroundColor Green
        foreach ($ng in $nodegroups) {
            Write-Host "   - $ng" -ForegroundColor Cyan
        }
    } else {
        Write-Host "⚠️  No node groups found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Node Groups Check Failed" -ForegroundColor Red
}

# Check Security Groups
Write-Host "`n🔍 Checking Security Groups..." -ForegroundColor Yellow
try {
    $vpcId = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=staging-elastic-vpc" --query "Vpcs[0].VpcId" --output text --region "us-west-2" 2>$null
    
    if ($vpcId -and $vpcId -ne "None") {
        $sgs = aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" "Name=tag:Project,Values=advanced-elastic" --query "SecurityGroups[].GroupName" --output json --region "us-west-2" 2>$null | ConvertFrom-Json
        
        if ($sgs) {
            Write-Host "✅ Security Groups: $($sgs.Count) found" -ForegroundColor Green
            foreach ($sg in $sgs) {
                Write-Host "   - $sg" -ForegroundColor Cyan
            }
        } else {
            Write-Host "⚠️  No security groups found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ VPC not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Security Groups Check Failed" -ForegroundColor Red
}

# Check IAM Roles
Write-Host "`n🔍 Checking IAM Roles..." -ForegroundColor Yellow
try {
    $clusterRole = aws iam get-role --role-name "advanced-elastic-staging-aws-cluster-role" --query "Role.RoleName" --output text --region "us-west-2" 2>$null
    $nodesRole = aws iam get-role --role-name "advanced-elastic-staging-aws-nodes-role" --query "Role.RoleName" --output text --region "us-west-2" 2>$null
    
    if ($clusterRole) {
        Write-Host "✅ Cluster IAM Role: $clusterRole" -ForegroundColor Green
    } else {
        Write-Host "❌ Cluster IAM Role: Not found" -ForegroundColor Red
    }
    
    if ($nodesRole) {
        Write-Host "✅ Nodes IAM Role: $nodesRole" -ForegroundColor Green
    } else {
        Write-Host "❌ Nodes IAM Role: Not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ IAM Roles Check Failed" -ForegroundColor Red
}

Write-Host "`n=====================================" -ForegroundColor Magenta
Write-Host "Quick status check completed!" -ForegroundColor Green
Write-Host "Run '.\monitor-infrastructure.ps1' for continuous monitoring" -ForegroundColor Cyan
