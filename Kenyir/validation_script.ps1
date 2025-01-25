# validation_script.ps1
function Test-ChocolateyInstallation {
    [CmdletBinding()]
    param(
        [switch]$InstallIfMissing
    )
    
    Write-ValidationLog "Checking Chocolatey installation..."
    
    try {
        $choco = Get-Command choco -ErrorAction Stop
        $chocoVersion = (choco --version)
        
        return [ValidationResult]::new(
            "Chocolatey",
            $true,
            $chocoVersion,
            "Required",
            "",
            @()
        )
    }
    catch {
        $fixSteps = @(
            "Run PowerShell as Administrator",
            "Execute: Set-ExecutionPolicy Bypass -Scope Process -Force",
            "Execute: [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072",
            "Execute: iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
        )
        
        $result = [ValidationResult]::new(
            "Chocolatey",
            $false,
            "Not Installed",
            "Required",
            "Chocolatey package manager is not installed",
            $fixSteps
        )
        
        if ($InstallIfMissing) {
            Write-ValidationLog "Attempting to install Chocolatey..."
            try {
                # Check if running as administrator
                $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                
                if (-not $isAdmin) {
                    Write-ValidationLog "Administrator privileges required for Chocolatey installation"
                    $result.Error = "Administrator privileges required for installation"
                    return $result
                }
                
                # Install Chocolatey
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
                
                # Verify installation
                $choco = Get-Command choco -ErrorAction Stop
                $chocoVersion = (choco --version)
                
                Write-ValidationLog "Chocolatey installed successfully: version $chocoVersion"
                
                return [ValidationResult]::new(
                    "Chocolatey",
                    $true,
                    $chocoVersion,
                    "Required",
                    "",
                    @()
                )
            }
            catch {
                Write-ValidationLog "Failed to install Chocolatey: $_"
                $result.Error = "Installation failed: $_"
                return $result
            }
        }
        
        return $result
    }
}

function Install-RequiredComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComponentName,
        [string]$ChocoPackage,
        [string]$ManualInstallUrl,
        [string[]]$AlternativeSteps
    )
    
    Write-ValidationLog "Attempting to install $ComponentName..."
    
    # First, check if Chocolatey is available
    $chocoResult = Test-ChocolateyInstallation
    
    if ($chocoResult.Status) {
        try {
            Write-ValidationLog "Installing $ComponentName using Chocolatey..."
            choco install $ChocoPackage -y
            return $true
        }
        catch {
            Write-ValidationLog "Chocolatey installation failed: $_"
        }
    }
    
    # If Chocolatey installation failed or not available, provide manual instructions
    Write-Host "`nUnable to automatically install $ComponentName. Please follow these manual installation steps:" -ForegroundColor Yellow
    Write-Host "`n1. Download from: $ManualInstallUrl" -ForegroundColor Cyan
    
    foreach ($step in $AlternativeSteps) {
        Write-Host $step -ForegroundColor Cyan
    }
    
    $proceed = Read-Host "`nWould you like to proceed with manual installation now? (Y/N)"
    
    if ($proceed -eq 'Y') {
        Start-Process $ManualInstallUrl
        Write-Host "Please complete the installation and press Enter when done..."
        Read-Host
        
        # Verify installation
        try {
            $verifyCommand = switch ($ComponentName) {
                "Docker" { "docker --version" }
                "Kubectl" { "kubectl version --client" }
                "Helm" { "helm version" }
                default { throw "Unknown component: $ComponentName" }
            }
            
            Invoke-Expression $verifyCommand
            Write-ValidationLog "$ComponentName installation verified"
            return $true
        }
        catch {
            Write-ValidationLog "$ComponentName installation verification failed: $_"
            return $false
        }
    }
    
    return $false
}

# validation_script.ps1
[CmdletBinding()]
param(
    [switch]$FixIssues,
    [switch]$GenerateReport
)

class ValidationResult {
    [string]$Component
    [bool]$Status
    [string]$CurrentVersion
    [string]$RequiredVersion
    [string]$Error
    [string[]]$FixSteps
    
    ValidationResult(
        [string]$component,
        [bool]$status,
        [string]$currentVersion,
        [string]$requiredVersion,
        [string]$error,
        [string[]]$fixSteps
    ) {
        $this.Component = $component
        $this.Status = $status
        $this.CurrentVersion = $currentVersion
        $this.RequiredVersion = $requiredVersion
        $this.Error = $error
        $this.FixSteps = $fixSteps
    }
}

