# 🚀 Advanced Elastic Terraform Infrastructure Deployment Guide

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Manual Deployment](#manual-deployment)
4. [Automated Deployment](#automated-deployment)
5. [Post-Deployment Setup](#post-deployment-setup)
6. [Troubleshooting](#troubleshooting)
7. [Cost Optimization](#cost-optimization)
8. [Security Considerations](#security-considerations)

## 🔧 Prerequisites

### Required Tools
- **Terraform** (v1.0+)
- **AWS CLI** (v2.0+)
- **kubectl** (v1.28+)
- **PowerShell** (Windows) or **Bash** (Linux/Mac)

### AWS Requirements
- **AWS Account** with appropriate permissions
- **IAM User/Role** with the following permissions:
  - EKS (Full Access)
  - EC2 (Full Access)
  - VPC (Full Access)
  - IAM (Limited - for EKS service roles)
  - S3 (Full Access to state bucket)
  - DynamoDB (Full Access to state lock table)

### Network Requirements
- **Internet Access** for downloading container images
- **Port 443** open for AWS API calls
- **Port 22** open for SSH access (if needed)

## ⚡ Quick Start

### Option 1: Automated Deployment (Recommended)
```powershell
# PowerShell (Windows)
.\deploy-infrastructure.ps1

# Or with custom environment
.\deploy-infrastructure.ps1 -Environment production -DryRun
```

```bash
# Batch (Windows)
deploy-infrastructure.bat

# Or with custom options
deploy-infrastructure.bat --environment production --dry-run
```

### Option 2: Manual Deployment
```bash
# 1. Initialize Terraform
terraform init

# 2. Create deployment plan
terraform plan -var-file="environments/development/terraform.tfvars" -out=tfplan

# 3. Apply the configuration
terraform apply tfplan
```

## 🛠️ Manual Deployment

### Step 1: Environment Preparation
```bash
# Navigate to project directory
cd advanced-elastic-terraform

# Verify configuration
terraform validate

# Check AWS credentials
aws sts get-caller-identity
```

### Step 2: Backend Configuration
```bash
# Initialize with S3 backend
terraform init

# Verify backend configuration
terraform show -json | jq '.values.backend'
```

### Step 3: Variable Configuration
```bash
# Review environment variables
cat environments/development/terraform.tfvars

# Customize if needed
# - Instance types
# - Node group sizes
# - Environment tags
```

### Step 4: Deployment Planning
```bash
# Create detailed plan
terraform plan -var-file="environments/development/terraform.tfvars" -out=tfplan

# Review the plan
terraform show tfplan
```

### Step 5: Infrastructure Deployment
```bash
# Apply the configuration
terraform apply tfplan

# Monitor progress
# This will take 15-30 minutes for full deployment
```

## 🤖 Automated Deployment

### PowerShell Script Features
- **Pre-deployment validation** of tools and AWS connection
- **Automatic Terraform initialization** and planning
- **Interactive confirmation** before deployment
- **Post-deployment verification** of cluster status
- **Color-coded output** for better readability
- **Error handling** with detailed feedback

### Batch Script Features
- **Cross-platform compatibility** (Windows)
- **Command-line options** for customization
- **Progress tracking** with timestamps
- **Automatic cleanup** of temporary files

### Script Options
```powershell
# PowerShell
.\deploy-infrastructure.ps1 -Environment production
.\deploy-infrastructure.ps1 -SkipValidation
.\deploy-infrastructure.ps1 -DryRun

# Batch
deploy-infrastructure.bat --environment production
deploy-infrastructure.bat --skip-validation
deploy-infrastructure.bat --dry-run
```

## 🎯 Post-Deployment Setup

### 1. Access the EKS Cluster
```bash
# Update kubectl configuration
aws eks update-kubeconfig --region us-west-2 --name advanced-elastic-development-aws

# Verify cluster access
kubectl get nodes
kubectl get namespaces
```

### 2. Access Kibana
```bash
# Port forward to Kibana
kubectl port-forward -n kibana svc/kibana-external 5601:5601

# Open browser: http://localhost:5601
# Default credentials: admin / (check terraform output)
```

### 3. Access Monitoring Stack
```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-operator-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-operator-kube-p-prometheus 9090:9090

# Alertmanager
kubectl port-forward -n monitoring svc/prometheus-operator-kube-p-alertmanager 9093:9093
```

### 4. Verify Elasticsearch
```bash
# Check Elasticsearch pods
kubectl get pods -n elasticsearch

# Check Elasticsearch health
kubectl exec -n elasticsearch deployment/elasticsearch -- curl -s http://localhost:9200/_cluster/health
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Terraform Init Fails
```bash
# Error: No valid credential sources found
aws configure
aws sts get-caller-identity

# Error: Backend configuration error
# Check backend.tf and S3 bucket permissions
```

#### 2. Plan Fails
```bash
# Error: Invalid configuration
terraform validate
terraform fmt

# Error: Variable not declared
# Check variables.tf and terraform.tfvars
```

#### 3. Apply Fails
```bash
# Error: IAM permissions
# Verify IAM user has required permissions

# Error: VPC limits
# Check AWS account VPC limits

# Error: EKS cluster creation timeout
# Wait and retry (AWS service issue)
```

#### 4. Cluster Access Issues
```bash
# kubectl connection refused
aws eks update-kubeconfig --region us-west-2 --name <cluster-name>

# Permission denied
# Check IAM roles and policies
```

### Debug Commands
```bash
# Terraform debugging
export TF_LOG=DEBUG
terraform plan

# AWS debugging
aws sts get-caller-identity
aws eks describe-cluster --name <cluster-name>

# Kubernetes debugging
kubectl get events --sort-by='.lastTimestamp'
kubectl describe pod <pod-name> -n <namespace>
```

## 💰 Cost Optimization

### Development Environment
- **Instance Types**: t3.medium (Elasticsearch), t3.small (Monitoring)
- **Node Groups**: Minimal sizing (1-2 nodes)
- **Auto Scaling**: Disabled for cost control
- **Spot Instances**: Not recommended for Elasticsearch

### Production Environment
- **Instance Types**: m5.large+ for Elasticsearch, m5.xlarge+ for monitoring
- **Node Groups**: 3+ nodes for high availability
- **Auto Scaling**: Enabled with appropriate limits
- **Reserved Instances**: Consider for predictable workloads

### Cost Monitoring
```bash
# AWS Cost Explorer
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost

# Resource tagging for cost allocation
terraform output project_info
```

## 🔒 Security Considerations

### Network Security
- **Private Subnets**: Elasticsearch nodes in private subnets
- **Security Groups**: Minimal required access
- **VPC Endpoints**: Private AWS service access
- **Network ACLs**: Additional network layer security

### Access Control
- **IAM Roles**: Least privilege principle
- **RBAC**: Kubernetes role-based access control
- **Secrets Management**: Kubernetes secrets for sensitive data
- **Audit Logging**: CloudTrail and Kubernetes audit logs

### Data Protection
- **Encryption at Rest**: EBS volume encryption
- **Encryption in Transit**: TLS for all communications
- **Backup Encryption**: S3 bucket encryption
- **Access Logging**: S3 and CloudTrail logging

## 📊 Monitoring and Maintenance

### Health Checks
```bash
# Daily health checks
kubectl get nodes
kubectl get pods --all-namespaces
kubectl top nodes
kubectl top pods --all-namespaces

# Elasticsearch health
kubectl exec -n elasticsearch deployment/elasticsearch -- curl -s http://localhost:9200/_cluster/health
```

### Backup Strategy
```bash
# S3 backup verification
aws s3 ls s3://elastic-terraform-state-2024-alamz/

# Terraform state backup
terraform state pull > terraform-state-backup.json
```

### Updates and Maintenance
```bash
# Terraform updates
terraform plan -var-file="environments/development/terraform.tfvars"

# Kubernetes updates
kubectl get nodes -o wide
kubectl drain <node-name> --ignore-daemonsets
```

## 🎉 Success Indicators

### Infrastructure Ready
- ✅ EKS cluster status: ACTIVE
- ✅ All node groups: ACTIVE
- ✅ All pods: Running
- ✅ Services: Available
- ✅ Ingress: Configured

### Applications Accessible
- ✅ Kibana: http://localhost:5601
- ✅ Grafana: http://localhost:3000
- ✅ Prometheus: http://localhost:9090
- ✅ Elasticsearch: Internal cluster access

### Monitoring Active
- ✅ Prometheus targets: UP
- ✅ Grafana dashboards: Loaded
- ✅ Alertmanager: Receiving alerts
- ✅ Log aggregation: Working

## 📞 Support and Resources

### Documentation
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Elasticsearch Documentation](https://www.elastic.co/guide/index.html)

### Community
- [Terraform Community](https://discuss.hashicorp.com/)
- [AWS Developer Forums](https://forums.aws.amazon.com/)
- [Elastic Community](https://discuss.elastic.co/)

### Getting Help
1. Check the troubleshooting section above
2. Review Terraform and AWS logs
3. Verify IAM permissions and network configuration
4. Check community forums for similar issues
5. Consider professional support for production environments

---

**Happy Deploying! 🚀**

*This guide covers the essential steps for deploying your Advanced Elastic Terraform infrastructure. For production deployments, always test in staging first and ensure proper backup and disaster recovery procedures are in place.*
