# deploy.ps1
# Import configuration
. .\config.ps1

function Wait-ForPods {
    param (
        [string]$namespace,
        [string]$label,
        [int]$timeout
    )
    
    Write-Host "Waiting for pods in namespace $namespace with label $label"
    kubectl wait --for=condition=ready pod -l app=$label -n $namespace --timeout=${timeout}s
    if ($LASTEXITCODE -ne 0) {
        throw "Timeout waiting for pods in namespace $namespace with label $label"
    }
}

function Test-Deployment {
    param (
        [string]$namespace,
        [string]$deployment
    )
    
    $replicas = kubectl get deployment $deployment -n $namespace -o jsonpath='{.status.replicas}'
    $ready = kubectl get deployment $deployment -n $namespace -o jsonpath='{.status.readyReplicas}'
    
    if ($replicas -ne $ready) {
        Write-Error "Deployment $deployment in $namespace not ready. Expected: $replicas, Ready: $ready"
        return $false
    }
    return $true
}

try {
    # Create namespaces
    Write-Host "Creating namespaces..." -ForegroundColor Cyan
    kubectl apply -f .\kubernetes\namespaces\
    
    # Apply security policies
    Write-Host "Applying security policies..." -ForegroundColor Cyan
    kubectl apply -f .\kubernetes\security\
    
    # Setup storage
    Write-Host "Setting up storage components..." -ForegroundColor Cyan
    kubectl apply -f .\kubernetes\storage\
    Wait-ForPods -namespace "storage" -label "minio" -timeout 300
    
    # Deploy database components
    Write-Host "Deploying database components..." -ForegroundColor Cyan
    kubectl apply -f .\kubernetes\database\
    Wait-ForPods -namespace "database" -label "postgres" -timeout 300
    Wait-ForPods -namespace "database" -label "pgbouncer" -timeout 300
    
    # Deploy processing components
    Write-Host "Deploying processing components..." -ForegroundColor Cyan
    kubectl apply -f .\kubernetes\processing\
    Wait-ForPods -namespace "processing" -label "spark-master" -timeout 300
    Wait-ForPods -namespace "processing" -label "spark-worker" -timeout 300
    
    # Deploy query engine
    Write-Host "Deploying query engine..." -ForegroundColor Cyan
    kubectl apply -f .\kubernetes\query-engine\
    Wait-ForPods -namespace "query-engine" -label "trino" -timeout 300
    
    # Setup monitoring
    Write-Host "Setting up monitoring..." -ForegroundColor Cyan
    kubectl apply -f .\kubernetes\monitoring\
    Wait-ForPods -namespace "monitoring" -label "prometheus" -timeout 300
    Wait-ForPods -namespace "monitoring" -label "grafana" -timeout 300
    
    # Validate deployments
    Write-Host "Validating deployments..." -ForegroundColor Cyan
    $deployments = @("minio", "postgres", "pgbouncer", "spark-master", "trino", "prometheus", "grafana")
    foreach ($deployment in $deployments) {
        $namespace = kubectl get deployment $deployment -o jsonpath='{.metadata.namespace}'
        if (-not (Test-Deployment -namespace $namespace -deployment $deployment)) {
            throw "Deployment validation failed for $deployment"
        }
    }
    
    Write-Host "Deployment complete. Running health checks..." -ForegroundColor Green
    
    # Run health checks
    . .\health_check.ps1
    
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}