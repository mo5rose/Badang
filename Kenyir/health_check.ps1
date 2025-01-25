# health_check.ps1
function Test-Component {
    param (
        [string]$namespace,
        [string]$service,
        [int]$port,
        [string]$endpoint
    )
    
    Write-Host "Checking $service in namespace $namespace..."
    
    $serviceIP = kubectl get svc $service -n $namespace -o jsonpath='{.spec.clusterIP}'
    
    try {
        $response = Invoke-WebRequest -Uri "http://${serviceIP}:${port}${endpoint}" -TimeoutSec 5
        if ($response.StatusCode -ne 200) {
            throw "Health check failed for $service"
        }
    }
    catch {
        Write-Error "Health check failed for $service: $_"
        return $false
    }
    return $true
}

try {
    # MinIO health check
    Test-Component -namespace "storage" -service "minio" -port 9000 -endpoint "/minio/health/live"
    
    # PostgreSQL health check
    $pgHost = kubectl get svc postgres -n database -o jsonpath='{.spec.clusterIP}'
    $env:PGPASSWORD = $config.DB_PASSWORD
    $query = "SELECT 1;"
    $result = psql -h $pgHost -U $config.DB_USER -d $config.DB_NAME -c $query
    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL health check failed"
    }
    
    # PgBouncer health check
    $pgBouncerHost = kubectl get svc pgbouncer -n database -o jsonpath='{.spec.clusterIP}'
    $env:PGPASSWORD = $config.PGBOUNCER_PASSWORD
    $query = "SHOW DATABASES;"
    $result = psql -h $pgBouncerHost -p 6432 -U $config.PGBOUNCER_USER -d pgbouncer -c $query
    if ($LASTEXITCODE -ne 0) {
        throw "PgBouncer health check failed"
    }
    
    # Component health checks
    Test-Component -namespace "processing" -service "spark-master" -port 8080 -endpoint "/health"
    Test-Component -namespace "query-engine" -service "trino" -port 8080 -endpoint "/v1/info"
    Test-Component -namespace "monitoring" -service "prometheus" -port 9090 -endpoint "/-/healthy"
    Test-Component -namespace "monitoring" -service "grafana" -port 3000 -endpoint "/api/health"
    
    Write-Host "All health checks passed" -ForegroundColor Green
}
catch {
    Write-Error "Health checks failed: $_"
    exit 1
}