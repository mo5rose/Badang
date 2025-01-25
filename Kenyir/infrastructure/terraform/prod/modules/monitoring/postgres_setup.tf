# modules/monitoring/postgres_setup.tf

# Create read-only user for Grafana
resource "postgresql_role" "grafana_reader" {
  name     = "grafana_reader"
  login    = true
  password = random_password.grafana_db_password.result

  depends_on = [aws_rds_cluster.metadata]
}

resource "postgresql_grant" "grafana_reader" {
  database    = "datalake"
  role        = postgresql_role.grafana_reader.name
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]
}

# Create connection pool for Grafana
resource "postgresql_grant" "grafana_pool" {
  database    = "datalake"
  role        = postgresql_role.grafana_reader.name
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]

  connection_pooling {
    pool_size          = 10
    pool_mode         = "transaction"
    max_client_conn   = 100
    default_pool_size = 20
  }
}