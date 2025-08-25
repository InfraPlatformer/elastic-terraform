# =============================================================================
# VARIABLES FOR ADVANCED ELASTIC TERRAFORM SETUP
# =============================================================================

# =============================================================================
# GLOBAL VARIABLES
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "advanced-elastic"
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development"
  }
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "devops-team"
}

variable "kubernetes_version" {
  description = "Kubernetes version for clusters"
  type        = string
  default     = "1.29"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "advanced-elastic-staging-aws"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

# =============================================================================
# AWS CONFIGURATION
# =============================================================================

variable "aws_region" {
  description = "AWS region for infrastructure"
  type        = string
  default     = "us-west-2"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (alias for aws_vpc_cidr)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_node_groups" {
  description = "AWS EKS node group configuration"
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

  default = {
    elasticsearch = {
      instance_types = ["t3.medium", "t3.large"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      max_size       = 5
      desired_size   = 3
      disk_size      = 100
      labels = {
        role = "elasticsearch"
      }
      taints = [{
        key    = "dedicated"
        value  = "elasticsearch"
        effect = "NO_SCHEDULE"
      }]
    }

    kibana = {
      instance_types = ["t3.small", "t3.medium"]
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      disk_size      = 50
      labels = {
        role = "kibana"
      }
      taints = [{
        key    = "dedicated"
        value  = "kibana"
        effect = "NO_SCHEDULE"
      }]
    }

    monitoring = {
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      disk_size      = 50
      labels = {
        role = "monitoring"
      }
      taints = []
    }
  }
}

variable "aws_backup_bucket" {
  description = "AWS S3 bucket for backups"
  type        = string
  default     = ""
}

# =============================================================================
# AZURE CONFIGURATION
# =============================================================================

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
  sensitive   = true
}

variable "azure_resource_group" {
  description = "Azure resource group name"
  type        = string
  default     = "advanced-elastic-rg"
}

variable "azure_location" {
  description = "Azure region for infrastructure"
  type        = string
  default     = "West US 2"
}

variable "azure_node_pools" {
  description = "Azure AKS node pool configuration"
  type = map(object({
    vm_size             = string
    os_disk_size_gb     = number
    count               = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    node_labels         = map(string)
    node_taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))

  default = {
    elasticsearch = {
      vm_size             = "Standard_D2s_v3"
      os_disk_size_gb     = 100
      count               = 3
      enable_auto_scaling = true
      min_count           = 2
      max_count           = 5
      node_labels = {
        role = "elasticsearch"
      }
      node_taints = [{
        key    = "dedicated"
        value  = "elasticsearch"
        effect = "NoSchedule"
      }]
    }

    kibana = {
      vm_size             = "Standard_D1s_v3"
      os_disk_size_gb     = 50
      count               = 2
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 3
      node_labels = {
        role = "kibana"
      }
      node_taints = [{
        key    = "dedicated"
        value  = "kibana"
        effect = "NoSchedule"
      }]
    }

    monitoring = {
      vm_size             = "Standard_D1s_v3"
      os_disk_size_gb     = 50
      count               = 1
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 2
      node_labels = {
        role = "monitoring"
      }
      node_taints = []
    }
  }
}

variable "azure_backup_storage" {
  description = "Azure storage account for backups"
  type        = string
  default     = ""
}

# =============================================================================
# ELASTIC STACK CONFIGURATION
# =============================================================================

variable "elasticsearch_version" {
  description = "Elasticsearch version"
  type        = string
  default     = "8.11.0"
}

variable "kibana_version" {
  description = "Kibana version"
  type        = string
  default     = "8.11.0"
}

variable "elastic_cloud_region" {
  description = "Elastic Cloud region"
  type        = string
  default     = "us-west-2"
}

variable "elastic_cloud_deployment_template" {
  description = "Elastic Cloud deployment template"
  type        = string
  default     = "gcp-io-optimized"
}

# =============================================================================
# CROSS-CLUSTER FEATURES
# =============================================================================

variable "enable_cross_cluster_search" {
  description = "Enable Cross-Cluster Search (CCS)"
  type        = bool
  default     = true
}

variable "enable_cross_cluster_replication" {
  description = "Enable Cross-Cluster Replication (CCR)"
  type        = bool
  default     = true
}

variable "cross_cluster_remote_clusters" {
  description = "List of remote clusters for CCS/CCR"
  type = list(object({
    name             = string
    seeds            = list(string)
    skip_unavailable = bool
  }))
  default = []
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

variable "enable_encryption_at_rest" {
  description = "Enable encryption at rest"
  type        = bool
  default     = false
}

variable "enable_encryption_in_transit" {
  description = "Enable encryption in transit (TLS)"
  type        = bool
  default     = true
}

variable "enable_audit_logging" {
  description = "Enable audit logging"
  type        = bool
  default     = true
}

variable "enable_rbac" {
  description = "Enable Role-Based Access Control"
  type        = bool
  default     = true
}

variable "elastic_password" {
  description = "Elasticsearch superuser password"
  type        = string
  sensitive   = true
  default     = ""
}

# =============================================================================
# MONITORING CONFIGURATION
# =============================================================================

variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}

variable "monitoring_retention_days" {
  description = "Monitoring data retention in days"
  type        = number
  default     = 30
}

variable "enable_alerting" {
  description = "Enable alerting and notifications"
  type        = bool
  default     = true
}

# =============================================================================
# BACKUP CONFIGURATION
# =============================================================================

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 90
}

variable "backup_schedule" {
  description = "Backup schedule (cron expression)"
  type        = string
  default     = "0 2 * * *" # Daily at 2 AM
}

# =============================================================================
# PERFORMANCE & SCALING
# =============================================================================

variable "elasticsearch_heap_size" {
  description = "Elasticsearch JVM heap size"
  type        = string
  default     = "2g"
}

variable "elasticsearch_data_nodes" {
  description = "Number of Elasticsearch data nodes"
  type        = number
  default     = 3
}

variable "elasticsearch_master_nodes" {
  description = "Number of Elasticsearch master nodes"
  type        = number
  default     = 3
}

variable "elasticsearch_ingest_nodes" {
  description = "Number of Elasticsearch ingest nodes"
  type        = number
  default     = 2
}

variable "kibana_replicas" {
  description = "Number of Kibana replicas"
  type        = number
  default     = 2
}

# =============================================================================
# NETWORKING & ACCESS
# =============================================================================

variable "enable_public_access" {
  description = "Enable public access to EKS control plane (required for private nodes)"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the cluster"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Changed for EKS public access - use specific IPs in production
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for AWS services"
  type        = bool
  default     = true
}

# =============================================================================
# TAGS & LABELS
# =============================================================================

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "advanced-elastic"
    Environment = "development"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
    Purpose     = "elastic-stack"
    CostCenter  = "engineering"
  }
}

# =============================================================================
# MONITORING & GRAFANA
# =============================================================================

variable "grafana_admin_password" {
  description = "Admin password for Grafana dashboard"
  type        = string
  default     = "admin123"
  sensitive   = true
}

# =============================================================================
# SSH ACCESS CONFIGURATION
# =============================================================================

variable "ssh_key_name" {
  description = "SSH key name for EC2 instance access"
  type        = string
  default     = ""
}
