# modules/monitoring/postgres_pool.tf

# PgBouncer ConfigMap
resource "kubernetes_config_map" "pgbouncer_config" {
  metadata {
    name      = "pgbouncer-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "pgbouncer.ini" = <<-EOT
      [databases]
      datalake = host=${aws_rds_cluster.metadata.endpoint} port=5432 dbname=datalake

      [pgbouncer]
      listen_port = 6432
      listen_addr = *
      auth_type = md5
      auth_file = /etc/pgbouncer/userlist.txt
      
      # Connection pooling settings
      pool_mode = transaction
      max_client_conn = 1000
      default_pool_size = 50
      min_pool_size = 10
      reserve_pool_size = 25
      reserve_pool_timeout = 5
      max_db_connections = 100
      max_user_connections = 100
      
      # Connection lifetime settings
      server_reset_query = DISCARD ALL
      server_idle_timeout = 60
      server_lifetime = 3600
      
      # TCP keepalive settings
      tcp_keepalive = 1
      tcp_keepidle = 30
      tcp_keepintvl = 10
      
      # Logging
      log_connections = 1
      log_disconnections = 1
      log_pooler_errors = 1
      stats_period = 60
      
      # Memory management
      client_idle_timeout = 60
      idle_transaction_timeout = 60
    EOT

    "userlist.txt" = <<-EOT
      "grafana_reader" "${random_password.grafana_db_password.result}"
    EOT
  }
}

# PgBouncer Deployment
resource "kubernetes_deployment" "pgbouncer" {
  metadata {
    name      = "pgbouncer"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "pgbouncer"
      }
    }

    template {
      metadata {
        labels = {
          app = "pgbouncer"
        }
      }

spec {
    template {
      spec {
        container {
          image = "internal-registry.company.local/pgbouncer:1.18"
          
          # Add offline configuration
          volume_mount {
            name = "ca-certificates"
            mount_path = "/etc/ssl/certs/company-ca.crt"
            sub_path = "company-ca.crt"
            read_only = true
          }

          env {
            name = "SSL_CERT_FILE"
            value = "/etc/ssl/certs/company-ca.crt"
          }
        }

        volume {
          name = "ca-certificates"
          config_map {
            name = kubernetes_config_map.ca_certificates.metadata[0].name
          }
        }

        image_pull_secrets {
          name = kubernetes_secret.registry_credentials.metadata[0].name
        }
      }
    }
  }
}

# PgBouncer Service
resource "kubernetes_service" "pgbouncer" {
  metadata {
    name      = "pgbouncer"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    selector = {
      app = "pgbouncer"
    }

    port {
      port        = 6432
      target_port = 6432
    }
  }
}