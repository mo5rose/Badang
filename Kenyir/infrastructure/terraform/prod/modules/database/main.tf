# modules/database/main.tf
resource "aws_rds_cluster" "metadata" {
  cluster_identifier     = "datalake-${var.environment}"
  engine                = "aurora-postgresql"
  engine_version        = "13.7"
  database_name         = "datalake"
  master_username       = "datalake_admin"
  master_password       = random_password.db_password.result
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  skip_final_snapshot    = false
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name
  
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 16
  }
}

resource "aws_rds_cluster_instance" "metadata" {
  count               = 2
  identifier          = "datalake-${var.environment}-${count.index + 1}"
  cluster_identifier  = aws_rds_cluster.metadata.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.metadata.engine
  engine_version      = aws_rds_cluster.metadata.engine_version
}