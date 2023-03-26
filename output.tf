output "kube_config" {
  value = rancher2_cluster.test_cluster.kube_config
}

output "rancher_url" {
  value = "https://${var.rancher_domain_prefix}.${var.cloudflare_domain}"
}

output "rancher_admin_password" {
  value = random_password.admin_user.result
}

output "rancher_admin_username" {
  value = "rancherAdmin"
}