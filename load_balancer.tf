resource "hcloud_load_balancer" "management_lb" {
  name               = "rke2-management-lb"
  load_balancer_type = "lb11"
  location           = "hel1"
    labels = {
        "rke2" = "management"
    }
}

resource "hcloud_load_balancer_network" "management_lb_network_registration" {
  load_balancer_id = hcloud_load_balancer.management_lb.id
  subnet_id        = hcloud_network_subnet.main.id
}

resource "hcloud_load_balancer_target" "management_lb_targets" {

  count            = var.master_node_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.management_lb.id
  server_id        = hcloud_server.master[count.index].id
  use_private_ip   = true
  depends_on = [
    hcloud_load_balancer_network.management_lb_network_registration
  ]
}

resource "hcloud_load_balancer_service" "management_lb_k8s_service" {
  load_balancer_id = hcloud_load_balancer.management_lb.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
  depends_on       = [hcloud_load_balancer_target.management_lb_targets, hcloud_server.worker]
}

resource "hcloud_load_balancer_service" "management_lb_ssh_service" {
  load_balancer_id = hcloud_load_balancer.management_lb.id
  protocol         = "tcp"
  listen_port      = 22
  destination_port = 22
  depends_on       = [hcloud_load_balancer_target.management_lb_targets]
}

resource "hcloud_load_balancer_service" "management_lb_register_service" {
  load_balancer_id = hcloud_load_balancer.management_lb.id
  protocol         = "tcp"
  listen_port      = 9345
  destination_port = 9345
  depends_on       = [hcloud_load_balancer_target.management_lb_targets]
}

resource "hcloud_load_balancer_service" "management_lb_service" {
  for_each         = toset(var.additional_lb_service_ports)
  load_balancer_id = hcloud_load_balancer.management_lb.id
  protocol         = "tcp"
  listen_port      = tonumber(each.value)
  destination_port = tonumber(each.value)
  depends_on       = [hcloud_load_balancer_target.management_lb_targets]
}
