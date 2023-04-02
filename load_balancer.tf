resource "hcloud_load_balancer" "rancher_management_lb" {
  name               = "rancher-management-lb"
  load_balancer_type = "lb11"
  location           = "hel1"
    labels = {
        "rancher" = "management"
    }
}

resource "hcloud_load_balancer_network" "rancher_management_lb_network_registration" {
  load_balancer_id = hcloud_load_balancer.rancher_management_lb.id
  subnet_id        = hcloud_network_subnet.main.id
}

resource "hcloud_load_balancer_target" "rancher_management_lb_targets" {

  count            = var.master_node_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.rancher_management_lb.id
  server_id        = hcloud_server.master[count.index].id
  use_private_ip   = true
  depends_on = [
    hcloud_load_balancer_network.rancher_management_lb_network_registration,
    hcloud_server_network.master
  ]
}

resource "hcloud_load_balancer_service" "rancher_management_lb_k8s_service" {
  load_balancer_id = hcloud_load_balancer.rancher_management_lb.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
  depends_on       = [hcloud_load_balancer_target.rancher_management_lb_targets]
}

resource "hcloud_load_balancer_service" "rancher_management_lb_ssh_service" {
  load_balancer_id = hcloud_load_balancer.rancher_management_lb.id
  protocol         = "tcp"
  listen_port      = 22
  destination_port = 22
  depends_on       = [hcloud_load_balancer_target.rancher_management_lb_targets]
}

resource "hcloud_load_balancer_service" "rancher_management_lb_register_service" {
  load_balancer_id = hcloud_load_balancer.rancher_management_lb.id
  protocol         = "tcp"
  listen_port      = 9345
  destination_port = 9345
  depends_on       = [hcloud_load_balancer_target.rancher_management_lb_targets]
}

resource "hcloud_load_balancer_service" "rancher_management_lb_http_service" {
  load_balancer_id = hcloud_load_balancer.rancher_management_lb.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 80
  depends_on       = [hcloud_load_balancer_target.rancher_management_lb_targets]
}

resource "hcloud_load_balancer_service" "rancher_management_lb_https_service" {
  load_balancer_id = hcloud_load_balancer.rancher_management_lb.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 443
  depends_on       = [hcloud_load_balancer_target.rancher_management_lb_targets]
}
