# config.ps1
# Configuration settings
$config = @{
    # Database Configuration
    DB_USER = "datalake"
    DB_PASSWORD = "secure_password"
    DB_NAME = "datalake"
    
    # PgBouncer Configuration
    PGBOUNCER_USER = "pgbouncer"
    PGBOUNCER_PASSWORD = "secure_password"
    
    # Storage Configuration
    MINIO_ROOT_USER = "minio"
    MINIO_ROOT_PASSWORD = "secure_password"
    
    # Monitoring Configuration
    GRAFANA_ADMIN_PASSWORD = "secure_password"
}