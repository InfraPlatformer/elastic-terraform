# =============================================================================
# OUTPUTS FOR KIBANA MODULE
# =============================================================================

output "kibana_namespace" {
  description = "Kubernetes namespace for Kibana"
  value       = kubernetes_namespace.kibana.metadata[0].name
}

output "kibana_release" {
  description = "Kibana Helm release information"
  value = {
    name      = helm_release.kibana.name
    namespace = helm_release.kibana.namespace
    version   = helm_release.kibana.version
    status    = helm_release.kibana.status
  }
}

output "kibana_credentials_secret_name" {
  description = "Name of the Kubernetes secret containing Kibana credentials"
  value       = kubernetes_secret.kibana_credentials.metadata[0].name
}

output "kibana_external_url" {
  description = "External URL for Kibana access"
  value       = "http://${kubernetes_service.kibana_external.status[0].load_balancer[0].ingress[0].hostname}:5601"
}

output "kibana_internal_url" {
  description = "Internal URL for Kibana access"
  value       = "http://kibana.kibana.svc.cluster.local:5601"
}

output "kibana_config_map" {
  description = "Kibana configuration ConfigMap information"
  value = {
    name      = kubernetes_config_map.kibana_config.metadata[0].name
    namespace = kubernetes_config_map.kibana_config.metadata[0].namespace
  }
}

output "kibana_service_account" {
  description = "Kibana service account information"
  value = {
    name      = kubernetes_service_account.kibana.metadata[0].name
    namespace = kubernetes_service_account.kibana.metadata[0].namespace
  }
}

output "kibana_role" {
  description = "Kibana role information"
  value = {
    name      = kubernetes_role.kibana.metadata[0].name
    namespace = kubernetes_role.kibana.metadata[0].namespace
  }
}

output "kibana_role_binding" {
  description = "Kibana role binding information"
  value = {
    name      = kubernetes_role_binding.kibana.metadata[0].name
    namespace = kubernetes_role_binding.kibana.metadata[0].namespace
  }
}












