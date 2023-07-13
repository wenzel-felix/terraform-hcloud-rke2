resource "kubernetes_namespace" "istio_system" {
  count      = var.cluster_configuration.preinstall_istio_service_mesh ? 1 : 0
  depends_on = [hcloud_load_balancer_service.management_lb_k8s_service]
  metadata {
    name = "istio-system"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
    ]
  }
}

resource "helm_release" "istio_base" {
  count      = var.cluster_configuration.preinstall_istio_service_mesh ? 1 : 0
  depends_on = [kubernetes_namespace.istio_system[0]]
  repository = local.istio_charts_url
  chart      = "base"
  name       = "istio-base"
  namespace  = kubernetes_namespace.istio_system[0].metadata[0].name
  version    = "1.18.0"
}

resource "helm_release" "istiod" {
  count      = var.cluster_configuration.preinstall_istio_service_mesh ? 1 : 0
  repository = local.istio_charts_url
  chart      = "istiod"
  name       = "istiod"
  namespace  = kubernetes_namespace.istio_system[0].metadata[0].name
  version    = "1.18.0"
  depends_on = [helm_release.istio_base[0]]
  values     = local.istio_values
}

# data "http" "gateway_api" {
#   url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.7.1/standard-install.yaml"
# }

# resource "kubectl_manifest" "gateway_api" {
#   yaml_body = data.http.gateway_api.request_body
# }
