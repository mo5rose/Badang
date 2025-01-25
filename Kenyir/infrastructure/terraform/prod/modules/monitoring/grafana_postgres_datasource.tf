# modules/monitoring/grafana_postgres_datasource.tf

resource "kubernetes_config_map" "grafana_postgres_datasource" {
  metadata {
    name      = "grafana-postgres-datasource"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "postgres.yaml" = yamlencode({
      apiVersion = 1
      datasources = [{
        name = "PostgreSQL"
        type = "postgres"
        url  = "${kubernetes_service.pgbouncer.metadata[0].name}:6432"
        database = "datalake"
        user = "grafana_reader"
        secureJsonData = {
          password = random_password.grafana_db_password.result
        }
        jsonData = {
          sslmode = "disable"  # Since we're using internal k8s networking
          maxOpenConns = 50    # Should match pgbouncer default_pool_size
          maxIdleConns = 25
          connMaxLifetime = 14400
          postgresVersion = 1300
          timescaledb = false
        }
      }]
    })
  }
}