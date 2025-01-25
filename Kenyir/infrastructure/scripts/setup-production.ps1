# infrastructure/scripts/setup-production.ps1
# Production Server Setup Script

# Install Windows Features
$features = @(
    "Containers",
    "Hyper-V",
    "Hyper-V-PowerShell"
)

foreach ($feature in $features) {
    Install-WindowsFeature -Name $feature -IncludeManagementTools
}

# Install Chocolatey and Required Software
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install -y `
    docker-desktop `
    aws-cli `
    azure-cli `
    kubernetes-cli `
    prometheus-windows-exporter `
    nssm

# Configure Docker
$dockerConfig = @{
    "experimental" = $true
    "metrics-addr" = "0.0.0.0:9323"
    "dns" = @("8.8.8.8", "8.8.4.4")
    "log-driver" = "json-file"
    "log-opts" = @{
        "max-size" = "10m"
        "max-file" = "3"
    }
}

$dockerConfig | ConvertTo-Json | Set-Content "C:\ProgramData\Docker\config\daemon.json"

# Configure Windows Firewall
$firewallRules = @{
    "Docker" = 2375
    "Prometheus" = 9090
    "Grafana" = 3000
    "MinIO" = 9000
    "Trino" = 8080
    "Spark" = 7077
    "Airflow" = 8082
}

foreach ($rule in $firewallRules.GetEnumerator()) {
    New-NetFirewallRule -DisplayName $rule.Key -Direction Inbound -Action Allow -Protocol TCP -LocalPort $rule.Value
}