resource "kubernetes_namespace" "monitoring" {
  depends_on = [ hcloud_load_balancer_service.management_lb_k8s_service ]
  count = var.cluster_configuration.preinstall_monitoring_stack ? 1 : 0
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prom_stack" {
  depends_on = [kubernetes_namespace.monitoring, helm_release.loki, kubernetes_config_map_v1.dashboard, helm_release.tempo]

  count = var.cluster_configuration.preinstall_monitoring_stack ? 1 : 0
  name  = "prom-stack"
  # https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "45.25.0"

  namespace = "monitoring"

  values = [ file("${path.module}/templates/values/kube-prometheus-stack.yaml") ]
}

resource "helm_release" "loki" {
  depends_on = [kubernetes_namespace.monitoring]

  count = var.cluster_configuration.preinstall_monitoring_stack ? 1 : 0
  name  = "loki"
  # https://github.com/grafana/helm-charts/blob/main/charts/loki-stack/values.yaml
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.9.10"

  namespace = "monitoring"
  values = [ file("${path.module}/templates/values/loki-stack.yaml") ]
}

resource "kubernetes_ingress_v1" "monitoring_ingress" {
  depends_on = [kubernetes_namespace.monitoring]

  count = var.cluster_configuration.preinstall_monitoring_stack ? 1 : 0
  metadata {
    name      = "monitoring-ingress"
    namespace = "monitoring"
    annotations = {
      "cert-manager.io/cluster-issuer" = "cloudflare"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "grafana.hetznerdoesnot.work"
      http {
        path {
          backend {
            service {
              name = "prom-stack-grafana"
              port {
                number = 80
              }
            }
          }
          path = "/"
        }
      }
    }

    rule {
      host = "prometheus.hetznerdoesnot.work"
      http {
        path {
          backend {
            service {
              name = "prom-stack-kube-prometheus-prometheus"
              port {
                number = 9090
              }
            }
          }
          path = "/"
        }
      }
    }

    tls {
      hosts = [
        "grafana.hetznerdoesnot.work",
        "prometheus.hetznerdoesnot.work"
      ]
      secret_name = "monitoring-tls"
    }
  }
}

resource "kubernetes_config_map_v1" "dashboard" {
  depends_on = [kubernetes_namespace.monitoring]

  count = var.cluster_configuration.preinstall_monitoring_stack ? 1 : 0
  metadata {
    name      = "dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard: "1"
    }
  }

  data = {
    "dashboard.json" = file("${path.module}/templates/misc/grafana-dashboard.json")
  }
}
