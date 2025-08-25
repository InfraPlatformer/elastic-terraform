# =============================================================================
# EKS MODULE OUTPUTS
# =============================================================================

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.main.version
}

output "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "EKS cluster OIDC provider ARN"
  value       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}"
}

output "node_groups" {
  description = "EKS node groups"
  value       = aws_eks_node_group.main
}

output "cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = aws_iam_role.eks_cluster.arn
}

output "nodes_role_arn" {
  description = "EKS nodes IAM role ARN"
  value       = aws_iam_role.eks_nodes.arn
}

output "addons" {
  description = "EKS add-ons"
  value = {
    vpc_cni = aws_eks_addon.vpc_cni
    coredns = aws_eks_addon.coredns
    kube_proxy = aws_eks_addon.kube_proxy
    aws_ebs_csi_driver = aws_eks_addon.aws_ebs_csi_driver
  }
}
