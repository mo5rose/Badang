# modules/monitoring/main.tf

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

# Prometheus Operator Installation
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "file:///helm-charts/prometheus"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "45.7.1"

  values = [
    templatefile("${path.module}/templates/prometheus-values.yaml", {
      registry_url = local.registry_url
      registry_secret = kubernetes_secret.registry_credentials.metadata[0].name
      storage_class = var.storage_class
      retention_period = var.retention_period
      replica_count = var.prometheus_replicas
    })
  ]

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_secret.registry_credentials
  ]
}

# Prometheus storage
resource "kubernetes_storage_class" "prometheus" {
  metadata {
    name = "prometheus-storage"
  }

  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy     = "Retain"
}

resource "kubernetes_persistent_volume" "prometheus" {
  count = var.prometheus_replicas

  metadata {
    name = "prometheus-data-${count.index}"
    labels = {
      type = "local"
      app  = "prometheus"
    }
  }

  spec {
    capacity = {
      storage = var.prometheus_storage_size
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class.prometheus.metadata[0].name
    persistent_volume_reclaim_policy = "Retain"
    local {
      path = "/mnt/prometheus-data-${count.index}"
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "kubernetes.io/hostname"
            operator = "In"
            values = var.prometheus_nodes
          }
        }
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Alert Manager Config
resource "kubernetes_secret" "alertmanager_config" {
  metadata {
    name      = "alertmanager-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "alertmanager.yml" = yamlencode({
      global = {
        resolve_timeout = "5m"
      }
      
      route = {
        group_by = ["namespace", "alertname", "severity"]
        group_wait = "30s"
        group_interval = "5m"
        repeat_interval = "12h"
        receiver = "null"
        routes = [
          {
            receiver = "internal-alerts"
            match = {
              severity = "critical"
            }
            group_wait = "30s"
            repeat_interval = "4h"
          }
        ]
      }
      
      receivers = [
        {
          name = "null"
        },
        {
          name = "internal-alerts"
          webhook_configs = [
            {
              url = "http://${var.internal_alert_webhook}"
              send_resolved = true
            }
          ]
        }
      ]
    })
  }
}