# EKS Status Check Script
# Use this script to monitor the progress of your EKS infrastructure

Write-Host "🔍 EKS Infrastructure Status Check" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check EKS Cluster Status
Write-Host "📊 EKS Cluster Status:" -ForegroundColor Yellow
$clusterStatus = aws eks describe-cluster --name advanced-elastic-staging-aws --query "cluster.status" --output text 2>$null
if ($clusterStatus) {
    Write-Host "   Cluster: advanced-elastic-staging-aws" -ForegroundColor Green
    Write-Host "   Status: $clusterStatus" -ForegroundColor Green
} else {
    Write-Host "   ❌ Unable to get cluster status" -ForegroundColor Red
}

Write-Host ""

# Check Nodegroup Status
Write-Host "🖥️  Nodegroup Status:" -ForegroundColor Yellow
$nodegroups = aws eks list-nodegroups --cluster-name advanced-elastic-staging-aws --query "nodegroups" --output text 2>$null

if ($nodegroups) {
    $nodegroups = $nodegroups -split "`t"
    foreach ($ng in $nodegroups) {
        if ($ng -and $ng -ne "nodegroups") {
            $status = aws eks describe-nodegroup --cluster-name advanced-elastic-staging-aws --nodegroup-name $ng --query "nodegroup.status" --output text 2>$null
            if ($status) {
                $color = if ($status -eq "ACTIVE") { "Green" } elseif ($status -eq "CREATING") { "Yellow" } else { "Red" }
                Write-Host "   $ng : $status" -ForegroundColor $color
            }
        }
    }
} else {
    Write-Host "   ❌ No nodegroups found" -ForegroundColor Red
}

Write-Host ""

# Check EC2 Instances
Write-Host "🖥️  EC2 Instance Status:" -ForegroundColor Yellow
$instances = aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/advanced-elastic-staging-aws,Values=owned" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId,State.Name]" --output table 2>$null

if ($instances) {
    Write-Host "   Running instances found:" -ForegroundColor Green
    $instanceCount = ($instances -split "`n" | Where-Object { $_ -match "i-" }).Count
    Write-Host "   Total: $instanceCount instances" -ForegroundColor Green
} else {
    Write-Host "   ❌ No running instances found" -ForegroundColor Red
}

Write-Host ""

# Check Security Group Rules
Write-Host "🔒 Security Group Status:" -ForegroundColor Yellow
$workerSG = "sg-09f6f6537e401c013"
$clusterSG = "sg-06bd0be5b4dfe713d"

$sgRules = aws ec2 describe-security-groups --group-ids $workerSG --query "SecurityGroups[0].IpPermissions[?FromPort==1025 && ToPort==65535]" --output text 2>$null

if ($sgRules) {
    Write-Host "   ✅ NodePort rule (1025-65535) found in worker security group" -ForegroundColor Green
} else {
    Write-Host "   ❌ NodePort rule (1025-65535) missing from worker security group" -ForegroundColor Red
}

Write-Host ""

# Check IAM Role
Write-Host "🔑 IAM Role Status:" -ForegroundColor Yellow
$inlinePolicies = aws iam list-role-policies --role-name advanced-elastic-staging-aws-nodes-role --query "PolicyNames" --output text 2>$null

if ($inlinePolicies -match "eks-describe-cluster") {
    Write-Host "   ✅ eks-describe-cluster inline policy found" -ForegroundColor Green
} else {
    Write-Host "   ❌ eks-describe-cluster inline policy missing" -ForegroundColor Red
}

Write-Host ""

# Summary
Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "===========" -ForegroundColor Cyan

if ($clusterStatus -eq "ACTIVE") {
    Write-Host "   ✅ EKS Cluster is ACTIVE" -ForegroundColor Green
} else {
    Write-Host "   ❌ EKS Cluster is not ACTIVE" -ForegroundColor Red
}

$activeNodegroups = 0
$creatingNodegroups = 0
if ($nodegroups) {
    foreach ($ng in $nodegroups) {
        if ($ng -and $ng -ne "nodegroups") {
            $status = aws eks describe-nodegroup --cluster-name advanced-elastic-staging-aws --nodegroup-name $ng --query "nodegroup.status" --output text 2>$null
            if ($status -eq "ACTIVE") { $activeNodegroups++ }
            if ($status -eq "CREATING") { $creatingNodegroups++ }
        }
    }
}

Write-Host "   📊 Nodegroups: $activeNodegroups ACTIVE, $creatingNodegroups CREATING" -ForegroundColor $(if ($activeNodegroups -gt 0) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "🔄 Run this script again to monitor progress!" -ForegroundColor Cyan
Write-Host "⏰ Expected completion: 10-15 minutes after security group fix" -ForegroundColor Yellow



