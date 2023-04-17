locals {
  cluster_loadbalancer_running = length(data.hcloud_load_balancers.rke2_management.load_balancers) > 0
  cluster_ca                   = data.remote_file.kubeconfig.content == "" ? "" : base64decode(yamldecode(data.remote_file.kubeconfig.content).clusters[0].cluster.certificate-authority-data)
  client_key                   = data.remote_file.kubeconfig.content == "" ? "" : base64decode(yamldecode(data.remote_file.kubeconfig.content).users[0].user.client-key-data)
  client_cert                  = data.remote_file.kubeconfig.content == "" ? "" : base64decode(yamldecode(data.remote_file.kubeconfig.content).users[0].user.client-certificate-data)
  cluster_host                 = "https://${hcloud_load_balancer.management_lb.ipv4}:6443"
  kube_config                  = replace(data.remote_file.kubeconfig.content, "https://127.0.0.1:6443", local.cluster_host)
}

resource "random_string" "master_node_suffix" {
  count   = var.master_node_count
  length  = 6
  special = false
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [hcloud_load_balancer_service.management_lb_ssh_service]

  create_duration = "30s"
}

resource "random_password" "rke2_token" {
  length  = 48
  special = false
}

resource "hcloud_server" "master" {
  depends_on = [
    hcloud_network_subnet.main
  ]
  count       = var.master_node_count
  name        = "rke2-master-${lower(random_string.master_node_suffix[count.index].result)}"
  server_type = "cpx21"
  image       = "ubuntu-20.04"
  location    = element(var.node_locations, count.index)
  ssh_keys    = [hcloud_ssh_key.main.id]
  user_data = templatefile("${path.module}/scripts/rke-master.sh.tpl", {
    RKE_TOKEN            = random_password.rke2_token.result
    INITIAL_MASTER       = count.index == 0 && !local.cluster_loadbalancer_running
    SERVER_ADDRESS       = hcloud_load_balancer.management_lb.ipv4
    INSTALL_RKE2_VERSION = var.rke2_version
  })

  network {
    network_id = hcloud_network.main.id
  }

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
    create_before_destroy = true
  }
}

resource "random_string" "worker_node_suffix" {
  count   = var.worker_node_count
  length  = 6
  special = false
}

resource "hcloud_server" "worker" {
  depends_on = [
    hcloud_network_subnet.main
  ]
  count       = var.worker_node_count
  name        = "rke2-worker-${lower(random_string.worker_node_suffix[count.index].result)}"
  server_type = "cpx21"
  image       = "ubuntu-20.04"
  location    = element(var.node_locations, count.index)
  ssh_keys    = [hcloud_ssh_key.main.id]
  user_data = templatefile("${path.module}/scripts/rke-worker.sh.tpl", {
    RKE_TOKEN            = random_password.rke2_token.result
    SERVER_ADDRESS       = hcloud_load_balancer.management_lb.ipv4
    INSTALL_RKE2_VERSION = var.rke2_version
  })

  network {
    network_id = hcloud_network.main.id
  }

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
    create_before_destroy = true
  }
}