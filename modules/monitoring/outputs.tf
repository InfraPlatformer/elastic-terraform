# =============================================================================
# MONITORING MODULE OUTPUTS
# =============================================================================

output "monitoring_namespace" {
  description = "Namespace where monitoring components are deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_url" {
  description = "URL to access Grafana dashboard"
  value       = "http://localhost:3000"
}

output "grafana_admin_password" {
  description = "Admin password for Grafana (use with kubectl port-forward)"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "prometheus_url" {
  description = "URL to access Prometheus (use with kubectl port-forward)"
  value       = "http://localhost:9090"
}

output "alertmanager_url" {
  description = "URL to access Alertmanager (use with kubectl port-forward)"
  value       = "http://localhost:9093"
}

output "monitoring_access_instructions" {
  description = "Instructions to access monitoring tools"
  value = <<-EOT
    🔍 MONITORING ACCESS INSTRUCTIONS:
    
    📊 Grafana Dashboard:
       kubectl port-forward -n monitoring svc/prometheus-operator-grafana 3000:80
       URL: http://localhost:3000
       Username: admin
       Password: ${var.grafana_admin_password}
    
    📈 Prometheus:
       kubectl port-forward -n monitoring svc/prometheus-operator-kube-p-prometheus 9090:9090
       URL: http://localhost:9090
    
    🚨 Alertmanager:
       kubectl port-forward -n monitoring svc/prometheus-operator-kube-p-alertmanager 9093:9093
       URL: http://localhost:9093
    
    📝 Logs (Elasticsearch):
       kubectl port-forward -n elasticsearch svc/elasticsearch-master 9200:9200
       URL: http://localhost:9200
    
    🎯 Kibana:
       kubectl port-forward -n elasticsearch svc/kibana-kibana 5601:5601
       URL: http://localhost:5601
    
    🔒 Security Monitoring (Falco):
       kubectl logs -n monitoring -l app=falco
    
    📊 Available Dashboards:
       - Backup Monitoring Dashboard
       - Kubernetes Cluster Overview
       - Infrastructure Overview
       - Elasticsearch Backup Monitoring
  EOT
}

output "monitoring_components" {
  description = "List of deployed monitoring components"
  value = [
    "Prometheus Operator",
    "Grafana",
    "Alertmanager",
    "Fluentd (Logging)",
    "Falco (Security)",
    "Custom Backup Monitoring"
  ]
}

output "monitoring_alerts" {
  description = "Available monitoring alerts"
  value = [
    "BackupJobFailed - Critical backup failures",
    "BackupTooOld - Backups older than 24 hours",
    "BackupSizeTooSmall - Suspicious backup sizes",
    "ElasticsearchClusterRed - Cluster health issues",
    "HighResourceUsage - CPU/Memory thresholds"
  ]
}

output "monitoring_metrics" {
  description = "Key metrics being collected"
  value = [
    "Backup job status and duration",
    "Backup size and success rate",
    "Elasticsearch cluster health",
    "Kubernetes cluster metrics",
    "AWS/Azure infrastructure metrics",
    "Security events and anomalies"
  ]
}
