terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.36.2"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 1.25.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

provider "hcloud" {
  token = var.hetzner_token
}

resource "random_password" "main" {
  length  = 16
  special = false
}

resource "cloudflare_record" "rancher" {
  zone_id = var.cloudflare_zone_id
  name    = var.rancher_domain_prefix
  type    = "A"
  proxied = true
  value   = hcloud_server.main.ipv4_address
}

resource "hcloud_network" "main" {
  name     = "main-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/16"
}

resource "hcloud_server" "main" {
  name        = "rancher-host"
  server_type = "cpx21"
  image       = "ubuntu-20.04"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.main.id]
  user_data = templatefile("${path.module}/scripts/rancher-init.sh.tpl", {
    RANCHER_DOMAIN   = "${var.rancher_domain_prefix}.${var.cloudflare_domain}"
    RANCHER_PASSWORD = random_password.main.result
  })

  network {
    network_id = hcloud_network.main.id
  }

  depends_on = [
    hcloud_network_subnet.main
  ]

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'"
    ]

    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = tls_private_key.machines.private_key_openssh
    }
  }
}

resource "local_file" "name" {
  content         = tls_private_key.machines.private_key_openssh
  filename        = "rancher-host-key"
  file_permission = "0600"
}

resource "hcloud_firewall" "main" {
  name = "main-firewall"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall_attachment" "main" {
  firewall_id = hcloud_firewall.main.id
  server_ids  = [hcloud_server.main.id]
}

resource "hcloud_ssh_key" "main" {
  name       = "main-ssh-key"
  public_key = tls_private_key.machines.public_key_openssh
}

resource "tls_private_key" "machines" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "time_sleep" "wait_10_seconds" {
  depends_on = [hcloud_server.main, cloudflare_record.rancher]
  destroy_duration = "10s"
  create_duration = "10s"
}

provider "rancher2" {
  alias     = "bootstrap"
  api_url   = "https://${var.rancher_domain_prefix}.${var.cloudflare_domain}"
  bootstrap = true
}

# Create a new rancher2_bootstrap using bootstrap provider config
resource "rancher2_bootstrap" "admin" {
  depends_on = [time_sleep.wait_10_seconds]
  provider         = rancher2.bootstrap
  initial_password = random_password.main.result
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
  url               = "https://github.com/JonasProgrammer/docker-machine-driver-hetzner/releases/download/3.6.0/docker-machine-driver-hetzner_3.6.0_linux_amd64.tar.gz"
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
    networks            = hcloud_network.main.id
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
    networks            = hcloud_network.main.id
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

resource "hcloud_load_balancer" "load_balancer" {
  name               = "cluster-load-balancer"
  load_balancer_type = "lb11"
  location           = "hel1"
}

resource "rancher2_cluster" "test_cluster" {
  name        = "test-cluster"
  description = "Foo rancher2 custom cluster"
  rke_config {
    addons = <<EOF
---
apiVersion: v1
stringData:
  token: ${var.hetzner_token}
  network: ${hcloud_network.main.name}
kind: Secret
metadata:
  name: hcloud
  namespace: kube-system
    EOF
    addons_include = [ "https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/latest/download/ccm-networks.yaml" ]
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
  length           = 16
  special          = false
}

resource "rancher2_user" "admin_user" {
  name = "rancheradmin"
  username = "rancheradmin"
  password = random_password.admin_user.result
  enabled = true
}

resource "rancher2_global_role_binding" "admin_user" {
  name = "rancheradmin"
  global_role_id = "admin"
  user_id = rancher2_user.admin_user.id
}