# modules/registry/main.tf

terraform {
  required_providers {
    kubernetes = ">= 2.0.0"
    helm = ">= 2.0.0"
  }
}

# Validation for required variables
variable "registry_node" {
  description = "Node for registry deployment"
  type        = string
  validation {
    condition     = length(var.registry_node) > 0
    error_message = "Registry node must be specified."
  }
}

# Registry Storage
resource "kubernetes_persistent_volume" "registry" {
  metadata {
    name = "private-registry-pv"
    labels = {
      type = "local"
      app  = "registry"
    }
  }

  spec {
    capacity = {
      storage = "100Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = "local-storage"
    local {
      path = "/mnt/registry-data"
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "kubernetes.io/hostname"
            operator = "In"
            values = [var.registry_node]
          }
        }
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Registry PVC
resource "kubernetes_persistent_volume_claim" "registry" {
  metadata {
    name      = "registry-pvc"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "100Gi"
      }
    }
    storage_class_name = "local-storage"
    volume_name        = kubernetes_persistent_volume.registry.metadata[0].name
  }

  depends_on = [kubernetes_persistent_volume.registry]
}

# Registry Deployment
resource "kubernetes_deployment" "private_registry" {
  metadata {
    name      = "private-registry"
    namespace = kubernetes_namespace.registry.metadata[0].name
    labels = {
      app = "private-registry"
    }
  }

  spec {
    replicas = 2

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = 1
        max_surge       = 1
      }
    }

    selector {
      match_labels = {
        app = "private-registry"
      }
    }

    template {
      metadata {
        labels = {
          app = "private-registry"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "5000"
        }
      }

      spec {
        security_context {
          fs_group    = 1000
          run_as_user = 1000
        }

        container {
          image = "internal-registry.company.local/registry:2.8.1"
          name  = "registry"

          security_context {
            read_only_root_filesystem = true
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }

          port {
            container_port = 5000
            protocol      = "TCP"
          }

          volume_mount {
            name       = "registry-data"
            mount_path = "/var/lib/registry"
          }

          volume_mount {
            name       = "registry-config"
            mount_path = "/etc/docker/registry"
            read_only  = true
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/v2/_catalog"
              port = 5000
            }
            initial_delay_seconds = 15
            period_seconds       = 10
            timeout_seconds     = 5
            failure_threshold   = 3
          }

          readiness_probe {
            http_get {
              path = "/v2/_catalog"
              port = 5000
            }
            initial_delay_seconds = 5
            period_seconds       = 10
            timeout_seconds     = 5
            failure_threshold   = 3
          }
        }

        volume {
          name = "registry-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.registry.metadata[0].name
          }
        }

        volume {
          name = "registry-config"
          config_map {
            name = kubernetes_config_map.registry_config.metadata[0].name
          }
        }

        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key      = "app"
                  operator = "In"
                  values   = ["private-registry"]
                }
              }
              topology_key = "kubernetes.io/hostname"
            }
          }
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Registry Service
resource "kubernetes_service" "registry" {
  metadata {
    name      = "private-registry"
    namespace = kubernetes_namespace.registry.metadata[0].name
    labels = {
      app = "private-registry"
    }
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "private-registry"
    }
    port {
      port        = 5000
      target_port = 5000
      protocol    = "TCP"
    }
  }
}

# Registry Config
resource "kubernetes_config_map" "registry_config" {
  metadata {
    name      = "registry-config"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }

  data = {
    "config.yml" = yamlencode({
      version = "0.1"
      log = {
        level = "info"
        formatter = "json"
        fields = {
          service = "registry"
        }
      }
      storage = {
        cache = {
          blobdescriptor = "inmemory"
        }
        filesystem = {
          rootdirectory = "/var/lib/registry"
        }
        maintenance = {
          uploadpurging = {
            enabled = true
            age = "168h"
            interval = "24h"
            dryrun = false
          }
        }
      }
      http = {
        addr = ":5000"
        headers = {
          "X-Content-Type-Options" = ["nosniff"]
        }
      }
      health = {
        storagedriver = {
          enabled = true
          interval = "10s"
          threshold = 3
        }
      }
    })
  }
}

# Network Policies
resource "kubernetes_network_policy" "registry" {
  metadata {
    name      = "registry-network-policy"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "private-registry"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.datalake.metadata[0].name
          }
        }
      }
      ports {
        port     = 5000
        protocol = "TCP"
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.datalake.metadata[0].name
          }
        }
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

# Output values
output "registry_service_name" {
  value = "${kubernetes_service.registry.metadata[0].name}.${kubernetes_service.registry.metadata[0].namespace}.svc.cluster.local"
  description = "Internal registry service DNS name"
}

output "registry_port" {
  value = kubernetes_service.registry.spec[0].port[0].port
  description = "Registry service port"
}