# modules/monitoring/grafana_postgres_dashboard.tf

resource "kubernetes_config_map" "postgres_pool_dashboard" {
  metadata {
    name      = "postgres-pool-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "postgres-pool-dashboard.json" = jsonencode({
      annotations = {
        list = []
      }
      editable = true
      panels = [
        {
          title = "Active Connections"
          type  = "gauge"
          gridPos = {
            h = 8
            w = 8
            x = 0
            y = 0
          }
          targets = [{
            expr = "sum(pgbouncer_pools_client_active_connections)"
          }]
        },
        {
          title = "Connection Pool Utilization"
          type  = "graph"
          gridPos = {
            h = 8
            w = 16
            x = 8
            y = 0
          }
          targets = [{
            expr = "sum(pgbouncer_pools_client_active_connections) / sum(pgbouncer_pools_client_maxwait) * 100"
          }]
        },
        {
          title = "Waiting Queries"
          type  = "stat"
          gridPos = {
            h = 4
            w = 8
            x = 0
            y = 8
          }
          targets = [{
            expr = "sum(pgbouncer_pools_client_waiting_connections)"
          }]
        }
      ]
    })
  }
}