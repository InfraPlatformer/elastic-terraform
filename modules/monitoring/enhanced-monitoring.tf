# =============================================================================
# PROMETHEUS OPERATOR CRD INSTALLATION
# =============================================================================
# Install required CRDs before creating ServiceMonitor resources
# =============================================================================

# Install Prometheus Operator CRDs
resource "kubernetes_manifest" "prometheus_operator_crds" {
  count = var.enable_prometheus_operator ? 1 : 0
  
  manifest = {
    apiVersion = "apiextensions.k8s.io/v1"
    kind = "CustomResourceDefinition"
    metadata = {
      name = "servicemonitors.monitoring.coreos.com"
    }
    spec = {
      group = "monitoring.coreos.com"
      names = {
        kind = "ServiceMonitor"
        listKind = "ServiceMonitorList"
        plural = "servicemonitors"
        singular = "servicemonitor"
      }
      scope = "Namespaced"
      versions = [
        {
          name = "v1"
          served = true
          storage = true
          schema = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                spec = {
                  type = "object"
                  properties = {
                    selector = {
                      type = "object"
                    }
                    endpoints = {
                      type = "array"
                      items = {
                        type = "object"
                      }
                    }
                    namespaceSelector = {
                      type = "object"
                    }
                  }
                }
              }
            }
          }
        }
      ]
    }
  }
  
  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.prometheus_operator_enhanced
  ]
}

# =============================================================================
# ENHANCED FLUENTD CONFIGURATION
# =============================================================================

# Enhanced Prometheus Operator with Production Settings
resource "helm_release" "prometheus_operator_enhanced" {
  name       = "prometheus-operator-enhanced"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
          resources = {
            requests = {
              memory = "2Gi"
              cpu = "1000m"
            }
            limits = {
              memory = "4Gi"
              cpu = "2000m"
            }
          }
          retentionSize = "10GB"
          ruleSelectorNilUsesHelmValues = false
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues = false
          probeSelectorNilUsesHelmValues = false
        }
      }

      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "20Gi"
                  }
                }
              }
            }
          }
          resources = {
            requests = {
              memory = "1Gi"
              cpu = "500m"
            }
            limits = {
              memory = "2Gi"
              cpu = "1000m"
            }
          }
          retention = "120h"
        }
      }

      grafana = {
        adminPassword = "admin123"  # Change this in production
        persistence = {
          enabled = true
          storageClassName = "gp2"
          accessModes = ["ReadWriteOnce"]
          size = "10Gi"
        }
        resources = {
          requests = {
            memory = "1Gi"
            cpu = "500m"
          }
          limits = {
            memory = "2Gi"
            cpu = "1000m"
          }
        }
        dashboardProviders = {
          dashboardproviders = {
            apiVersion = 1
            providers = [
              {
                name = "default"
                orgId = 1
                folder = ""
                type = "file"
                disableDeletion = false
                editable = true
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }
        dashboards = {
          default = {
            elasticsearch-overview = {
              gnetId = 2320
              revision = 1
              datasource = "Prometheus"
            }
            kubernetes-cluster = {
              gnetId = 315
              revision = 3
              datasource = "Prometheus"
            }
            node-exporter = {
              gnetId = 1860
              revision = 22
              datasource = "Prometheus"
            }
          }
        }
      }

      defaultRules = {
        rules = {
          elasticsearch = true
          kubernetes = true
          node = true
          general = true
          alertmanager = true
          configReloaders = true
          etcd = true
          configReloaders = true
          kubeApiserverAvailability = true
          kubeApiserverBurnrate = true
          kubeApiserverHistogram = true
          kubeApiserverSlos = true
          kubeControllerManager = true
          kubelet = true
          kubeProxy = true
          kubePrometheusGeneral = true
          kubePrometheusNodeRecording = true
          kubeScheduler = true
          kubeStateMetrics = true
          kubelet = true
          kubeApiserverAvailability = true
          kubeApiserverBurnrate = true
          kubeApiserverHistogram = true
          kubeApiserverSlos = true
          kubeControllerManager = true
          kubelet = true
          kubeProxy = true
          kubePrometheusGeneral = true
          kubePrometheusNodeRecording = true
          kubeScheduler = true
          kubeStateMetrics = true
          kubelet = true
          kubeApiserverAvailability = true
          kubeApiserverBurnrate = true
          kubeApiserverHistogram = true
          kubeApiserverSlos = true
          kubeControllerManager = true
          kubelet = true
          kubeProxy = true
          kubePrometheusGeneral = true
          kubePrometheusNodeRecording = true
          kubeScheduler = true
          kubeStateMetrics = true
          kubelet = true
        }
      }

      prometheusOperator = {
        admissionWebhooks = {
          enabled = true
          patch = {
            enabled = true
          }
        }
        tls = {
          enabled = true
        }
        resources = {
          requests = {
            memory = "1Gi"
            cpu = "500m"
          }
          limits = {
            memory = "2Gi"
            cpu = "1000m"
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]

  timeout = 600
  wait = true
  wait_for_jobs = true

  lifecycle {
    create_before_destroy = true
  }
}

# Custom Prometheus Rules for Elasticsearch
resource "kubernetes_config_map" "elasticsearch_prometheus_rules" {
  depends_on = [var.eks_cluster]
  metadata {
    name      = "elasticsearch-prometheus-rules"
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
              for = "5m"
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
              for = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Elasticsearch high memory usage"
                description = "Elasticsearch memory usage is above 90%"
              }
            },
            {
              alert = "ElasticsearchHighDiskUsage"
              expr = "elasticsearch_filesystem_data_available_bytes / elasticsearch_filesystem_data_size_bytes < 0.1"
              for = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Elasticsearch high disk usage"
                description = "Elasticsearch disk usage is above 90%"
              }
            },
            {
              alert = "ElasticsearchHighCPUUsage"
              expr = "rate(elasticsearch_process_cpu_percent[5m]) > 80"
              for = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Elasticsearch high CPU usage"
                description = "Elasticsearch CPU usage is above 80%"
              }
            }
          ]
        },
        {
          name = "elasticsearch.performance"
          rules = [
            {
              alert = "ElasticsearchSlowQueries"
              expr = "histogram_quantile(0.95, rate(elasticsearch_indices_search_query_time_seconds_bucket[5m])) > 1"
              for = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Elasticsearch slow queries detected"
                description = "95th percentile of query time is above 1 second"
              }
            },
            {
              alert = "ElasticsearchHighIndexingLatency"
              expr = "histogram_quantile(0.95, rate(elasticsearch_indices_indexing_index_time_seconds_bucket[5m])) > 0.5"
              for = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "Elasticsearch high indexing latency"
                description = "95th percentile of indexing time is above 0.5 seconds"
              }
            }
          ]
        }
      ]
    })
  }
}

