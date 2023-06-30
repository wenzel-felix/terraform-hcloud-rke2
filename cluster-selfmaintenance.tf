resource "kubernetes_namespace" "kured" {
  depends_on = [ hcloud_load_balancer_service.management_lb_k8s_service ]
  count = var.enable_auto_os_updates && local.is_ha_cluster ? 1 : 0
  metadata {
    name = "kured"
  }
}

resource "helm_release" "kured" {
  depends_on = [kubernetes_namespace.kured]
  count      = var.enable_auto_os_updates && local.is_ha_cluster ? 1 : 0
  repository = "https://kubereboot.github.io/charts"
  chart      = "kured"
  name       = "kured"
  namespace  = kubernetes_namespace.kured[0].metadata[0].name
  version    = "3.0.1"
}

data "http" "system_upgrade_controller" {
  url    = "https://raw.githubusercontent.com/rancher/system-upgrade-controller/master/manifests/system-upgrade-controller.yaml"
}

resource "kubectl_manifest" "system_upgrade_controller" {
  depends_on = [ hcloud_load_balancer_service.management_lb_k8s_service ]
  for_each      = var.enable_auto_kubernetes_updates && local.is_ha_cluster ? {for i in local.system_upgrade_controller_components: index(local.system_upgrade_controller_components, i) => i} : {}
  yaml_body  = each.value
}

resource "kubectl_manifest" "system_upgrade_controller_server_plan" {
  depends_on = [ kubectl_manifest.system_upgrade_controller ]
  count      = var.enable_auto_kubernetes_updates && local.is_ha_cluster ? 1 : 0
  yaml_body  = file("${path.module}/templates/manifests/system-upgrade-controller-server.yaml")
}

resource "kubectl_manifest" "system_upgrade_controller_agent_plan" {
  depends_on = [ kubectl_manifest.system_upgrade_controller ]
  count      = var.enable_auto_kubernetes_updates && local.is_ha_cluster ? 1 : 0
  yaml_body  = file("${path.module}/templates/manifests/system-upgrade-controller-agent.yaml")
}