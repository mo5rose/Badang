# main-orchestrator.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Development", "Testing", "Production")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = ".\config\$Environment.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPrerequisites
)

# Import all required modules
$requiredScripts = @(
    ".\deployment-strategy.ps1",
    ".\deploy.ps1",
    ".\deploy-environment.ps1",
    ".\environment-check.ps1",
    ".\setup-linux-components.ps1"
)

foreach ($script in $requiredScripts) {
    if (Test-Path $script) {
        . $script
    } else {
        throw "Required script not found: $script"
    }
}

function Start-DataLakeDeployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$DeploymentParams
    )
    
    try {
        # 1. Validate Strategy
        $strategy = Get-DeploymentStrategy -Environment $DeploymentParams.Environment
        if (-not $strategy.Validated) {
            throw "Invalid deployment strategy for environment: $($DeploymentParams.Environment)"
        }

        # 2. Check Prerequisites
        if (-not $SkipPrerequisites) {
            $prerequisites = Test-SystemRequirements
            if (-not $prerequisites) {
                throw "System prerequisites not met"
            }
        }

        # 3. Initialize Environment
        $envParams = @{
            Environment = $DeploymentParams.Environment
            Location = $DeploymentParams.Location
            ConfigPath = $DeploymentParams.ConfigPath
        }
        
        $initialized = Initialize-Environment @envParams
        if (-not $initialized) {
            throw "Environment initialization failed"
        }

        # 4. Setup Linux Components
        Install-LinuxComponents -Environment $DeploymentParams.Environment

        # 5. Deploy Core Infrastructure
        $infraParams = @{
            ResourceGroupName = "datalake-$($DeploymentParams.Environment.ToLower())"
            Location = $DeploymentParams.Location
            Environment = $DeploymentParams.Environment
        }
        
        Deploy-CoreInfrastructure @infraParams

        # 6. Configure Environment-Specific Settings
        $envConfig = @{
            Environment = $DeploymentParams.Environment
            ResourceGroupName = $infraParams.ResourceGroupName
            Location = $DeploymentParams.Location
        }
        
        Set-EnvironmentConfiguration @envConfig

        # 7. Validate Deployment
        $validation = Test-Deployment @envConfig
        if (-not $validation.Success) {
            throw "Deployment validation failed: $($validation.Errors)"
        }

        return @{
            Success = $true
            ResourceGroup = $infraParams.ResourceGroupName
            Environment = $DeploymentParams.Environment
            Timestamp = Get-Date
        }
    }
    catch {
        Write-Error "Deployment failed: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
            Stage = $_.InvocationInfo.ScriptLineNumber
            Timestamp = Get-Date
        }
    }
}

# Configuration validation
function Test-Configuration {
    param($ConfigPath)
    
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }
    
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    
    # Add configuration validation logic here
    return $true
}

# Deployment validation
function Test-Deployment {
    param(
        [string]$Environment,
        [string]$ResourceGroupName,
        [string]$Location
    )
    
    $tests = @{
        ResourceGroup = Test-AzResourceGroup -Name $ResourceGroupName
        Storage = Test-StorageAccounts -ResourceGroupName $ResourceGroupName
        Processing = Test-ProcessingServices -ResourceGroupName $ResourceGroupName
        WSL = Test-WSLConfiguration
        Linux = Test-LinuxComponents -Environment $Environment
    }
    
    $success = $tests.Values | Where-Object { -not $_ } | Measure-Object | Select-Object -ExpandProperty Count -eq 0
    
    return @{
        Success = $success
        Tests = $tests
        Timestamp = Get-Date
    }
}

# Main execution
try {
    $deploymentParams = @{
        Environment = $Environment
        Location = $Location
        ConfigPath = $ConfigPath
    }
    
    # Validate configuration
    Test-Configuration -ConfigPath $ConfigPath
    
    # Start deployment
    $result = Start-DataLakeDeployment -DeploymentParams $deploymentParams
    
    if ($result.Success) {
        Write-Host "Deployment completed successfully!" -ForegroundColor Green
        $result | ConvertTo-Json | Out-File ".\deployment-result.json"
    } else {
        Write-Error "Deployment failed. See deployment-result.json for details"
        $result | ConvertTo-Json | Out-File ".\deployment-result.json"
        exit 1
    }
}
catch {
    Write-Error "Critical error during deployment: $_"
    exit 1
}