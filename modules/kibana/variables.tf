# =============================================================================
# VARIABLES FOR KIBANA MODULE
# =============================================================================

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kibana_version" {
  description = "Kibana Helm chart version"
  type        = string
  default     = "8.11.0"
}

variable "elasticsearch_hosts" {
  description = "Elasticsearch hosts for Kibana to connect to"
  type        = list(string)
  default     = ["http://elasticsearch.elasticsearch.svc.cluster.local:9200"]
}

variable "kibana_replicas" {
  description = "Number of Kibana replicas"
  type        = number
  default     = 2
}

variable "enable_security" {
  description = "Enable X-Pack security for Kibana"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable Ingress for Kibana"
  type        = bool
  default     = false
}

variable "ingress_hosts" {
  description = "Ingress hosts for Kibana"
  type        = list(string)
  default     = []
}

variable "ingress_tls" {
  description = "Ingress TLS configuration for Kibana"
  type = list(object({
    secret_name = string
    hosts       = list(string)
  }))
  default = []
}

variable "ingress_annotations" {
  description = "Ingress annotations for Kibana"
  type        = map(string)
  default = {
    "kubernetes.io/ingress.class" = "nginx"
    "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {}
}

