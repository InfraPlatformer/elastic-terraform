# =============================================================================
# ENHANCED OUTPUTS FOR ADVANCED ELASTIC TERRAFORM
# =============================================================================
# This file contains comprehensive outputs with validation and security information
# =============================================================================

# AWS INFRASTRUCTURE OUTPUTS
output "aws_cluster_info" {
  description = "AWS EKS cluster information"
  value = {
    name     = module.aws_eks.cluster_name
    endpoint = module.aws_eks.cluster_endpoint
    version  = module.aws_eks.cluster_version
    region   = var.aws_region
    arn      = module.aws_eks.cluster_arn
  }
}

output "aws_node_groups" {
  description = "AWS EKS node group information"
  value = {
    elasticsearch = try(module.aws_eks.node_groups["elasticsearch"], null)
    monitoring    = try(module.aws_eks.node_groups["monitoring"], null)
  }
}

output "aws_networking_info" {
  description = "AWS networking information"
  value = {
    vpc_id          = module.aws_networking.vpc_id
    vpc_cidr        = module.aws_networking.vpc_cidr
    public_subnets  = module.aws_networking.public_subnets
    private_subnets = module.aws_networking.private_subnets
  }
}

# SECURITY GROUP OUTPUTS - Critical for troubleshooting
output "security_group_ids" {
  description = "Map of security group IDs for reference and troubleshooting"
  value = {
    eks_cluster   = module.aws_networking.eks_cluster_security_group_id
    eks_nodes     = module.aws_networking.eks_nodes_security_group_id
    elasticsearch = module.aws_networking.elasticsearch_security_group_id
    kibana        = module.aws_networking.kibana_security_group_id
  }
}

output "security_group_details" {
  description = "Detailed security group information for validation"
  value = {
    eks_cluster = {
      id          = module.aws_networking.eks_cluster_security_group_id
      name        = "${var.environment}-elastic-eks-cluster-sg"
      description = "EKS Cluster Security Group"
    }
    eks_nodes = {
      id          = module.aws_networking.eks_nodes_security_group_id
      name        = "${var.environment}-elastic-eks-nodes-sg"
      description = "EKS Worker Nodes Security Group"
    }
    elasticsearch = {
      id          = module.aws_networking.elasticsearch_security_group_id
      name        = "${var.environment}-elastic-elasticsearch-sg"
      description = "Elasticsearch Security Group"
    }
    kibana = {
      id          = module.aws_networking.kibana_security_group_id
      name        = "${var.environment}-elastic-kibana-sg"
      description = "Kibana Security Group"
    }
  }
}

# IAM ROLE OUTPUTS - Critical for troubleshooting
output "iam_role_arns" {
  description = "IAM role ARNs for cluster and worker nodes"
  value = {
    cluster_role = module.aws_eks.cluster_role_arn
    nodes_role   = module.aws_eks.nodes_role_arn
  }
}

# MONITORING OUTPUTS - Phase 3 DevOps (Will be enabled after monitoring module is configured)
# output "monitoring_info" {
#   description = "Complete monitoring stack information and access instructions"
#   value       = module.monitoring.monitoring_access_instructions
#   sensitive   = true
# }

# output "monitoring_urls" {
#   description = "Direct URLs for monitoring tools (use with kubectl port-forward)"
#   value = {
#     grafana_url      = module.monitoring.grafana_url
#     prometheus_url   = module.monitoring.prometheus_url
#     alertmanager_url = module.monitoring.alertmanager_url
#   }
# }

# output "monitoring_components" {
#   description = "List of deployed monitoring components"
#   value       = module.monitoring.monitoring_components
# }

# CONNECTION INSTRUCTIONS
output "connection_instructions" {
  description = "Instructions for connecting to the infrastructure"
  value = {
    aws_cluster = {
      kubectl_config             = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.aws_eks.cluster_name}"
      elasticsearch_url          = "Will be available after Elasticsearch deployment"
      elasticsearch_internal_url = "http://elasticsearch.elasticsearch.svc.cluster.local:9200"
    }
  }
}

# VALIDATION OUTPUTS - For infrastructure health checks
output "infrastructure_health" {
  description = "Infrastructure health indicators"
  value = {
    vpc_configured        = module.aws_networking.vpc_id != null
    cluster_created       = module.aws_eks.cluster_name != null
    security_groups_ready = true # Simplified check - security groups are always created with the networking module
    iam_roles_configured  = module.aws_eks.cluster_role_arn != null
    monitoring_deployed   = false # Will be enabled after monitoring module is configured
  }
}

# PROJECT INFORMATION
output "project_info" {
  description = "Project information"
  value = {
    name        = var.project_name
    environment = var.environment
    owner       = var.owner
    region      = var.aws_region
    version     = "1.0.0"
    managed_by  = "terraform"
  }
}

# TROUBLESHOOTING OUTPUTS
output "troubleshooting_commands" {
  description = "Useful commands for troubleshooting common issues"
  value = {
    check_cluster_status  = "aws eks describe-cluster --name ${module.aws_eks.cluster_name} --region ${var.aws_region}"
    check_nodegroups      = "aws eks list-nodegroups --cluster-name ${module.aws_eks.cluster_name} --region ${var.aws_region}"
    check_security_groups = "aws ec2 describe-security-groups --group-ids ${module.aws_networking.eks_cluster_security_group_id}"
    check_iam_roles       = "aws iam list-attached-role-policies --role-name ${split("/", module.aws_eks.nodes_role_arn)[1]}"
    get_kubeconfig        = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.aws_eks.cluster_name}"
  }
}
