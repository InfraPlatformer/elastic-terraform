# =============================================================================
# PRODUCTION ELASTIC STACK INFRASTRUCTURE ON AWS EKS
# =============================================================================

# AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
      Purpose     = "elastic-stack"
    }
  }
}

# Kubernetes Provider - Will be configured after EKS cluster is created
# provider "kubernetes" {
#   host                   = module.aws_eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.aws_eks.cluster_certificate_authority_data)
#   
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args = [
#       "eks",
#       "get-token",
#       "--cluster-name",
#       module.aws_eks.cluster_name,
#       "--region",
#       var.aws_region
#     ]
#   }
# }

# Helm Provider - Temporarily disabled due to syntax issues
# provider "helm" {
#   kubernetes {
#     host                   = module.aws_eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.aws_eks.cluster_certificate_authority_data)
#     
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args = [
#         "eks",
#         "get-token",
#         "--cluster-name",
#         module.aws_eks.cluster_name,
#         "--region",
#         var.aws_region
#       ]
#     }
#   }
# }

# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# EKS Cluster Auth
data "aws_eks_cluster_auth" "cluster" {
  name = module.aws_eks.cluster_name
}

# Locals for standardized configuration
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  # Standardized tags for all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    Purpose     = "elastic-stack"
    CreatedAt   = timestamp()
    Version     = "1.0.0"
  }

  # Environment-specific tags
  environment_tags = merge(local.common_tags, {
    CostCenter = var.environment == "production" ? "prod-elastic" : "dev-elastic"
    Backup     = var.environment == "production" ? "daily" : "weekly"
  })
}

# =============================================================================
# CORE INFRASTRUCTURE MODULES
# =============================================================================

# Networking Infrastructure
module "aws_networking" {
  source = "./modules/networking"

  vpc_cidr           = var.vpc_cidr
  environment        = var.environment
  availability_zones = local.availability_zones
  tags               = local.environment_tags
}

# EKS Cluster with Enhanced Security
module "aws_eks" {
  source = "./modules/eks"

  cluster_name              = var.cluster_name
  cluster_version           = var.cluster_version
  subnet_ids                = module.aws_networking.private_subnets
  cluster_security_group_id = module.aws_networking.eks_cluster_security_group_id
  nodes_security_group_id   = module.aws_networking.eks_nodes_security_group_id
  enable_public_access      = var.enable_public_access
  allowed_cidr_blocks       = var.allowed_cidr_blocks
  environment               = var.environment
  tags                      = local.environment_tags

  # Node groups configuration
  node_groups = {
    elasticsearch = {
      instance_types = ["t3.large"] # Increased from t3.medium to t3.large (8GB RAM)
      capacity_type  = "ON_DEMAND"
      min_size       = 3
      max_size       = 5
      desired_size   = 3
      disk_size      = 100 # Increased from 20GB to 100GB for Elasticsearch data
      labels = {
        role = "elasticsearch"
      }
      taints = [{
        key    = "dedicated"
        value  = "elasticsearch"
        effect = "NO_SCHEDULE"
      }]
    }
    monitoring = {
      instance_types = ["t3.medium"] # Increased from t3.small to t3.medium for monitoring
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      disk_size      = 50 # Increased from 10GB to 50GB for monitoring data
      labels = {
        role = "monitoring"
      }
      taints = []
    }
  }
}

# Enhanced Monitoring Stack - Will be enabled after Helm provider is configured
# module "monitoring" {
#   source = "./modules/monitoring"
#   
#   environment = var.environment
#   enable_alerting = true
#   enable_logging = true
#   enable_security_monitoring = true
#   storage_class = "gp2"
#   monitoring_namespace = "monitoring"
#   eks_cluster = module.aws_eks
#   
#   depends_on = [module.aws_eks]
# }

# Backup and Disaster Recovery - Will be enabled after Helm provider is configured
# module "backup" {
#   source = "./modules/backup"
#   
#   cluster_name  = var.cluster_name
#   environment   = var.environment
#   aws_region   = var.aws_region
#   tags         = local.environment_tags
#   eks_cluster  = module.aws_eks
#   
#   depends_on = [module.aws_eks]
# }

# Auto-scaling Configuration - Will be enabled after Helm provider is configured
# module "autoscaling" {
#   source = "./modules/autoscaling"
#   
#   cluster_name = var.cluster_name
#   aws_region  = var.aws_region
#   eks_cluster = module.aws_eks
#   
#   depends_on = [module.aws_eks]
# }

# =============================================================================
# APPLICATION DEPLOYMENTS
# =============================================================================



# Kibana Dashboard - Will be enabled after Helm provider is configured
# module "kibana" {
#   source = "./modules/kibana"
#   
#   environment = var.environment
#   cluster_name = var.cluster_name
#   kibana_replicas = 2
#   enable_security = true
#   tags = local.environment_tags
#   
#   depends_on = [module.aws_eks]
# }
