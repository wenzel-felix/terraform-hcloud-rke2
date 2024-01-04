resource "kubernetes_namespace" "istio_system" {
  count      = var.cluster_configuration.istio_service_mesh.preinstall ? 1 : 0
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
  count      = var.cluster_configuration.istio_service_mesh.preinstall ? 1 : 0
  depends_on = [kubernetes_namespace.istio_system[0]]
  repository = local.istio_charts_url
  chart      = "base"
  name       = "istio-base"
  namespace  = kubernetes_namespace.istio_system[0].metadata[0].name
  version    = var.cluster_configuration.istio_service_mesh.version
}

resource "helm_release" "istiod" {
  count      = var.cluster_configuration.istio_service_mesh.preinstall ? 1 : 0
  repository = local.istio_charts_url
  chart      = "istiod"
  name       = "istiod"
  namespace  = kubernetes_namespace.istio_system[0].metadata[0].name
  version    = var.cluster_configuration.istio_service_mesh.version
  depends_on = [helm_release.istio_base[0], kubectl_manifest.gateway_api]
  values     = local.istio_values
}

data "http" "gateway_api" {
  count = var.preinstall_gateway_api_crds ? 1 : 0
  url   = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_version}/standard-install.yaml"
}

resource "kubectl_manifest" "gateway_api" {
  depends_on = [hcloud_load_balancer_service.management_lb_k8s_service]
  for_each   = var.preinstall_gateway_api_crds ? { for i in local.gateway_api_crds : index(local.gateway_api_crds, i) => i } : {}
  yaml_body  = each.value
}
