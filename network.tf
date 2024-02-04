locals {
  network_address  = var.network_address != null ? var.network_address : "10.0.0.0/16"
}

resource "hcloud_network" "main" {
  name     = "${var.cluster_name}-network"
  ip_range = local.network_address
}

resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = local.network_address
}
