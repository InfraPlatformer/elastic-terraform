# =============================================================================
# VARIABLES FOR AUTOSCALING MODULE
# =============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the cluster"
  type        = string
}

variable "eks_cluster" {
  description = "EKS cluster resource"
  type        = any
}
