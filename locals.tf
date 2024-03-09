locals {
  cluster_loadbalancer_running = length(data.hcloud_load_balancers.rke2_management.load_balancers) > 0
  cluster_ca                   = data.remote_file.kubeconfig.content == "" ? "" : base64decode(yamldecode(data.remote_file.kubeconfig.content).clusters[0].cluster.certificate-authority-data)
  client_key                   = data.remote_file.kubeconfig.content == "" ? "" : base64decode(yamldecode(data.remote_file.kubeconfig.content).users[0].user.client-key-data)
  client_cert                  = data.remote_file.kubeconfig.content == "" ? "" : base64decode(yamldecode(data.remote_file.kubeconfig.content).users[0].user.client-certificate-data)
  cluster_host                 = "https://${hcloud_load_balancer.management_lb.ipv4}:6443"
  kube_config                  = replace(data.remote_file.kubeconfig.content, "https://127.0.0.1:6443", local.cluster_host)

  istio_charts_url = "https://istio-release.storage.googleapis.com/charts"
  istio_values     = var.cluster_configuration.tracing_stack.preinstall ? [file("${path.module}/templates/values/istiod.yaml")] : []

  is_ha_cluster = var.master_node_count >= 3

  system_upgrade_controller_crds = try(split("---", data.http.system_upgrade_controller_crds[0].response_body), null)
  system_upgrade_controller_components = try(split("---", data.http.system_upgrade_controller[0].response_body), null)

  gateway_api_crds_raw = try(split("---\n", data.http.gateway_api[0].response_body), null)
  gateway_api_crds     = try(slice(local.gateway_api_crds_raw, 1, length(local.gateway_api_crds_raw)), null)

  oidc_issuer_subdomain = "oidc.${var.domain}"
}
