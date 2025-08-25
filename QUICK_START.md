# 🚀 **Quick Start Guide**
## **Get Your Elasticsearch Infrastructure Running in 15 Minutes**

---

## ⚡ **Prerequisites (5 minutes)**

### **1. Install Required Tools**
```bash
# Install Terraform
# Windows: Download from https://www.terraform.io/downloads.html
# macOS: brew install terraform
# Linux: curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# Install AWS CLI
# Windows: Download from https://aws.amazon.com/cli/
# macOS: brew install awscli
# Linux: curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Install kubectl
# Windows: Download from https://kubernetes.io/docs/tasks/tools/
# macOS: brew install kubectl
# Linux: curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install Helm
# Windows: Download from https://helm.sh/docs/intro/install/
# macOS: brew install helm
# Linux: curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
```

### **2. Configure AWS Credentials**
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and Region
```

---

## 🚀 **Deploy Infrastructure (10 minutes)**

### **1. Clone Repository**
```bash
git clone https://github.com/yourusername/elastic-terraform.git
cd elastic-terraform
```

### **2. Deploy Development Environment**
```bash
# Navigate to development environment
cd environments/development

# Initialize Terraform
terraform init

# Deploy infrastructure (auto-approve for quick start)
terraform apply -auto-approve
```

### **3. Deploy Elasticsearch Stack**
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

---

## 🌐 **Access Your Stack (2 minutes)**

### **1. Get Cluster Access**
```bash
# Update kubectl config
aws eks update-kubeconfig --region us-east-1 --name elasticsearch-cluster-dev
```

### **2. Port Forward Kibana**
```bash
# Port forward Kibana service
kubectl port-forward -n elasticsearch svc/kibana-kibana 5601:5601
```

### **3. Access Kibana**
- **URL**: http://localhost:5601
- **Username**: `elastic`
- **Password**: Get from Kubernetes secret:
  ```bash
  kubectl get secrets -n elasticsearch elasticsearch-master-credentials -o jsonpath='{.data.elastic}' | base64 -d
  ```

---

## 🔧 **CI/CD Setup (Optional - 5 minutes)**

### **1. Configure GitHub Secrets**
- Go to your repository → Settings → Secrets and variables → Actions
- Add these secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`

### **2. Push to Trigger Pipeline**
```bash
git add .
git commit -m "Initial setup"
git push origin develop  # Triggers development deployment
```

---

## ✅ **Verification Checklist**

- [ ] **Infrastructure**: EKS cluster running
- [ ] **Elasticsearch**: Pods in Running state
- [ ] **Kibana**: Pods in Running state
- [ ] **Access**: Kibana accessible at localhost:5601
- [ ] **Authentication**: Can login with elastic user
- [ ] **CI/CD**: GitHub Actions pipeline running (optional)

---

## 🚨 **Troubleshooting Quick Fixes**

### **Issue: Terraform init fails**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Reinitialize
terraform init -reconfigure
```

### **Issue: Pods not starting**
```bash
# Check pod status
kubectl get pods -n elasticsearch

# Check events
kubectl get events -n elasticsearch --sort-by='.lastTimestamp'
```

### **Issue: Kibana not accessible**
```bash
# Check service
kubectl get svc -n elasticsearch

# Check port-forward
kubectl port-forward -n elasticsearch svc/kibana-kibana 5601:5601
```

---

## 📚 **Next Steps**

1. **Explore Kibana**: Create dashboards and visualizations
2. **Add Data**: Configure data sources and indices
3. **Set Up Monitoring**: Configure alerts and notifications
4. **Scale Up**: Add more nodes or resources
5. **Security**: Enable X-Pack security features

---

## 🆘 **Need Help?**

- 📖 **Full Documentation**: [README.md](README.md)
- 🔐 **CI/CD Setup**: [.github/SETUP_SECRETS.md](.github/SETUP_SECRETS.md)
- 🎯 **Presentation**: [PRESENTATION_TEMPLATE.md](PRESENTATION_TEMPLATE.md)
- 🐛 **Issues**: Create an issue in the repository

---

**🎉 You're all set! Your Elasticsearch infrastructure is running and ready for development.**
