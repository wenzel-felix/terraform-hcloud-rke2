module "rke2" {
  source                = "../.."
  hetzner_token         = var.hetzner_token
  master_node_count     = 3
  worker_node_count     = 1
  generate_ssh_key_file = true
  rke2_version          = "v1.27.1+rke2r1"
  cluster_configuration = {
    preinstall_monitoring_stack   = true
    preinstall_istio_service_mesh = true
    preinstall_tracing_stack      = true
    preinstall_hcloud_controller  = false
  }
  create_cloudflare_dns_record         = true
  cloudflare_zone_id                   = var.cloudflare_zone_id
  cloudflare_token                     = var.cloudflare_token
  cloudflare_domain                    = var.cloudflare_domain
  letsencrypt_issuer                   = var.letsencrypt_issuer
  use_cluster_managed_tls_certificates = true
}

resource "local_file" "name" {
  content  = module.rke2.kube_config
  filename = "kubeconfig.yaml"
}

