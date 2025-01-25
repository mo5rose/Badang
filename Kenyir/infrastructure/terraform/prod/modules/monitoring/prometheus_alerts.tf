# modules/monitoring/prometheus_alerts.tf

resource "kubernetes_config_map" "prometheus_alerts" {
  metadata {
    name      = "prometheus-alerts"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "alert_rules.yml" = yamlencode({
      groups = [
        {
          name = "connection_pool_alerts"
          rules = [
            {
              alert = "ConnectionPoolUtilizationWarning"
              expr  = "sum(pgbouncer_pools_client_active_connections) by (database) / sum(pgbouncer_pools_client_maxwait) by (database) > 0.7"
              for   = "5m"
              labels = {
                severity = "warning"
                category = "connection_pool"
              }
              annotations = {
                summary = "Connection pool utilization above 70%"
                description = "Database {{ $labels.database }} connection pool utilization has been above 70% for 5 minutes"
                runbook_url = "https://wiki.internal/runbooks/connection-pool"
              }
            },
            {
              alert = "ConnectionPoolUtilizationCritical"
              expr  = "sum(pgbouncer_pools_client_active_connections) by (database) / sum(pgbouncer_pools_client_maxwait) by (database) > 0.85"
              for   = "3m"
              labels = {
                severity = "critical"
                category = "connection_pool"
              }
              annotations = {
                summary = "Connection pool utilization above 85%"
                description = "Database {{ $labels.database }} connection pool utilization has been above 85% for 3 minutes"
                runbook_url = "https://wiki.internal/runbooks/connection-pool"
              }
            }
          ]
        },
        {
          name = "query_performance_alerts"
          rules = [
            {
              alert = "LongRunningQueriesWarning"
              expr  = "rate(pgbouncer_pools_client_waiting_connections[5m]) > 2"
              for   = "2m"
              labels = {
                severity = "warning"
                category = "query_performance"
              }
              annotations = {
                summary = "Increased query waiting time"
                description = "Average of {{ $value }} queries waiting for connections in the past 5 minutes"
              }
            },
            {
              alert = "LongRunningQueriesCritical"
              expr  = "rate(pgbouncer_pools_client_waiting_connections[5m]) > 5"
              for   = "1m"
              labels = {
                severity = "critical"
                category = "query_performance"
              }
              annotations = {
                summary = "Critical query waiting time"
                description = "Average of {{ $value }} queries waiting for connections in the past 5 minutes"
              }
            },
            {
              alert = "QueryLatencyHigh"
              expr  = "rate(pgbouncer_pools_server_maxwait_seconds[5m]) > 1"
              for   = "2m"
              labels = {
                severity = "warning"
                category = "query_performance"
              }
              annotations = {
                summary = "High query latency detected"
                description = "Average query latency is {{ $value }}s in the past 5 minutes"
              }
            }
          ]
        },
        {
          name = "resource_utilization_alerts"
          rules = [
            {
              alert = "HighMemoryUtilization"
              expr  = "process_resident_memory_bytes{job=\"pgbouncer\"} / process_virtual_memory_bytes{job=\"pgbouncer\"} > 0.8"
              for   = "5m"
              labels = {
                severity = "warning"
                category = "resources"
              }
              annotations = {
                summary = "High memory utilization"
                description = "PgBouncer memory utilization is {{ $value | humanizePercentage }}"
              }
            },
            {
              alert = "ConnectionResetRate"
              expr  = "rate(pgbouncer_pools_server_maxwait_count[5m]) > 10"
              for   = "3m"
              labels = {
                severity = "warning"
                category = "connections"
              }
              annotations = {
                summary = "High connection reset rate"
                description = "Connection reset rate is {{ $value }} per second"
              }
            }
          ]
        },
        {
          name = "availability_alerts"
          rules = [
            {
              alert = "PgBouncerDown"
              expr  = "up{job=\"pgbouncer\"} == 0"
              for   = "1m"
              labels = {
                severity = "critical"
                category = "availability"
              }
              annotations = {
                summary = "PgBouncer instance is down"
                description = "PgBouncer instance has been down for more than 1 minute"
              }
            },
            {
              alert = "DatabaseConnectionFailures"
              expr  = "increase(pgbouncer_errors_count{type=\"connection_failure\"}[5m]) > 5"
              for   = "2m"
              labels = {
                severity = "critical"
                category = "availability"
              }
              annotations = {
                summary = "Database connection failures detected"
                description = "{{ $value }} connection failures in the last 5 minutes"
              }
            }
          ]
        },
        {
          name = "pool_health_alerts"
          rules = [
            {
              alert = "PoolMaxClientsReached"
              expr  = "pgbouncer_pools_client_active_connections / pgbouncer_pools_client_maxwait > 0.95"
              for   = "1m"
              labels = {
                severity = "critical"
                category = "pool_health"
              }
              annotations = {
                summary = "Pool max clients nearly reached"
                description = "Connection pool is at {{ $value | humanizePercentage }} of maximum capacity"
              }
            },
            {
              alert = "UnhealthyPoolConnections"
              expr  = "increase(pgbouncer_errors_count{type=\"server_connection_error\"}[5m]) > 3"
              for   = "2m"
              labels = {
                severity = "warning"
                category = "pool_health"
              }
              annotations = {
                summary = "Unhealthy pool connections detected"
                description = "{{ $value }} server connection errors in the last 5 minutes"
              }
            }
          ]
        }
      ]
    })
  }
}

