module "rke2" {
  source             = "../.."
  hetzner_token      = var.hetzner_token
  master_node_count = 3
  worker_node_count = 1
  generate_ssh_key_file = true
  rke2_version = "v1.27.1+rke2r1"
  preinstall_monitoring_stack = true
}

resource "local_file" "name" {
  content = module.rke2.kube_config
  filename = "kubeconfig.yaml"
}

