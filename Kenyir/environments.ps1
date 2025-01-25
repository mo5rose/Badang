# environments.ps1
class Environment {
    [string]$Name
    [hashtable]$Config
    [string]$KubeContext
    [string[]]$Namespaces
    
    Environment(
        [string]$name,
        [hashtable]$config,
        [string]$kubeContext,
        [string[]]$namespaces
    ) {
        $this.Name = $name
        $this.Config = $config
        $this.KubeContext = $kubeContext
        $this.Namespaces = $namespaces
    }
}

# Define environment configurations
$Environments = @{
    Development = [Environment]::new(
        "development",
        @{
            ResourceLimits = @{
                CPU = "0.5"
                Memory = "2Gi"
            }
            Storage = @{
                Class = "standard"
                Size = "10Gi"
            }
            Replicas = @{
                MinReplicas = 1
                MaxReplicas = 2
            }
            Monitoring = @{
                RetentionDays = 7
                SamplingRate = "1m"
            }
            Security = @{
                NetworkPolicy = "permissive"
                RBAC = "minimal"
            }
        },
        "datalake-dev",
        @("dev-storage", "dev-processing", "dev-analysis")
    )

    Testing = [Environment]::new(
        "testing",
        @{
            ResourceLimits = @{
                CPU = "1"
                Memory = "4Gi"
            }
            Storage = @{
                Class = "standard"
                Size = "20Gi"
            }
            Replicas = @{
                MinReplicas = 2
                MaxReplicas = 4
            }
            Monitoring = @{
                RetentionDays = 14
                SamplingRate = "30s"
            }
            Security = @{
                NetworkPolicy = "restricted"
                RBAC = "standard"
            }
        },
        "datalake-test",
        @("test-storage", "test-processing", "test-analysis")
    )

    Production = [Environment]::new(
        "production",
        @{
            ResourceLimits = @{
                CPU = "2"
                Memory = "8Gi"
            }
            Storage = @{
                Class = "premium"
                Size = "50Gi"
            }
            Replicas = @{
                MinReplicas = 3
                MaxReplicas = 8
            }
            Monitoring = @{
                RetentionDays = 30
                SamplingRate = "15s"
            }
            Security = @{
                NetworkPolicy = "strict"
                RBAC = "full"
            }
        },
        "datalake-prod",
        @("prod-storage", "prod-processing", "prod-analysis")
    )
}