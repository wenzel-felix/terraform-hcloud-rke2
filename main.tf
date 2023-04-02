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
    remote = {
      source  = "tenstad/remote"
      version = "0.1.1"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

provider "hcloud" {
  token = var.hetzner_token
}

# resource "cloudflare_record" "rancher" {
#   zone_id = var.cloudflare_zone_id
#   name    = var.rancher_domain_prefix
#   type    = "A"
#   proxied = true
#   value   = hcloud_server.main.ipv4_address
# }

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

resource "random_string" "master_node_suffix" {
  count   = var.master_node_count
  length  = 6
  special = false
}

data "remote_file" "kubeconfig" {
  depends_on = [
    hcloud_load_balancer_target.rancher_management_lb_targets
  ]
  conn {
    host        = hcloud_load_balancer.rancher_management_lb.ipv4
    user        = "root"
    private_key = tls_private_key.machines.private_key_openssh
    sudo        = true
  }

  path = "/etc/rancher/rke2/rke2.yaml"
}

locals {
  cluster_ca   = data.remote_file.kubeconfig.content == "" ? "" : base64decode(yamldecode(data.remote_file.kubeconfig.content).clusters[0].cluster.certificate-authority-data)
  client_key   = data.remote_file.kubeconfig.content == "" ? "" : base64decode(yamldecode(data.remote_file.kubeconfig.content).users[0].user.client-key-data)
  client_cert  = data.remote_file.kubeconfig.content == "" ? "" : base64decode(yamldecode(data.remote_file.kubeconfig.content).users[0].user.client-certificate-data)
  cluster_host = "https://${hcloud_load_balancer.rancher_management_lb.ipv4}:6443"
}

resource "random_password" "rke2_token" {
  length  = 48
  special = false
}

data "hcloud_load_balancers" "lb_3" {
  with_selector = "rancher=management"
}

locals {
  cluster_loadbalancer_running = length(data.hcloud_load_balancers.lb_3.load_balancers) > 0
}

resource "hcloud_server" "master" {
  count       = var.master_node_count
  name        = "rke2-master-${random_string.master_node_suffix[count.index].result}"
  server_type = "cpx21"
  image       = "ubuntu-20.04"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.main.id]
  user_data = templatefile("${path.module}/scripts/rke-master.sh.tpl", {
    RKE_TOKEN      = random_password.rke2_token.result
    INITIAL_MASTER = count.index == 0 && !local.cluster_loadbalancer_running
    SERVER_ADDRESS = hcloud_load_balancer.rancher_management_lb.ipv4
  })

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

  lifecycle {
    ignore_changes = [
      user_data
    ]
  }
}

resource "random_string" "worker_node_suffix" {
  count   = var.master_node_count
  length  = 6
  special = false
}

resource "hcloud_server" "worker" {
  count       = var.worker_node_count
  name        = "rke2-worker-${random_string.worker_node_suffix[count.index].result}"
  server_type = "cpx21"
  image       = "ubuntu-20.04"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.main.id]
  user_data = templatefile("${path.module}/scripts/rke-worker.sh.tpl", {
    RKE_TOKEN      = random_password.rke2_token.result
    SERVER_ADDRESS = hcloud_load_balancer.rancher_management_lb.ipv4
  })

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

resource "hcloud_server_network" "master" {
  count     = var.master_node_count
  server_id = hcloud_server.master[count.index].id
  subnet_id = hcloud_network_subnet.main.id
}

resource "hcloud_server_network" "worker" {
  count     = var.worker_node_count
  server_id = hcloud_server.worker[count.index].id
  subnet_id = hcloud_network_subnet.main.id
}

resource "local_file" "name" {
  content         = tls_private_key.machines.private_key_openssh
  filename        = "rancher-host-key"
  file_permission = "0600"
}

# resource "hcloud_firewall" "main" {
#   name = "main-firewall"
#   rule {
#     direction = "in"
#     protocol  = "tcp"
#     port      = "80"
#     source_ips = [
#       "0.0.0.0/0",
#       "::/0"
#     ]
#   }
#   rule {
#     direction = "in"
#     protocol  = "tcp"
#     port      = "22"
#     source_ips = [
#       "0.0.0.0/0",
#       "::/0"
#     ]
#   }
#   rule {
#     direction = "in"
#     protocol  = "tcp"
#     port      = "443"
#     source_ips = [
#       "0.0.0.0/0",
#       "::/0"
#     ]
#   }
# }

# resource "hcloud_firewall_attachment" "main" {
#   firewall_id = hcloud_firewall.main.id
#   server_ids  = [hcloud_server.main.id]
# }

resource "hcloud_ssh_key" "main" {
  name       = "main-ssh-key"
  public_key = tls_private_key.machines.public_key_openssh
}

resource "tls_private_key" "machines" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

