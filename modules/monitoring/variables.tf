# =============================================================================
# MONITORING MODULE VARIABLES
# =============================================================================

variable "environment" {
  description = "Environment name (e.g., development, staging, production)"
  type        = string
  default     = "development"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "monitoring_retention_days" {
  description = "Number of days to retain monitoring data"
  type        = number
  default     = 30
}

variable "enable_alerting" {
  description = "Enable alerting and notifications"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable centralized logging with Fluentd"
  type        = bool
  default     = true
}

variable "enable_security_monitoring" {
  description = "Enable security monitoring with Falco"
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "gp3"
}

variable "monitoring_namespace" {
  description = "Namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "enable_fluentd" {
  description = "Enable Fluentd logging"
  type        = bool
  default     = true
}

variable "eks_cluster" {
  description = "EKS cluster resource for dependency"
  type        = any
  default     = null
}

variable "enable_prometheus_operator" {
  description = "Enable Prometheus Operator for monitoring"
  type        = bool
  default     = true
}
