# modules/database/pgbouncer.tf

resource "kubernetes_config_map" "pgbouncer_config" {
  metadata {
    name      = "pgbouncer-config"
    namespace = kubernetes_namespace.datalake.metadata[0].name
    labels = {
      app = "pgbouncer"
    }
  }

  data = {
    "pgbouncer.ini" = <<-EOT
      [databases]
      * = host=${var.db_host} port=${var.db_port}

      [pgbouncer]
      listen_addr = *
      listen_port = 6432
      unix_socket_dir =
      user = postgres
      auth_file = /etc/pgbouncer/userlist.txt
      auth_type = md5
      auth_user = ${var.admin_user}
      
      # Pool settings
      pool_mode = transaction
      max_client_conn = 1000
      default_pool_size = 50
      min_pool_size = 10
      reserve_pool_size = 25
      reserve_pool_timeout = 5
      max_db_connections = 100
      max_user_connections = 100
      
      # Connection lifetime
      server_reset_query = DISCARD ALL
      server_reset_query_always = 0
      server_check_delay = 30
      server_check_query = select 1
      server_lifetime = 3600
      server_idle_timeout = 600
      server_connect_timeout = 15
      server_login_retry = 15
      
      # TCP settings
      tcp_keepalive = 1
      tcp_keepcnt = 5
      tcp_keepidle = 30
      tcp_keepintvl = 30
      tcp_user_timeout = 0
      
      # TLS settings
      client_tls_sslmode = verify-full
      client_tls_key_file = /etc/pgbouncer/tls/tls.key
      client_tls_cert_file = /etc/pgbouncer/tls/tls.crt
      client_tls_ca_file = /etc/pgbouncer/tls/ca.crt
      
      # Logging
      log_connections = 1
      log_disconnections = 1
      log_pooler_errors = 1
      log_stats = 1
      stats_period = 60
      verbose = 0
    EOT

    "userlist.txt" = <<-EOT
      "${var.admin_user}" "${var.admin_password_md5}"
      "${var.app_user}" "${var.app_password_md5}"
    EOT
  }
}

resource "kubernetes_deployment" "pgbouncer" {
  metadata {
    name      = "pgbouncer"
    namespace = kubernetes_namespace.datalake.metadata[0].name
    labels = {
      app = "pgbouncer"
    }
  }

  spec {
    replicas = var.pgbouncer_replicas

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = 1
        max_surge       = 1
      }
    }

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
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "9127"
        }
      }

      spec {
        security_context {
          fs_group    = 70
          run_as_user = 70
        }

        container {
          name  = "pgbouncer"
          image = "${var.internal_registry}/pgbouncer:1.18"

          security_context {
            read_only_root_filesystem = true
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }

          port {
            container_port = 6432
            protocol      = "TCP"
          }

          port {
            container_port = 9127
            protocol      = "TCP"
            name          = "metrics"
          }

          resources {
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/pgbouncer"
            read_only  = true
          }

          volume_mount {
            name       = "tls"
            mount_path = "/etc/pgbouncer/tls"
            read_only  = true
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          liveness_probe {
            tcp_socket {
              port = 6432
            }
            initial_delay_seconds = 30
            period_seconds       = 10
            timeout_seconds     = 5
            failure_threshold   = 3
          }

          readiness_probe {
            exec {
              command = [
                "sh",
                "-c",
                "PGPASSWORD=$PGBOUNCER_PASSWORD psql -h 127.0.0.1 -p 6432 -U $PGBOUNCER_USER -d pgbouncer -c 'SHOW DATABASES;'"
              ]
            }
            initial_delay_seconds = 5
            period_seconds       = 10
            timeout_seconds     = 5
            failure_threshold   = 3
          }

          env {
            name = "PGBOUNCER_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.pgbouncer_auth.metadata[0].name
                key  = "admin_user"
              }
            }
          }

          env {
            name = "PGBOUNCER_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.pgbouncer_auth.metadata[0].name
                key  = "admin_password"
              }
            }
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.pgbouncer_config.metadata[0].name
          }
        }

        volume {
          name = "tls"
          secret {
            secret_name = kubernetes_secret.pgbouncer_tls.metadata[0].name
          }
        }

        volume {
          name = "tmp"
          empty_dir {}
        }

        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key      = "app"
                  operator = "In"
                  values   = ["pgbouncer"]
                }
              }
              topology_key = "kubernetes.io/hostname"
            }
          }
        }
      }
    }
  }
}