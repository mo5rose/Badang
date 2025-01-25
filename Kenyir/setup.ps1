$setupScript = @'
# Enable Windows features
Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install required software
choco install -y `
    vscode `
    git `
    docker-desktop `
    python `
    nodejs `
    azure-cli `
    aws-cli `
    kubernetes-cli

# Install WSL2
wsl --install -d Ubuntu
'@

# Save and execute script
$setupScript | Out-File -FilePath setup.ps1 -Encoding UTF8
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup.ps1