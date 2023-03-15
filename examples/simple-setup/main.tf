module "rancher" {
  source             = "../.."
  hetzner_token      = var.hetzner_token
  cloudflare_token   = var.cloudflare_token
  cloudflare_zone_id = var.cloudflare_zone_id
  cloudflare_domain = var.cloudflare_domain
}

resource "local_file" "name" {
  content = module.rancher.kube_config
  filename = "kubeconfig"
}