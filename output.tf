output "kube_config" {
  value = local.kube_config
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

output "management_lb_ipv4" {
  value = hcloud_load_balancer.management_lb.ipv4
}

output "management_network_id" {
  value = hcloud_network.main.id
}

output "management_network_name" {
  value = hcloud_network.main.name
}

output "cluster_master_nodes_ipv4" {
  value = hcloud_server.master[*].ipv4_address
}

output "cluster_worker_nodes_ipv4" {
  value = hcloud_server.worker[*].ipv4_address
}
