# environment-check.ps1
function Test-SystemRequirements {
    [CmdletBinding()]
    param()
    
    $requirements = @{
        WSL = @{
            Required = $true
            Version = "2"
            Components = @(
                "Ubuntu 22.04"
                "Python environment"
                "Hadoop components"
            )
        }
        Linux = @{
            Tools = @(
                "Apache Spark"
                "Apache Hive"
                "Apache NiFi"
                "Apache Kafka"
                "Python data tools"
            )
            Configurations = @(
                "HDFS settings"
                "YARN configurations"
                "Spark defaults"
            )
        }
    }

    # Check WSL installation
    $wslStatus = wsl --status 2>$null
    $wslInstalled = $LASTEXITCODE -eq 0
    
    if (-not $wslInstalled) {
        Write-Host "WSL is not installed. Installing WSL..." -ForegroundColor Yellow
        wsl --install -d Ubuntu-22.04
        Write-Host "Please restart your computer after WSL installation." -ForegroundColor Yellow
        return $false
    }

    return $true
}
