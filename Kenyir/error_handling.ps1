# error_handling.ps1
class DeploymentError {
    [string]$Component
    [string]$Error
    [string]$Status
    [datetime]$Timestamp
    
    DeploymentError([string]$component, [string]$error) {
        $this.Component = $component
        $this.Error = $error
        $this.Status = "Failed"
        $this.Timestamp = Get-Date
    }
}

# Enhanced deploy.ps1 with error handling
function Start-SafeDeployment {
    [CmdletBinding()]
    param()
    
    # Initialize deployment log
    $deploymentLog = Join-Path $PSScriptRoot "deployment_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $errorLog = @()
    
    function Write-DeploymentLog {
        param([string]$Message)
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Tee-Object -FilePath $deploymentLog -Append
    }

    function Test-ComponentHealth {
        param (
            [string]$Component,
            [string]$Namespace,
            [int]$RetryCount = 3,
            [int]$RetryDelay = 30
        )
        
        for ($i = 1; $i -le $RetryCount; $i++) {
            try {
                Write-DeploymentLog "Attempt $i of $RetryCount: Checking $Component health..."
                
                $pods = kubectl get pods -n $Namespace -l app=$Component -o json | ConvertFrom-Json
                $readyPods = ($pods.items | Where-Object {
                    $_.status.phase -eq 'Running' -and 
                    $_.status.containerStatuses.ready -notcontains $false
                }).Count
                
                if ($readyPods -eq $pods.items.Count -and $readyPods -gt 0) {
                    Write-DeploymentLog "$Component is healthy"
                    return $true
                }
                
                if ($i -lt $RetryCount) {
                    Write-DeploymentLog "Waiting $RetryDelay seconds before next attempt..."
                    Start-Sleep -Seconds $RetryDelay
                }
            }
            catch {
                Write-DeploymentLog "Error checking $Component health: $_"
                if ($i -eq $RetryCount) {
                    throw $_
                }
                Start-Sleep -Seconds $RetryDelay
            }
        }
        return $false
    }

    function Restore-FailedDeployment {
        param (
            [string]$Component,
            [string]$Namespace
        )
        
        Write-DeploymentLog "Attempting to restore failed deployment: $Component in $Namespace"
        
        try {
            # Scale down the deployment
            kubectl scale deployment $Component -n $Namespace --replicas=0
            Start-Sleep -Seconds 10
            
            # Scale back up
            kubectl scale deployment $Component -n $Namespace --replicas=1
            
            # Wait for recovery
            $recovered = Test-ComponentHealth -Component $Component -Namespace $Namespace -RetryCount 5
            if (-not $recovered) {
                throw "Recovery failed for $Component"
            }
            
            Write-DeploymentLog "Successfully recovered $Component"
            return $true
        }
        catch {
            Write-DeploymentLog "Recovery failed for $Component: $_"
            return $false
        }
    }

    try {
        # Validate prerequisites
        Write-DeploymentLog "Validating prerequisites..."
        if (-not (& .\validation_script.ps1)) {
            throw "Prerequisites validation failed"
        }

        # Create backup of current state
        Write-DeploymentLog "Creating deployment backup..."
        $backupDir = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -ItemType Directory -Path $backupDir
        kubectl get all --all-namespaces -o yaml > "$backupDir\cluster_backup.yaml"

        # Deploy components in sequence
        $deploymentSequence = @(
            @{Component="storage"; Namespace="storage"; Config=".\kubernetes\storage\"},
            @{Component="database"; Namespace="database"; Config=".\kubernetes\database\"},
            @{Component="processing"; Namespace="processing"; Config=".\kubernetes\processing\"},
            @{Component="query-engine"; Namespace="query-engine"; Config=".\kubernetes\query-engine\"},
            @{Component="monitoring"; Namespace="monitoring"; Config=".\kubernetes\monitoring\"}
        )

        foreach ($deployment in $deploymentSequence) {
            Write-DeploymentLog "Starting deployment of $($deployment.Component)..."
            
            try {
                # Apply configuration
                kubectl apply -f $deployment.Config
                
                # Wait for deployment
                $healthy = Test-ComponentHealth -Component $deployment.Component -Namespace $deployment.Namespace
                
                if (-not $healthy) {
                    Write-DeploymentLog "Initial deployment failed for $($deployment.Component). Attempting recovery..."
                    
                    # Attempt recovery
                    $recovered = Restore-FailedDeployment -Component $deployment.Component -Namespace $deployment.Namespace
                    
                    if (-not $recovered) {
                        $errorLog += [DeploymentError]::new($deployment.Component, "Deployment failed and recovery unsuccessful")
                        throw "Deployment failed for $($deployment.Component) and could not be recovered"
                    }
                }
            }
            catch {
                Write-DeploymentLog "Error deploying $($deployment.Component): $_"
                $errorLog += [DeploymentError]::new($deployment.Component, $_.Exception.Message)
                
                # Prompt for continuation
                $continue = Read-Host "Deployment failed for $($deployment.Component). Continue with remaining components? (Y/N)"
                if ($continue -ne 'Y') {
                    throw "Deployment aborted by user after $($deployment.Component) failure"
                }
            }
        }

        # Final health check
        if ($errorLog.Count -eq 0) {
            Write-DeploymentLog "Running final health checks..."
            $healthCheck = & .\health_check.ps1
            if (-not $healthCheck) {
                throw "Final health check failed"
            }
        }

        # Generate deployment report
        $reportPath = "deployment_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        $report