# output "kube_config" {
#   value = rancher2_cluster.test_cluster.kube_config
# }

# output "rancher_url" {
#   value = "https://${var.rancher_domain_prefix}.${var.cloudflare_domain}"
# }

# output "rancher_admin_password" {
#   value = random_password.admin_user.result
# }

# output "rancher_admin_username" {
#   value = "rancherAdmin"
# }

output "kubeconfig" {
  value = data.remote_file.kubeconfig.content
}

output "cluster_ca" {
  value = local.cluster_ca
}

output "client_cert" {
  value = local.client_cert
}

output "client_key" {
  value = local.client_key
}

output "cluster_host" {
  value = local.cluster_host
}