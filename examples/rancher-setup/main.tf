module "rke2" {
  domain                               = var.domain
  source                               = "../.."
  hetzner_token                        = var.hetzner_token
  master_node_count                    = 3
  worker_node_count                    = 1
  additional_lb_service_ports          = ["80", "443"]
  use_cluster_managed_tls_certificates = false
  rke2_version                         = var.rke2_version
  rancher_version                      = var.rancher_version
}

output "kube_config" {
  value = nonsensitive(rancher2_cluster.test_cluster.kube_config)
}

output "rancher_admin_username" {
  value = rancher2_user.admin_user.username
}

output "rancher_admin_password" {
  value = nonsensitive(random_password.admin_user.result)
}

