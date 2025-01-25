# modules/monitoring/prometheus_setup.tf

resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-server"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "9090"
    }
  }

  spec {
    selector = {
      app = "prometheus"
    }
    port {
      port        = 9090
      target_port = 9090
    }
  }
}

# Configure Prometheus scrape configs
resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "prometheus.yml" = yamlencode({
      global = {
        scrape_interval     = "15s"
        evaluation_interval = "15s"
      }
      scrape_configs = [
        {
          job_name = "datalake-metrics"
          kubernetes_sd_configs = [{
            role = "pod"
          }]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
              action       = "keep"
              regex        = true
            },
            {
              source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
              action       = "replace"
              target_label = "__metrics_path__"
              regex        = "(.+)"
            }
          ]
        }
      ]
    })
  }
}