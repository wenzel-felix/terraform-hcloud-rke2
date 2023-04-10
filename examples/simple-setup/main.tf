module "rancher" {
  source             = "../.."
  hetzner_token      = var.hetzner_token
  master_node_count = 3
  worker_node_count = 1
}

resource "local_file" "name" {
  content = module.rancher.kube_config
  filename = "kubeconfig.yaml"
}

