resource "hcloud_network" "main" {
  name     = "${var.cluster_name}-network"
  ip_range = var.network_address
}

resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.network_address
}
