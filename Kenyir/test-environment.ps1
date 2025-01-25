$testScript = @'
# Test Docker
docker --version
docker-compose --version

# Start services
docker-compose up -d

# Wait for services to be healthy
Start-Sleep -Seconds 30

# Test MinIO
curl http://localhost:9000/minio/health/live

# Test Spark
curl http://localhost:8080/

# Test Trino
curl http://localhost:8081/v1/info

# Test Airflow
curl http://localhost:8082/health

# Test PostgreSQL
$env:PGPASSWORD = "datalake123"
psql -h localhost -U datalake -d datalake -c "\dt"

# Show running containers
docker-compose ps
'@

$testScript | Out-File -FilePath test-environment.ps1 -Encoding UTF8