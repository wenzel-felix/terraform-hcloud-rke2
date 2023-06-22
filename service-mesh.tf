resource "kubernetes_namespace" "istio_system" {
  depends_on = [ hcloud_load_balancer_service.management_lb_k8s_service ]
  metadata {
    name = "istio-system"
  }
}

resource "helm_release" "istio_base" {
  depends_on = [kubernetes_namespace.istio_system]
  repository = local.istio_charts_url
  chart      = "base"
  name       = "istio-base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.18.0"
}

resource "helm_release" "istiod" {
  repository = local.istio_charts_url
  chart      = "istiod"
  name       = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.18.0"
  depends_on = [helm_release.istio_base]
  values = [ file("${path.module}/templates/values/istiod.yaml") ]
}

# data "http" "gateway_api" {
#   url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.7.1/standard-install.yaml"
# }

# resource "kubectl_manifest" "gateway_api" {
#   yaml_body = data.http.gateway_api.request_body
# }
