# modules/monitoring/postgres_monitoring.tf

# Prometheus PostgreSQL Exporter
resource "kubernetes_deployment" "postgres_exporter" {
  metadata {
    name      = "postgres-exporter"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres-exporter"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres-exporter"
        }
      }

      spec {
        container {
          name  = "postgres-exporter"
          image = "wrouesnel/postgres_exporter:latest"
          
          env {
            name  = "DATA_SOURCE_NAME"
            value = "postgresql://grafana_reader:${random_password.grafana_db_password.result}@${kubernetes_service.pgbouncer.metadata[0].name}:6432/datalake?sslmode=disable"
          }

          port {
            container_port = 9187
          }
        }
      }
    }
  }
}

# Custom Prometheus Rules for PgBouncer monitoring
resource "kubernetes_config_map" "postgres_monitoring_rules" {
  metadata {
    name      = "postgres-monitoring-rules"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "postgres_rules.yml" = yamlencode({
      groups = [{
        name = "postgres_connection_pool"
        rules = [
          {
            alert = "HighConnectionUtilization"
            expr  = "sum(pgbouncer_pools_client_active_connections) / sum(pgbouncer_pools_client_maxwait) > 0.8"
            for   = "5m"
            labels = {
              severity = "warning"
            }
            annotations = {
              summary = "Connection pool utilization is high"
              description = "Connection pool utilization has been above 80% for 5 minutes"
            }
          },
          {
            alert = "LongRunningQueries"
            expr  = "pgbouncer_pools_client_waiting_connections > 0"
            for   = "1m"
            labels = {
              severity = "warning"
            }
            annotations = {
              summary = "Queries waiting for available connections"
              description = "There are queries waiting for available connections in the pool"
            }
          }
        ]
      }]
    })
  }
}