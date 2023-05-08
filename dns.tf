resource "cloudflare_record" "wildcard" {
  for_each = var.create_cloudflare_dns_record ? toset(concat(hcloud_server.master[*].ipv4_address, hcloud_server.worker[*].ipv4_address)) : []
  zone_id  = var.cloudflare_zone_id
  name     = "*.${var.cloudflare_domain}"
  type     = "A"
  proxied  = !var.use_cluster_managed_tls_certificates
  value    = each.value
}