# Enhanced Fluentd Configuration
resource "helm_release" "fluentd_enhanced" {
  count      = var.enable_fluentd ? 1 : 0
  name       = "fluentd-enhanced"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluentd"
  version    = "0.4.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false

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
            flush_interval = "30s"
            retry_max_interval = "30s"
            retry_forever = true
            reload_connections = false
            reconnect_on_error = true
            reload_on_failure = true
            request_timeout = "30s"
            suppress_type_name = true
          }
        ]
      }
      resources = {
        limits = {
          cpu = "100m"
          memory = "128Mi"
        }
        requests = {
          cpu = "50m"
          memory = "64Mi"
        }
      }
      tolerations = [
        {
          key = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      ]
      nodeSelector = {
        "node-role.kubernetes.io/master" = "true"
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.prometheus_operator_enhanced
  ]

  timeout = 300
  wait = true
  wait_for_jobs = true
}

# Service Monitor for Elasticsearch
resource "kubernetes_manifest" "elasticsearch_service_monitor" {
  depends_on = [
    var.eks_cluster,
    helm_release.prometheus_operator_enhanced,
    kubernetes_manifest.prometheus_operator_crds[0]
  ]
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind = "ServiceMonitor"
    metadata = {
      name = "elasticsearch"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app = "elasticsearch"
        release = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "elasticsearch"
        }
      }
      endpoints = [
        {
          port = "http"
          path = "/_prometheus/metrics"
          interval = "30s"
          scrapeTimeout = "10s"
        }
      ]
      namespaceSelector = {
        matchNames = ["elasticsearch"]
      }
    }
  }
}
