provider "cloudflare" {
  api_token = var.cloudflare_token
}

resource "cloudflare_record" "rancher" {
  zone_id = var.cloudflare_zone_id
  name    = var.rancher_domain_prefix
  type    = "A"
  proxied = false
  value   = module.rke2.management_lb_ipv4
}