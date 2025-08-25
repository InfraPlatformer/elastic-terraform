# =============================================================================
# STREAMLINED MONITORING STACK
# =============================================================================

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
      environment = var.environment
    }
  }
}

# =============================================================================
# CORE MONITORING - PROMETHEUS & GRAFANA
# =============================================================================

# Streamlined Prometheus Stack - Essential components only
resource "helm_release" "prometheus_operator" {
  name       = "prometheus-operator"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "55.5.0"

  values = [
    yamlencode({
      # Prometheus - Reduced retention and storage
      prometheus = {
        prometheusSpec = {
          retention = "7d"  # Reduced from 30d
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "20Gi"  # Reduced from 50Gi
                  }
                }
                storageClassName = "gp3"
              }
            }
          }
          resources = {
            requests = {
              memory = "128Mi"  # Reduced from 256Mi
              cpu    = "50m"    # Reduced from 100m
            }
            limits = {
              memory = "512Mi"  # Reduced from 1Gi
              cpu    = "250m"   # Reduced from 500m
            }
          }
          # Essential Elasticsearch monitoring only
          additionalScrapeConfigs = [
            "- job_name: 'elasticsearch'",
            "  static_configs:",
            "    - targets: ['elasticsearch-master.elasticsearch.svc.cluster.local:9200']",
            "  metrics_path: '/_prometheus/metrics'",
            "  scrape_interval: 60s"  # Reduced frequency
          ]
        }
      }

      # Grafana - Essential dashboards only
      grafana = {
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled = true
          size    = "5Gi"  # Reduced from 10Gi
          storageClassName = "gp3"
        }
        # Streamlined dashboards - keep only essential ones
        dashboards = {
          "kubernetes-cluster" = {
            gnetId = 7249
            revision = 1
            datasource = "Prometheus"
          }
          "elasticsearch-overview" = {
            gnetId = 266
            revision = 1
            datasource = "Prometheus"
          }
        }
        resources = {
          requests = {
            memory = "64Mi"   # Reduced from 128Mi
            cpu    = "50m"    # Reduced from 100m
          }
          limits = {
            memory = "256Mi"  # Reduced from 512Mi
            cpu    = "250m"   # Reduced from 500m
          }
        }
      }

      # Alertmanager - Basic configuration
      alertmanager = {
        alertmanagerSpec = {
          retention = "72h"  # Reduced from 120h
          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "5Gi"  # Reduced from 10Gi
                  }
                }
                storageClassName = "gp3"
              }
            }
          }
          resources = {
            requests = {
              memory = "32Mi"
              cpu    = "25m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
      }

      # Disable resource-heavy components
      nodeExporter = {
        enabled = true
      }
      kubeStateMetrics = {
        enabled = true
      }
      defaultRules = {
        create = true
        rules = {
          alertmanager = false
          etcd = false
          configReloaders = false
          general = false
          k8s = true
          kubeApiserverAvailability = false
          kubeApiserverBurnrate = false
          kubeApiserverHistogram = false
          kubeApiserverSlos = false
          kubelet = false
          kubeProxy = false
          kubePrometheusGeneral = false
          kubePrometheusNodeRecording = false
          kubernetesApps = true
          kubernetesResources = true
          kubernetesStorage = false
          kubernetesSystem = false
          network = false
          node = false
          nodeExporterAlerting = false
          nodeExporterRecording = false
          prometheus = false
          prometheusOperator = false
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# =============================================================================
# OPTIONAL LOGGING (CONDITIONAL)
# =============================================================================

# Lightweight log collection (only if enabled)
resource "helm_release" "fluentd" {
  count      = var.enable_logging ? 1 : 0
  name       = "fluentd"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluentd"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "0.4.0"

  values = [
    yamlencode({
      config = {
        outputs = [
          {
            type = "elasticsearch"
            host = "elasticsearch-master.elasticsearch.svc.cluster.local"
            port = 9200
            logstash_format = true
            logstash_prefix = "fluentd"
            include_tag_key = true
            tag_key = "@log_name"
            flush_interval = "30s"  # Reduced frequency
          }
        ]
      }
      resources = {
        requests = {
          memory = "64Mi"   # Reduced
          cpu    = "50m"    # Reduced
        }
        limits = {
          memory = "128Mi"  # Reduced
          cpu    = "100m"   # Reduced
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# =============================================================================
# ESSENTIAL ALERTING RULES ONLY
# =============================================================================

# Minimal Prometheus rules for Elasticsearch health
resource "kubernetes_config_map" "prometheus_rules" {
  metadata {
    name      = "elasticsearch-monitoring-rules"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      app = "elasticsearch-monitoring"
    }
  }

  data = {
    "elasticsearch-rules.yaml" = yamlencode({
      groups = [
        {
          name = "elasticsearch.health"
          rules = [
            {
              alert = "ElasticsearchClusterDown"
              expr = "up{job=\"elasticsearch\"} == 0"
              for  = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary = "Elasticsearch cluster is down"
                description = "Elasticsearch cluster has been down for more than 5 minutes"
              }
            },
            {
              alert = "ElasticsearchHighMemoryUsage"
              expr = "elasticsearch_jvm_memory_used_bytes / elasticsearch_jvm_memory_max_bytes > 0.9"
              for  = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Elasticsearch high memory usage"
                description = "Elasticsearch memory usage is above 90%"
              }
            }
          ]
        }
      ]
    })
  }

  depends_on = [kubernetes_namespace.monitoring]
}
