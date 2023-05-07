provider "helm" {
  kubernetes {
    host = local.cluster_host

    client_certificate     = local.client_cert
    client_key             = local.client_key
    cluster_ca_certificate = local.cluster_ca
  }
}

resource "kubernetes_namespace" "monitoring" {
  depends_on = [ hcloud_load_balancer_service.management_lb_k8s_service ]
  count = var.preinstall_monitoring_stack ? 1 : 0
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prom_stack" {
  depends_on = [kubernetes_namespace.monitoring, helm_release.loki]

  count = var.preinstall_monitoring_stack ? 1 : 0
  name  = "prom-stack"
  # https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "45.25.0"

  namespace = "monitoring"

  values = [
    <<EOF
grafana:
  additionalDataSources:
    - name: Loki
      type: loki
      access: proxy
      url: http://${helm_release.loki[0].name}.${kubernetes_namespace.monitoring[0].metadata[0].name}:3100/
      editable: false
      jsonData:
        maxLines: 1000
        minInterval: 5s
      basicAuth: true
      basicAuthPassword: ${random_password.loki_auth[0].result}
      basicAuthUser: operator
    EOF
  ]
}

resource "random_password" "loki_auth" {
  count   = var.preinstall_monitoring_stack ? 1 : 0
  length  = 16
  special = false
}

resource "helm_release" "loki" {
  depends_on = [kubernetes_namespace.monitoring]

  count = var.preinstall_monitoring_stack ? 1 : 0
  name  = "loki"
  # https://github.com/grafana/helm-charts/blob/main/charts/loki-stack/values.yaml
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.9.10"

  namespace = "monitoring"
  values = [
    <<EOF
minio:
  enabled: true
loki:
  isDefault: false
gateway:
  basicAuth: 
    username: operator
    password: ${random_password.loki_auth[0].result}
    EOF
  ]
}

resource "kubernetes_ingress_v1" "monitoring_ingress" {
  depends_on = [kubernetes_namespace.monitoring]

  count = var.preinstall_monitoring_stack ? 1 : 0
  metadata {
    name      = "monitoring-ingress"
    namespace = "monitoring"
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
  }
}
