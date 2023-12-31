provider "rancher2" {
  alias     = "bootstrap"
  api_url   = "https://${var.rancher_domain_prefix}.${var.cloudflare_domain}"
  bootstrap = true
}

# Create a new rancher2_bootstrap using bootstrap provider config
resource "rancher2_bootstrap" "admin" {
  depends_on       = [helm_release.rancher]
  provider         = rancher2.bootstrap
  initial_password = random_password.rancher_init_password.result
}

# Provider config for admin
provider "rancher2" {
  api_url   = rancher2_bootstrap.admin.url
  token_key = rancher2_bootstrap.admin.token
}

resource "rancher2_node_driver" "hetzner_node_driver" {
  active            = true
  builtin           = false
  name              = "hetzner"
  ui_url            = "https://storage.googleapis.com/hcloud-rancher-v2-ui-driver/component.js"
  url               = "https://github.com/JonasProgrammer/docker-machine-driver-hetzner/releases/download/5.0.2/docker-machine-driver-hetzner_5.0.2_linux_amd64.tar.gz"
  whitelist_domains = ["storage.googleapis.com"]
}

resource "rancher2_node_template" "hetzner_worker" {
  name      = "hetzner-worker-node-template"
  driver_id = rancher2_node_driver.hetzner_node_driver.id
  hetzner_config {
    api_token           = var.hetzner_token
    image               = "ubuntu-20.04"
    server_location     = "nbg1"
    server_type         = "cpx21"
    networks            = module.rke2.management_network_id
    use_private_network = true
  }
}

resource "rancher2_node_template" "hetzner_master" {
  name      = "hetzner-master-node-template"
  driver_id = rancher2_node_driver.hetzner_node_driver.id
  hetzner_config {
    api_token           = var.hetzner_token
    image               = "ubuntu-20.04"
    server_location     = "nbg1"
    server_type         = "cpx11"
    networks            = module.rke2.management_network_id
    use_private_network = true
  }
}

resource "rancher2_node_pool" "master" {
  cluster_id       = rancher2_cluster.test_cluster.id
  name             = "master"
  hostname_prefix  = "master-cluster-0"
  node_template_id = rancher2_node_template.hetzner_master.id
  quantity         = 1
  control_plane    = true
  etcd             = false
  worker           = false
}

resource "rancher2_node_pool" "worker" {
  cluster_id       = rancher2_cluster.test_cluster.id
  name             = "worker"
  hostname_prefix  = "worker-cluster-0"
  node_template_id = rancher2_node_template.hetzner_worker.id
  quantity         = 3
  control_plane    = false
  etcd             = true
  worker           = true
}

resource "rancher2_cluster" "test_cluster" {
  name        = "test-cluster"
  description = "Foo rancher2 custom cluster"
  rke_config {
    addons         = <<EOF
---
apiVersion: v1
stringData:
  token: ${var.hetzner_token}
  network: ${module.rke2.management_network_name}
kind: Secret
metadata:
  name: hcloud
  namespace: kube-system
    EOF
    addons_include = ["https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/latest/download/ccm-networks.yaml"]
    services {
      kubelet {
        extra_args = {
          "cloud-provider" = "external"
        }
      }
    }
    enable_cri_dockerd = true
    network {
      plugin = "canal"
    }
  }
}

resource "random_password" "admin_user" {
  length  = 16
  special = false
}

resource "rancher2_user" "admin_user" {
  name     = "rancheradmin"
  username = "rancheradmin"
  password = random_password.admin_user.result
  enabled  = true
}

resource "rancher2_global_role_binding" "admin_user" {
  name           = "rancheradmin"
  global_role_id = "admin"
  user_id        = rancher2_user.admin_user.id
}