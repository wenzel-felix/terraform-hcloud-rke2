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
  depends_on = [kubernetes_namespace.monitoring, helm_release.loki, kubernetes_config_map_v1.dashboard]

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
    "dashboard.json" = <<EOF
    {
  "annotations": {
    "list": [
      {
        "$$hashKey": "object:75",
        "builtIn": 1,
        "datasource": {
          "type": "datasource",
          "uid": "grafana"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "description": "Log Viewer Dashboard for Loki",
  "editable": false,
  "fiscalYearStartMonth": 0,
  "gnetId": 13639,
  "graphTooltip": 0,
  "id": 30,
  "links": [
    {
      "$$hashKey": "object:59",
      "icon": "bolt",
      "includeVars": true,
      "keepTime": true,
      "tags": [],
      "targetBlank": true,
      "title": "View In Explore",
      "type": "link",
      "url": "/explore?orgId=1&left=[\"now-1h\",\"now\",\"Loki\",{\"expr\":\"{job=\\\"$app\\\"}\"},{\"ui\":[true,true,true,\"none\"]}]"
    },
    {
      "$$hashKey": "object:61",
      "icon": "external link",
      "tags": [],
      "targetBlank": true,
      "title": "Learn LogQL",
      "type": "link",
      "url": "https://grafana.com/docs/loki/latest/logql/"
    }
  ],
  "liveNow": false,
  "panels": [
    {
      "aliasColors": {},
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "loki",
        "uid": "P8E80F9AEF21F6940"
      },
      "fieldConfig": {
        "defaults": {
          "links": []
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 3,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 6,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": false,
        "total": false,
        "values": false
      },
      "lines": false,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.5.1",
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "datasource": {
            "type": "loki",
            "uid": "P8E80F9AEF21F6940"
          },
          "expr": "sum(count_over_time({job=\"$app\"} |= \"$search\" [$__interval]))",
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "$$hashKey": "object:168",
          "format": "short",
          "logBase": 1,
          "show": false
        },
        {
          "$$hashKey": "object:169",
          "format": "short",
          "logBase": 1,
          "show": false
        }
      ],
      "yaxis": {
        "align": false
      }
    },
    {
      "datasource": {
        "type": "loki",
        "uid": "P8E80F9AEF21F6940"
      },
      "gridPos": {
        "h": 25,
        "w": 24,
        "x": 0,
        "y": 3
      },
      "id": 2,
      "maxDataPoints": "",
      "options": {
        "dedupStrategy": "none",
        "enableLogDetails": true,
        "prettifyLogMessage": false,
        "showCommonLabels": false,
        "showLabels": false,
        "showTime": true,
        "sortOrder": "Descending",
        "wrapLogMessage": false
      },
      "targets": [
        {
          "datasource": {
            "type": "loki",
            "uid": "P8E80F9AEF21F6940"
          },
          "expr": "{job=\"$app\"} |= \"$search\" | logfmt",
          "hide": false,
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "transparent": true,
      "type": "logs"
    }
  ],
  "refresh": "",
  "schemaVersion": 38,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": [
      {
        "current": {
          "selected": false,
          "text": "kube-system/hcloud-cloud-controller-manager",
          "value": "kube-system/hcloud-cloud-controller-manager"
        },
        "datasource": {
          "type": "loki",
          "uid": "P8E80F9AEF21F6940"
        },
        "definition": "label_values(job)",
        "hide": 0,
        "includeAll": false,
        "label": "App",
        "multi": false,
        "name": "app",
        "options": [],
        "query": "label_values(job)",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "current": {
          "selected": false,
          "text": "",
          "value": ""
        },
        "hide": 0,
        "label": "String Match",
        "name": "search",
        "options": [
          {
            "selected": true,
            "text": "",
            "value": ""
          }
        ],
        "query": "",
        "skipUrlSync": false,
        "type": "textbox"
      }
    ]
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {
    "hidden": false,
    "refresh_intervals": [
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "",
  "title": "Logs / App",
  "uid": "sadlil-loki-apps-dashboard",
  "version": 1,
  "weekStart": ""
}
EOF
  }
}