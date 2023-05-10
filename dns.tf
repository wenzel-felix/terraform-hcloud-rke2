locals {
  ip_addresses = concat(hcloud_server.master[*].ipv4_address, hcloud_server.worker[*].ipv4_address)
}

resource "cloudflare_record" "wildcard" {
  for_each = var.create_cloudflare_dns_record ? {for id in range(var.master_node_count + var.worker_node_count): id => local.ip_addresses[id]} : {}
  zone_id  = var.cloudflare_zone_id
  name     = "*.${var.cloudflare_domain}"
  type     = "A"
  proxied  = !var.use_cluster_managed_tls_certificates
  value    = each.value
}
