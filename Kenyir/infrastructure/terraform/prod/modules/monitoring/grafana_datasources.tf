# modules/monitoring/grafana_datasources.tf

# Grafana data sources configuration
resource "kubernetes_config_map" "grafana_datasources" {
  metadata {
    name      = "grafana-datasources"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_datasource = "true"
    }
  }

  data = {
    "datasources.yaml" = yamlencode({
      apiVersion  = 1
      datasources = [
        {
          name      = "Prometheus"
          type      = "prometheus"
          access    = "proxy"
          url       = "http://prometheus-server.monitoring.svc.cluster.local:9090"
          isDefault = true
          version   = 1
          editable  = true
          jsonData = {
            timeInterval            = "30s"
            queryTimeout           = "60s"
            httpMethod            = "POST"
            manageAlerts          = true
            prometheusType        = "Prometheus"
            prometheusVersion     = "2.40.0"
          }
        },
        {
          name      = "CloudWatch"
          type      = "cloudwatch"
          access    = "proxy"
          jsonData = {
            authType      = "default"
            defaultRegion = var.aws_region
            customMetricsNamespaces = "DataLake"
          }
          secureJsonData = {
            accessKey = var.cloudwatch_access_key
            secretKey = var.cloudwatch_secret_key
          }
        },
        {
          name      = "PostgreSQL"
          type      = "postgres"
          url       = "${aws_rds_cluster.metadata.endpoint}:5432"
          database  = "datalake"
          user      = "grafana_reader"
          secureJsonData = {
            password = random_password.grafana_db_password.result
          }
          jsonData = {
            sslmode         = "require"
            maxOpenConns    = 100
            maxIdleConns    = 100
            connMaxLifetime = 14400
            postgresVersion = 1300
          }
        }
      ]
    })
  }
}

# Grafana configuration for data source provisioning
resource "helm_release" "grafana" {
  # ... other configuration ...

  values = [
    yamlencode({
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name = "Prometheus"
              type = "prometheus"
              url  = "http://prometheus-server.monitoring.svc.cluster.local:9090"
              access = "proxy"
              isDefault = true
            },
            {
              name = "CloudWatch"
              type = "cloudwatch"
              jsonData = {
                authType      = "default"
                defaultRegion = var.aws_region
              }
            }
          ]
        }
      }
    })
  ]
}