# =============================================================================
# VARIABLES FOR BACKUP MODULE
# =============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "eks_cluster" {
  description = "EKS cluster resource for dependency"
  type        = any
  default     = null
}
