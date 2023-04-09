module "rke2" {
  source                      = "../.."
  hetzner_token               = var.hetzner_token
  master_node_count           = 3
  worker_node_count           = 1
  additional_lb_service_ports = ["80", "443"]
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

