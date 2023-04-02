module "rancher" {
  source             = "../.."
  hetzner_token      = var.hetzner_token
  cloudflare_token   = var.cloudflare_token
  cloudflare_zone_id = var.cloudflare_zone_id
  cloudflare_domain = var.cloudflare_domain
  master_node_count = 3
  letsencrypt_issuer = var.letsencrypt_issuer
}

output "rancher_admin_username" {
  value = module.rancher.rancher_admin_username
}

output "rancher_admin_password" {
  value = nonsensitive(module.rancher.rancher_admin_password)
}

