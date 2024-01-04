resource "kubernetes_secret" "hcloud_ccm" {
  depends_on = [hcloud_load_balancer_service.management_lb_k8s_service]
  count      = var.cluster_configuration.hcloud_controller.preinstall ? 1 : 0
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }

  data = {
    token   = var.hetzner_token
    network = "${hcloud_network.main.name}"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
    ]
  }
}

resource "helm_release" "hccm" {
  depends_on = [kubernetes_secret.hcloud_ccm]
  count      = var.cluster_configuration.hcloud_controller.preinstall ? 1 : 0
  repository = "https://charts.hetzner.cloud"
  chart      = "hcloud-cloud-controller-manager"
  name       = "hccm"
  namespace  = "kube-system"
  version    = var.cluster_configuration.hcloud_controller.version

  values = [file("${path.module}/templates/values/hccm.yaml")]
}
