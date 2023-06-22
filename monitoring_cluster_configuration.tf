resource "kubernetes_namespace" "monitoring" {
  depends_on = [ hcloud_load_balancer_service.management_lb_k8s_service ]
  count = var.preinstall_monitoring_stack ? 1 : 0
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prom_stack" {
  depends_on = [kubernetes_namespace.monitoring, helm_release.loki, kubernetes_config_map_v1.dashboard, helm_release.tempo]

  count = var.preinstall_monitoring_stack ? 1 : 0
  name  = "prom-stack"
  # https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "45.25.0"

  namespace = "monitoring"

  values = [
    <<EOF
prometheus:
  prometheusSpec:
    enableRemoteWriteReceiver: true
    enableFeatures:
      - remote-write-receiver
grafana:
  additionalDataSources:
    - name: Loki
      type: loki
      uid: loki
      access: proxy
      url: http://${helm_release.loki[0].name}.${kubernetes_namespace.monitoring[0].metadata[0].name}:3100/
      editable: true
      basicAuth: true
      basicAuthPassword: ${random_password.loki_auth[0].result}
      basicAuthUser: operator         
      jsonData:
        derivedFields:
          - matcherRegex: "traceID=([a-fA-F0-9-]+)"
            name: TraceID
            url: '$${__value.raw}'
            datasourceUid: tempo
    - name: Tempo
      type: tempo
      access: browser
      orgId: 1
      uid: tempo
      url: http://${helm_release.tempo[0].name}.${kubernetes_namespace.monitoring[0].metadata[0].name}:3100
      isDefault: false
      editable: true
      jsonData:
        httpMethod: GET
        serviceMap:
          datasourceUid: 'prometheus'
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

  count = var.preinstall_monitoring_stack ? 1 : 0
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


################################
######### Tracing ##############
################################

resource "helm_release" "tempo" {
  depends_on = [kubernetes_namespace.monitoring]
  count      = var.preinstall_monitoring_stack ? 1 : 0
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  name       = "tempo"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = "1.3.1"
  values = [file("${path.module}/templates/values/tempo.yaml")]
}

resource "kubectl_manifest" "otel" {
  depends_on = [kubernetes_namespace.monitoring]
  yaml_body = file("${path.module}/templates/manifests/otel-deployment.yaml")
}

resource "kubectl_manifest" "otel_svc" {
  depends_on = [kubernetes_namespace.monitoring]
  yaml_body = file("${path.module}/templates/manifests/otel-service.yaml")
}

resource "kubectl_manifest" "config" {
  depends_on = [kubernetes_namespace.monitoring]
  yaml_body = file("${path.module}/templates/manifests/otel-configmap.yaml")
}