# Recording rules for aggregated metrics
resource "kubernetes_config_map" "prometheus_recording_rules" {
  metadata {
    name      = "prometheus-recording-rules"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "recording_rules.yml" = yamlencode({
      groups = [
        {
          name = "connection_pool_metrics"
          rules = [
            {
              record = "pgbouncer:connection_utilization:ratio5m"
              expr = "sum(rate(pgbouncer_pools_client_active_connections[5m])) by (database) / sum(pgbouncer_pools_client_maxwait) by (database)"
            },
            {
              record = "pgbouncer:waiting_queries:rate5m"
              expr = "rate(pgbouncer_pools_client_waiting_connections[5m])"
            },
            {
              record = "pgbouncer:query_latency:avg5m"
              expr = "rate(pgbouncer_pools_server_maxwait_seconds[5m])"
            }
          ]
        }
      ]
    })
  }
}

# Alert manager configuration
resource "kubernetes_config_map" "alertmanager_config" {
  metadata {
    name      = "alertmanager-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "alertmanager.yml" = yamlencode({
      global = {
        resolve_timeout = "5m"
        slack_api_url   = var.slack_webhook_url
      }
      
      route = {
        receiver = "slack-notifications"
        group_by = ["alertname", "category"]
        group_wait = "30s"
        group_interval = "5m"
        repeat_interval = "4h"
        
        routes = [
          {
            receiver = "slack-critical"
            match = {
              severity = "critical"
            }
            group_wait = "30s"
            repeat_interval = "1h"
          },
          {
            receiver = "slack-warnings"
            match = {
              severity = "warning"
            }
            group_wait = "1m"
            repeat_interval = "4h"
          }
        ]
      }
      
      receivers = [
        {
          name = "slack-critical"
          slack_configs = [{
            channel = "#datalake-alerts-critical"
            title = "{{ .GroupLabels.alertname }}"
            text = "{{ .CommonAnnotations.description }}\n{{ .CommonAnnotations.runbook_url }}"
            send_resolved = true
          }]
        },
        {
          name = "slack-warnings"
          slack_configs = [{
            channel = "#datalake-alerts"
            title = "{{ .GroupLabels.alertname }}"
            text = "{{ .CommonAnnotations.description }}"
            send_resolved = true
          }]
        }
      ]
    })
  }
}