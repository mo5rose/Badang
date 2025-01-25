# modules/system/offline_config.tf
resource "kubernetes_config_map" "offline_config" {
  metadata {
    name = "offline-config"
    namespace = kubernetes_namespace.datalake.metadata[0].name
  }

  data = {
    "offline.conf" = <<-EOT
      # Proxy Configuration
      no_proxy=".internal,.company.local,${var.internal_network_cidr}"
      
      # Internal DNS resolvers
      nameserver=${var.internal_dns_server}
      search_domains="company.local internal"
      
      # Internal NTP servers
      ntp_servers="${join(" ", var.internal_ntp_servers)}"
      
      # Certificate Authority
      custom_ca_certificates="/etc/ssl/certs/company-ca.crt"
    EOT
  }
}

# Trust internal CA certificates
resource "kubernetes_config_map" "ca_certificates" {
  metadata {
    name = "ca-certificates"
    namespace = kubernetes_namespace.datalake.metadata[0].name
  }

  data = {
    "company-ca.crt" = file("${path.module}/certs/company-ca.crt")
  }
}