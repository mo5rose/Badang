resource "kubernetes_network_policy" "pgbouncer" {
  metadata {
    name      = "pgbouncer-network-policy"
    namespace = kubernetes_namespace.datalake.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "pgbouncer"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.datalake.metadata[0].name
          }
        }
        pod_selector {
          match_labels = {
            role = "database-client"
          }
        }
      }

      ports {
        port     = 6432
        protocol = "TCP"
      }

      ports {
        port     = 9127
        protocol = "TCP"
      }
    }

    egress {
      to {
        ip_block {
          cidr = var.database_subnet_cidr
        }
      }
      ports {
        port     = 5432
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy" "default_deny" {
  metadata {
    name      = "default-deny"
    namespace = kubernetes_namespace.datalake.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# Network Security Groups for Database Subnet
resource "aws_security_group" "database" {
  name        = "database-${var.environment}"
  description = "Security group for database connections"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [var.kubernetes_subnet_cidr]
    description = "PostgreSQL access from Kubernetes nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.kubernetes_subnet_cidr]
    description = "Return traffic to Kubernetes nodes"
  }

  tags = {
    Name        = "database-${var.environment}"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Service Monitor for PgBouncer
resource "kubernetes_manifest" "pgbouncer_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "pgbouncer"
      namespace = kubernetes_namespace.datalake.metadata[0].name
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "pgbouncer"
        }
      }
      endpoints = [
        {
          port   = "metrics"
          path   = "/metrics"
          interval = "30s"
          scrapeTimeout = "10s"
        }
      ]
    }
  }
}

# TLS Certificate for PgBouncer
resource "kubernetes_secret" "pgbouncer_tls" {
  metadata {
    name      = "pgbouncer-tls"
    namespace = kubernetes_namespace.datalake.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = var.pgbouncer_tls_cert
    "tls.key" = var.pgbouncer_tls_key
    "ca.crt"  = var.pgbouncer_ca_cert
  }
}

# Additional security controls
resource "kubernetes_pod_security_policy" "restricted" {
  metadata {
    name = "restricted-psp"
  }

  spec {
    privileged                 = false
    allow_privilege_escalation = false
    
    required_drop_capabilities = ["ALL"]

    volumes = [
      "configMap",
      "emptyDir",
      "projected",
      "secret",
      "downwardAPI",
      "persistentVolumeClaim",
    ]

    run_as_user {
      rule = "MustRunAsNonRoot"
    }

    se_linux {
      rule = "RunAsAny"
    }

    supplemental_groups {
      rule = "MustRunAs"
      ranges {
        min = 1
        max = 65535
      }
    }

    fs_group {
      rule = "MustRunAs"
      ranges {
        min = 1
        max = 65535
      }
    }

    read_only_root_filesystem = true
  }
}