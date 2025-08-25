# =============================================================================
# VARIABLES FOR ELASTICSEARCH MODULE
# =============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  type        = string
}

variable "nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
  type        = string
}

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "elasticsearch_version" {
  description = "Elasticsearch Helm chart version"
  type        = string
  default     = ""
}

variable "elasticsearch_data_nodes" {
  description = "Number of Elasticsearch data nodes"
  type        = number
  default     = 3
}

variable "elasticsearch_heap_size" {
  description = "Elasticsearch JVM heap size"
  type        = string
  default     = "2Gi"
}

variable "enable_public_access" {
  description = "Enable public access to the EKS cluster"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the cluster"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "enable_encryption_at_rest" {
  description = "Enable encryption at rest for EKS"
  type        = bool
  default     = true
}

variable "enable_encryption_in_transit" {
  description = "Enable encryption in transit for Elasticsearch"
  type        = bool
  default     = true
}

variable "enable_security" {
  description = "Enable X-Pack security for Elasticsearch"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {}
}

variable "ssh_key_name" {
  description = "SSH key name for node access"
  type        = string
  default     = ""
}

