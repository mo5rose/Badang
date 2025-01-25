# modules/monitoring/health_checks.tf

resource "kubernetes_config_map" "grafana_health_check" {
  metadata {
    name      = "grafana-health-check"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "health-check.sh" = <<-EOF
      #!/bin/bash
      
      # Check Prometheus connection
      curl -f http://prometheus-server:9090/-/healthy || exit 1
      
      # Check CloudWatch connection
      aws cloudwatch list-metrics --namespace AWS/DataLake || exit 1
      
      # Check PostgreSQL connection
      PGPASSWORD=$GRAFANA_DB_PASSWORD psql -h $DB_HOST -U grafana_reader -d datalake -c "SELECT 1" || exit 1
    EOF
  }
}

resource "kubernetes_cron_job" "datasource_health_check" {
  metadata {
    name      = "datasource-health-check"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    schedule = "*/5 * * * *"
    job_template {
      spec {
        template {
          spec {
            container {
              name    = "health-check"
              image   = "postgres:13-alpine"
              command = ["/scripts/health-check.sh"]
              volume_mount {
                name       = "health-check-script"
                mount_path = "/scripts"
              }
            }
            volume {
              name = "health-check-script"
              config_map {
                name = kubernetes_config_map.grafana_health_check.metadata[0].name
              }
            }
          }
        }
      }
    }
  }
}
