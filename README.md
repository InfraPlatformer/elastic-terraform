# 🚀 Advanced Elasticsearch & Terraform Infrastructure

**Enterprise-grade Elasticsearch monitoring stack deployed with Infrastructure as Code (IaC) and automated CI/CD pipelines.**

[![CI/CD Pipeline](https://github.com/yourusername/elastic-terraform/workflows/Terraform%20Infrastructure%20Pipeline/badge.svg)](https://github.com/yourusername/elastic-terraform/actions)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-blue.svg)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue.svg)](https://kubernetes.io/)
[![Elasticsearch](https://img.shields.io/badge/Elasticsearch-8.5+-green.svg)](https://www.elastic.co/)

## 🎯 **Project Overview**

This project provides a complete, production-ready Elasticsearch monitoring stack deployed on AWS EKS using Terraform and Helm. It includes automated CI/CD pipelines, multi-environment support, and enterprise-grade security features.

### **✨ Key Features**

- 🏗️ **Infrastructure as Code** - Complete AWS infrastructure defined in Terraform
- 🚀 **Automated CI/CD** - GitHub Actions pipeline with multi-environment deployment
- 🔒 **Enterprise Security** - X-Pack security, SSL/TLS, and RBAC
- 📊 **Monitoring Stack** - Elasticsearch, Kibana, and comprehensive monitoring
- 🌍 **Multi-Environment** - Development, Staging, and Production configurations
- 💰 **Cost Optimization** - Auto-scaling, spot instances, and resource management
- 🔄 **GitOps Ready** - ArgoCD integration for advanced deployment strategies

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Development   │  │     Staging     │  │ Production  │ │
│  │     Branch      │  │     Branch      │  │   Branch    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 GitHub Actions CI/CD                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Security  │  │   Validate  │  │   Deploy & Test    │ │
│  │    Scan     │  │  Terraform  │  │   Environments     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    AWS Infrastructure                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │     VPC     │  │   EKS       │  │   Elasticsearch     │ │
│  │  Networking │  │   Cluster   │  │   + Kibana Stack    │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 **Quick Start**

### **Prerequisites**

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configured
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28
- [Helm](https://helm.sh/docs/intro/install/) >= 3.12.0
- [GitHub Account](https://github.com/) with repository access

### **1. Clone Repository**

```bash
git clone https://github.com/yourusername/elastic-terraform.git
cd elastic-terraform
```

### **2. Configure AWS Credentials**

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and Region
```

### **3. Deploy Development Environment**

```bash
# Navigate to development environment
cd environments/development

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply infrastructure
terraform apply -auto-approve
```

### **4. Deploy Elasticsearch Stack**

```bash
# Add Elastic Helm repository
helm repo add elastic https://helm.elastic.co
helm repo update

# Deploy Elasticsearch
helm upgrade --install elasticsearch elastic/elasticsearch \
  --namespace elasticsearch \
  --create-namespace \
  -f ../../elasticsearch-values.yaml

# Deploy Kibana
helm upgrade --install kibana elastic/kibana \
  --namespace elasticsearch \
  -f ../../kibana-values.yaml
```

### **5. Access Your Stack**

```bash
# Port forward Kibana
kubectl port-forward -n elasticsearch svc/kibana-kibana 5601:5601

# Access Kibana at: http://localhost:5601
# Default credentials: elastic / (check kubectl get secrets)
```

## 🔧 **CI/CD Pipeline Setup**

### **1. Configure GitHub Secrets**

Follow the [Secrets Setup Guide](.github/SETUP_SECRETS.md) to configure:
- AWS credentials for each environment
- Environment protection rules
- Deployment permissions

### **2. Push to Trigger Pipeline**

```bash
git add .
git commit -m "Initial CI/CD setup"
git push origin develop  # Triggers development deployment
```

### **3. Monitor Pipeline**

- View runs in GitHub Actions tab
- Check deployment status in AWS Console
- Monitor Kubernetes resources with kubectl

## 🌍 **Environment Configurations**

### **Development Environment**
- **Purpose**: Local development and testing
- **Resources**: Minimal (t3.medium instances)
- **Auto-deploy**: ✅ On `develop` branch
- **Security**: Basic (disabled for development)

### **Staging Environment**
- **Purpose**: Pre-production testing
- **Resources**: Medium (t3.large instances)
- **Auto-deploy**: ✅ On `main` branch
- **Security**: Production-like with SSL

### **Production Environment**
- **Purpose**: Live production workloads
- **Resources**: High (m5.large/xlarge instances)
- **Auto-deploy**: ❌ Manual approval required
- **Security**: Enterprise-grade with full encryption

## 📁 **Project Structure**

```
elastic-terraform/
├── .github/                          # GitHub Actions CI/CD
│   ├── workflows/
│   │   └── terraform-deploy.yml     # Main CI/CD pipeline
│   └── SETUP_SECRETS.md             # Secrets configuration guide
├── environments/                     # Environment-specific configs
│   ├── development/
│   │   └── terraform.tfvars         # Dev environment variables
│   ├── staging/
│   │   └── terraform.tfvars         # Staging environment variables
│   └── production/
│       └── terraform.tfvars         # Production environment variables
├── modules/                          # Reusable Terraform modules
│   ├── eks/                         # EKS cluster module
│   ├── elasticsearch/               # Elasticsearch module
│   ├── kibana/                      # Kibana module
│   ├── monitoring/                  # Monitoring stack module
│   └── networking/                  # VPC and networking module
├── elasticsearch-values.yaml         # Elasticsearch Helm values
├── kibana-values.yaml               # Kibana Helm values
├── main.tf                          # Main Terraform configuration
├── variables.tf                     # Variable definitions
├── outputs.tf                       # Output values
└── README.md                        # This file
```

## 🔒 **Security Features**

- **X-Pack Security**: Authentication and authorization
- **SSL/TLS Encryption**: In-transit and at-rest encryption
- **RBAC**: Role-based access control
- **Network Policies**: Kubernetes network security
- **IAM Integration**: AWS IAM roles and policies
- **Secret Management**: Kubernetes secrets and AWS Secrets Manager

## 📊 **Monitoring & Observability**

- **Elasticsearch**: Centralized logging and search
- **Kibana**: Data visualization and management
- **Prometheus**: Metrics collection
- **Grafana**: Advanced dashboards
- **Alerting**: Automated notifications
- **Log Aggregation**: Centralized log management

## 💰 **Cost Optimization**

- **Auto-scaling**: Automatic resource scaling based on demand
- **Spot Instances**: Use of AWS spot instances for non-critical workloads
- **Resource Limits**: Proper CPU and memory limits
- **Storage Optimization**: Efficient EBS volume management
- **Monitoring**: Cost tracking and optimization recommendations

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Kibana Connection Issues**
   ```bash
   # Check Elasticsearch status
   kubectl get pods -n elasticsearch
   
   # Check Elasticsearch logs
   kubectl logs -n elasticsearch elasticsearch-master-0
   ```

2. **Terraform State Issues**
   ```bash
   # Reinitialize Terraform
   terraform init -reconfigure
   
   # Import existing resources
   terraform import aws_eks_cluster.main cluster-name
   ```

3. **CI/CD Pipeline Failures**
   - Check GitHub Actions logs
   - Verify AWS credentials
   - Check environment protection rules

### **Getting Help**

- 📖 [Documentation](docs/)
- 🐛 [Issues](https://github.com/yourusername/elastic-terraform/issues)
- 💬 [Discussions](https://github.com/yourusername/elastic-terraform/discussions)

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- [HashiCorp Terraform](https://www.terraform.io/) for infrastructure automation
- [Elastic](https://www.elastic.co/) for the Elasticsearch stack
- [AWS](https://aws.amazon.com/) for cloud infrastructure
- [Kubernetes](https://kubernetes.io/) for container orchestration

---

**⭐ Star this repository if you find it helpful!**

**🔗 Connect with us:**
- [GitHub](https://github.com/yourusername)
- [LinkedIn](https://linkedin.com/in/yourusername)
- [Twitter](https://twitter.com/yourusername)
