# =============================================================================
# KIBANA MODULE FOR ADVANCED ELASTIC TERRAFORM
# =============================================================================
# This module deploys Kibana using Helm
# - Kibana deployment with Helm
# - Persistent storage and security configuration
# - Integration with Elasticsearch
# =============================================================================

# =============================================================================
# KIBANA NAMESPACE
# =============================================================================

# Create namespace for Kibana
resource "kubernetes_namespace" "kibana" {
  
  metadata {
    name = "kibana"
    labels = {
      name = "kibana"
      environment = var.environment
    }
  }
}

# =============================================================================
# KIBANA HELM RELEASE
# =============================================================================

# Kibana Helm Release
resource "helm_release" "kibana" {
  name       = "kibana"
  repository = "https://helm.elastic.co"
  chart      = "kibana"
  version    = var.kibana_version
  namespace  = kubernetes_namespace.kibana.metadata[0].name
  
  values = [
    yamlencode({
      # Basic configuration
      elasticsearchHosts = var.elasticsearch_hosts
      
      # Node configuration
      replicas = var.kibana_replicas
      
      # Resources
      resources = {
        requests = {
          memory = "512Mi"
          cpu    = "250m"
        }
        limits = {
          memory = "1Gi"
          cpu    = "1000m"
        }
      }
      
      # Storage
      volumeClaimTemplate = {
        spec = {
          accessModes = ["ReadWriteOnce"]
          resources = {
            requests = {
              storage = "10Gi"
            }
          }
          storageClassName = "gp3"
        }
      }
      
      # Security
      secretName = "kibana-credentials"
      
      # Configuration
      kibanaConfig = {
        "kibana.yml" = yamlencode({
          "server.name" = "kibana-${var.cluster_name}"
          "server.host" = "0.0.0.0"
          "elasticsearch.hosts" = var.elasticsearch_hosts
          "elasticsearch.username" = "kibana_system"
          "elasticsearch.password" = random_password.kibana_system.result
          
          # Security settings
          "xpack.security.enabled" = var.enable_security
          "xpack.encryptedSavedObjects.encryptionKey" = random_password.encryption_key.result
          
          # Performance settings
          "optimize.bundleFilter" = "!tests"
          "optimize.useBundleCache" = true
          
          # Monitoring
          "monitoring.ui.container.elasticsearch.enabled" = true
          "monitoring.ui.container.logstash.enabled" = false
          "monitoring.ui.container.beats.enabled" = false
        })
      }
      
      # Service configuration
      service = {
        type = "ClusterIP"
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
        }
      }
      
      # Ingress configuration (optional)
      ingress = var.enable_ingress ? {
        enabled = true
        className = "nginx"
        hosts = var.ingress_hosts
        tls = var.ingress_tls
        annotations = var.ingress_annotations
      } : {
        enabled = false
        className = ""
        hosts = []
        tls = []
        annotations = {}
      }
    })
  ]
  
  depends_on = [kubernetes_namespace.kibana]
}

# =============================================================================
# KIBANA CREDENTIALS SECRET
# =============================================================================

# Generate random password for Kibana system user
resource "random_password" "kibana_system" {
  length  = 32
  special = true
}

# Generate encryption key for Kibana
resource "random_password" "encryption_key" {
  length  = 32
  special = false
}

# Create Kubernetes secret for Kibana credentials
resource "kubernetes_secret" "kibana_credentials" {
  metadata {
    name      = "kibana-credentials"
    namespace = kubernetes_namespace.kibana.metadata[0].name
  }
  
  data = {
    username = "kibana_system"
    password = random_password.kibana_system.result
    encryption_key = random_password.encryption_key.result
  }
  
  depends_on = [kubernetes_namespace.kibana]
}

# =============================================================================
# KIBANA SERVICE
# =============================================================================

# External service for Kibana access
resource "kubernetes_service" "kibana_external" {
  metadata {
    name      = "kibana-external"
    namespace = kubernetes_namespace.kibana.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal"
    }
  }
  
  spec {
    type = "LoadBalancer"
    port {
      port        = 5601
      target_port = 5601
      protocol    = "TCP"
    }
    
    selector = {
      "app.kubernetes.io/name" = "kibana"
      "app.kubernetes.io/instance" = "kibana"
    }
  }
  
  depends_on = [helm_release.kibana]
}

# =============================================================================
# KIBANA CONFIGMAP
# =============================================================================

# ConfigMap for Kibana configuration
resource "kubernetes_config_map" "kibana_config" {
  metadata {
    name      = "kibana-config"
    namespace = kubernetes_namespace.kibana.metadata[0].name
    labels = {
      app = "kibana"
    }
  }
  
  data = {
    "kibana.yml" = yamlencode({
      "server.name" = "kibana-${var.cluster_name}"
      "server.host" = "0.0.0.0"
      "elasticsearch.hosts" = var.elasticsearch_hosts
      "elasticsearch.username" = "kibana_system"
      "elasticsearch.password" = random_password.kibana_system.result
      
      # Security settings
      "xpack.security.enabled" = var.enable_security
      "xpack.encryptedSavedObjects.encryptionKey" = random_password.encryption_key.result
      
      # Performance settings
      "optimize.bundleFilter" = "!tests"
      "optimize.useBundleCache" = true
      
      # Monitoring
      "monitoring.ui.container.elasticsearch.enabled" = true
      "monitoring.ui.container.logstash.enabled" = false
      "monitoring.ui.container.beats.enabled" = false
      
      # Custom settings
      "xpack.reporting.enabled" = true
      "xpack.reporting.kibanaServer.hostname" = "kibana.${var.cluster_name}.svc.cluster.local"
      "xpack.reporting.kibanaServer.port" = 5601
      "xpack.reporting.kibanaServer.protocol" = "http"
    })
  }
  
  depends_on = [kubernetes_namespace.kibana]
}

# =============================================================================
# KIBANA SERVICE ACCOUNT
# =============================================================================

# Service account for Kibana
resource "kubernetes_service_account" "kibana" {
  metadata {
    name      = "kibana"
    namespace = kubernetes_namespace.kibana.metadata[0].name
    labels = {
      app = "kibana"
    }
  }
}

# Role for Kibana
resource "kubernetes_role" "kibana" {
  metadata {
    name      = "kibana"
    namespace = kubernetes_namespace.kibana.metadata[0].name
    labels = {
      app = "kibana"
    }
  }
  
  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
  
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch", "patch"]
  }
}

# Role binding for Kibana
resource "kubernetes_role_binding" "kibana" {
  metadata {
    name      = "kibana"
    namespace = kubernetes_namespace.kibana.metadata[0].name
    labels = {
      app = "kibana"
    }
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.kibana.metadata[0].name
  }
  
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.kibana.metadata[0].name
    namespace = kubernetes_namespace.kibana.metadata[0].name
  }
}
