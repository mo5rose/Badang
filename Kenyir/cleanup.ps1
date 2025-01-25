# cleanup.ps1
Write-Host "Starting cleanup..." -ForegroundColor Yellow

try {
    # Delete applications in reverse order
    kubectl delete -f .\kubernetes\monitoring\ --grace-period=30
    kubectl delete -f .\kubernetes\query-engine\ --grace-period=30
    kubectl delete -f .\kubernetes\processing\ --grace-period=30
    kubectl delete -f .\kubernetes\database\ --grace-period=30
    kubectl delete -f .\kubernetes\storage\ --grace-period=30
    
    # Delete security policies
    kubectl delete -f .\kubernetes\security\
    
    # Delete namespaces
    kubectl delete -f .\kubernetes\namespaces\
    
    Write-Host "Cleanup complete" -ForegroundColor Green
}
catch {
    Write-Error "Cleanup failed: $_"
    exit 1
}