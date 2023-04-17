data "remote_file" "kubeconfig" {
  depends_on = [
    time_sleep.wait_30_seconds
  ]
  conn {
    host        = hcloud_load_balancer.management_lb.ipv4
    user        = "root"
    private_key = tls_private_key.machines.private_key_openssh
    sudo        = true
    timeout     = 500
  }

  path = "/etc/rancher/rke2/rke2.yaml"
}

data "hcloud_load_balancers" "rke2_management" {
  with_selector = "rke2=management"
}