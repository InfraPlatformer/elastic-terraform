# =============================================================================
# OUTPUTS FOR ELASTICSEARCH MODULE
# =============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL for the EKS cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "The OIDC provider ARN for the EKS cluster"
  value       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}"
}

output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "nodes_role_arn" {
  description = "ARN of the EKS worker nodes IAM role"
  value       = aws_iam_role.eks_nodes.arn
}

output "node_groups" {
  description = "Map of node group information"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      name           = v.node_group_name
      arn            = v.arn
      status         = v.status
      instance_types = v.instance_types
      capacity_type  = v.capacity_type
      scaling_config = v.scaling_config
      labels         = v.labels
      taints         = try(v.taints, [])
    }
  }
}

output "elasticsearch_namespace" {
  description = "Kubernetes namespace for Elasticsearch"
  value       = kubernetes_namespace.elasticsearch.metadata[0].name
}

output "elasticsearch_credentials_secret_name" {
  description = "Name of the Kubernetes secret containing Elasticsearch credentials"
  value       = kubernetes_secret.elasticsearch_credentials.metadata[0].name
}

output "elasticsearch_external_url" {
  description = "External URL for Elasticsearch access"
  value       = "http://${kubernetes_service.elasticsearch_external.status[0].load_balancer[0].ingress[0].hostname}:9200"
}

output "elasticsearch_internal_url" {
  description = "Internal URL for Elasticsearch access"
  value       = "http://elasticsearch.elasticsearch.svc.cluster.local:9200"
}

output "elasticsearch_helm_release" {
  description = "Elasticsearch Helm release information"
  value = {
    name      = helm_release.elasticsearch.name
    namespace = helm_release.elasticsearch.namespace
    version   = helm_release.elasticsearch.version
    status    = helm_release.elasticsearch.status
  }
}

output "cluster_health" {
  description = "Cluster health status (to be populated after deployment)"
  value       = "healthy"
}

# KMS Key Outputs - TEMPORARILY DISABLED DUE TO PERMISSION ISSUES
# output "eks_encryption_key_arn" {
#   description = "ARN of the EKS encryption KMS key"
#   value       = aws_kms_key.eks_encryption.arn
# }

# output "ebs_encryption_key_arn" {
#   description = "ARN of the EBS encryption KMS key"
#   value       = aws_kms_key.ebs_encryption.arn
# }

# output "app_secrets_key_arn" {
#   description = "ARN of the application secrets KMS key"
#   value       = aws_kms_key.app_secrets.arn
# }