function Test-Prerequisites {
    [CmdletBinding()]
    param()
    
    $results = @()
    
    # First, check Chocolatey
    $chocoResult = Test-ChocolateyInstallation -InstallIfMissing:$FixIssues
    $results += $chocoResult
    
    # Initialize log file
    $logFile = "validation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    function Write-ValidationLog {
        param([string]$Message)
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Tee-Object -FilePath $logFile -Append
    }

    function Test-DockerInstallation {
        try {
            $dockerVersion = (docker --version) -split " " | Select-Object -Index 2
            $dockerVersion = $dockerVersion.Substring(0, $dockerVersion.LastIndexOf("."))
            $requiredVersion = "20.10"
            
            $status = [version]$dockerVersion -ge [version]$requiredVersion
            
            $fixSteps = @(
                "Download Docker Desktop from https://www.docker.com/products/docker-desktop",
                "Run the installer with administrative privileges",
                "Ensure Hyper-V and WSL2 are enabled",
                "Add current user to docker-users group"
            )
            
            $results += [ValidationResult]::new(
                "Docker",
                $status,
                $dockerVersion,
                $requiredVersion,
                $(if(-not $status){"Docker version is below required version"}else{""}),
                $fixSteps
            )
            
            if ($FixIssues -and -not $status) {
                $dockerInstall = Install-RequiredComponent -ComponentName "Docker" `
                    -ChocoPackage "docker-desktop" `
                    -ManualInstallUrl "https://www.docker.com/products/docker-desktop" `
                    -AlternativeSteps @(
                        "2. Run the installer with administrative privileges",
                        "3. Ensure Hyper-V and WSL2 are enabled",
                        "4. Restart your computer after installation",
                        "5. Add your user to the docker-users group"
                    )
                
                if ($dockerInstall) {
                    # Recheck version after installation
                    return Test-DockerInstallation
                }
            }
        }
        catch {
            $results += [ValidationResult]::new(
                "Docker",
                $false,
                "Not Installed",
                $requiredVersion,
                $_.Exception.Message,
                $fixSteps
            )
        }
    }

    function Test-KubernetesTools {
        try {
            $kubectlVersion = (kubectl version --client -o json | ConvertFrom-Json).clientVersion.gitVersion
            $kubectlVersion = $kubectlVersion.Substring(1, $kubectlVersion.IndexOf(".", 1))
            $requiredVersion = "1.24"
            
            $status = [version]$kubectlVersion -ge [version]$requiredVersion
            
            $fixSteps = @(
                "Install kubectl using: choco install kubernetes-cli",
                "Or download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/",
                "Add kubectl to PATH environment variable"
            )
            
            $results += [ValidationResult]::new(
                "Kubectl",
                $status,
                $kubectlVersion,
                $requiredVersion,
                $(if(-not $status){"Kubectl version is below required version"}else{""}),
                $fixSteps
            )
            
            if ($FixIssues -and -not $status) {
                $kubectlInstall = Install-RequiredComponent -ComponentName "Kubectl" `
                    -ChocoPackage "kubernetes-cli" `
                    -ManualInstallUrl "https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/" `
                    -AlternativeSteps @(
                        "2. Download the latest kubectl.exe",
                        "3. Add kubectl.exe to your PATH environment variable",
                        "4. Open a new PowerShell window after installation"
                    )
                
                if ($kubectlInstall) {
                    # Recheck version after installation
                    return Test-KubernetesTools
                }
            }
        }
        catch {
            $results += [ValidationResult]::new(
                "Kubectl",
                $false,
                "Not Installed",
                $requiredVersion,
                $_.Exception.Message,
                $fixSteps
            )
        }
    }

    function Test-HelmInstallation {
        try {
            $helmVersion = (helm version --template="{{.Version}}").Substring(1, 3)
            $requiredVersion = "3.8"
            
            $status = [version]$helmVersion -ge [version]$requiredVersion
            
            $fixSteps = @(
                "Install Helm using: choco install kubernetes-helm",
                "Or download from: https://helm.sh/docs/intro/install/",
                "Add helm to PATH environment variable"
            )
            
            $results += [ValidationResult]::new(
                "Helm",
                $status,
                $helmVersion,
                $requiredVersion,
                $(if(-not $status){"Helm version is below required version"}else{""}),
                $fixSteps
            )
            
            if ($FixIssues -and -not $status) {
                Write-ValidationLog "Attempting to fix Helm installation..."
                if (Get-Command choco -ErrorAction SilentlyContinue) {
                    choco install kubernetes-helm -y
                }
            }
        }
        catch {
            $results += [ValidationResult]::new(
                "Helm",
                $false,
                "Not Installed",
                $requiredVersion,
                $_.Exception.Message,
                $fixSteps
            )
        }
    }

    function Test-SystemRequirements {
        try {
            # Check Windows version
            $osInfo = Get-CimInstance Win32_OperatingSystem
            $windowsVersion = [version]$osInfo.Version
            $requiredVersion = [version]"10.0.19044"
            
            $status = $windowsVersion -ge $requiredVersion
            
            $fixSteps = @(
                "Update Windows to latest version",
                "Enable Windows features: Hyper-V, Containers, WSL2",
                "Restart system after enabling features"
            )
            
            $results += [ValidationResult]::new(
                "Windows",
                $status,
                $windowsVersion.ToString(),
                $requiredVersion.ToString(),
                $(if(-not $status){"Windows version is below required version"}else{""}),
                $fixSteps
            )
            
            # Check available memory
            $memory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
            $requiredMemory = 16
            
            $memoryStatus = $memory -ge $requiredMemory
            
            $results += [ValidationResult]::new(
                "Memory",
                $memoryStatus,
                "$([math]::Round($memory, 2)) GB",
                "$requiredMemory GB",
                $(if(-not $memoryStatus){"Insufficient memory"}else{""}),
                @("Upgrade system memory to at least $requiredMemory GB")
            )
        }
        catch {
            $results += [ValidationResult]::new(
                "System",
                $false,
                "Unknown",
                "Windows 10/11 Pro",
                $_.Exception.Message,
                $fixSteps
            )
        }
    }

    # Run all validation checks
    Write-ValidationLog "Starting validation checks..."
    
    Test-SystemRequirements
    Test-DockerInstallation
    Test-KubernetesTools
    Test-HelmInstallation
    
    # Generate detailed report
    if ($GenerateReport) {
        $reportPath = "validation_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        $report = @"
        <!DOCTYPE html>
        <html>
        <head>
            <title>Validation Report</title>
            <style>
                body { font-family: Arial, sans-serif; padding: 20px; }
                .success { color: green; }
                .failure { color: red; }
                .component { margin-bottom: 20px; padding: 10px; border: 1px solid #ddd; }
                .fix-steps { margin-left: 20px; color: #666; }
            </style>
        </head>
        <body>
            <h1>Validation Report</h1>
            <p>Generated: $(Get-Date)</p>
"@

        foreach ($result in $results) {
            $statusClass = if ($result.Status) { "success" } else { "failure" }
            $report += @"
            <div class="component">
                <h2>$($result.Component)</h2>
                <p>Status: <span class="$statusClass">$($result.Status)</span></p>
                <p>Current Version: $($result.CurrentVersion)</p>
                <p>Required Version: $($result.RequiredVersion)</p>
"@

            if (-not $result.Status) {
                $report += @"
                <p>Error: $($result.Error)</p>
                <div class="fix-steps">
                    <h3>Fix Steps:</h3>
                    <ul>
"@
                foreach ($step in $result.FixSteps) {
                    $report += "<li>$step</li>"
                }
                $report += @"
                    </ul>
                </div>
"@
            }

            $report += "</div>"
        }

        $report += @"
        </body>
        </html>
"@

        $report | Out-File -FilePath $reportPath
        Write-ValidationLog "Validation report generated: $reportPath"
    }

    # Return results
    $overallSuccess = $results | Where-Object { -not $_.Status } | Measure-Object | Select-Object -ExpandProperty Count -eq 0
    
    if (-not $overallSuccess) {
        Write-ValidationLog "Validation failed. See report for details."
        throw "Prerequisites validation failed. Check validation_report_*.html for details."
    }
    
    Write-ValidationLog "Validation completed successfully."
    return $overallSuccess
}

# Execute validation with parameters
try {
    Test-Prerequisites -ErrorAction Stop
}
catch {
    Write-Error "Validation failed: $_"
    
    # Prompt for fix attempt
    if (-not $FixIssues) {
        $fix = Read-Host "Would you like to attempt to fix the issues? (Y/N)"
        if ($fix -eq 'Y') {
            Test-Prerequisites -FixIssues -GenerateReport
        }
    }
    
    exit 1
}