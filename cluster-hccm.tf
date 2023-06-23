resource "kubernetes_secret" "hcloud_ccm" {
  depends_on = [ hcloud_load_balancer_service.management_lb_k8s_service ]
  count = var.cluster_configuration.preinstall_hcloud_controller ? 1 : 0
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }

  data = {
    token   = var.hetzner_token
    network = "${hcloud_network.main.name}"
  }
}

resource "kubernetes_service_account" "hcloud_ccm" {
  depends_on = [ hcloud_load_balancer_service.management_lb_k8s_service ]
  count = var.cluster_configuration.preinstall_hcloud_controller ? 1 : 0
  metadata {
    name      = "cloud-controller-manager"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "hcloud_ccm" {
  depends_on = [ hcloud_load_balancer_service.management_lb_k8s_service ]
  count = var.cluster_configuration.preinstall_hcloud_controller ? 1 : 0
  metadata {
    name = "system:cloud-controller-manager"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cloud-controller-manager"
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "hcloud_ccm" {
  depends_on = [ hcloud_load_balancer_service.management_lb_k8s_service ]
  count = var.cluster_configuration.preinstall_hcloud_controller ? 1 : 0

  lifecycle {
    ignore_changes = [ 
      spec[0].template[0].spec[0],
      metadata[0].annotations
    ]
  }

  metadata {
    name      = "hcloud-cloud-controller-manager"
    namespace = "kube-system"
  }

  spec {
    replicas             = 1
    revision_history_limit = 2
    selector {
      match_labels = {
        app = "hcloud-cloud-controller-manager"
      }
    }
    template {
      metadata {
        labels = {
          app = "hcloud-cloud-controller-manager"
        }
      }
      spec {
        service_account_name = "cloud-controller-manager"
        dns_policy          = "Default"
        toleration {
          # Allow HCCM itself to schedule on nodes that have not yet been initialized by HCCM.
          key    = "node.cloudprovider.kubernetes.io/uninitialized"
          value  = "true"
          effect = "NoSchedule"
        }
        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }
        toleration {
          # Allow HCCM to schedule on control plane nodes.
          key      = "node-role.kubernetes.io/master"
          effect   = "NoSchedule"
          operator = "Exists"
        }
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          effect   = "NoSchedule"
          operator = "Exists"
        }
        toleration {
          key    = "node.kubernetes.io/not-ready"
          effect = "NoExecute"
        }
        host_network = true
        container {
          name = "hcloud-cloud-controller-manager"
          command = [
            "/bin/hcloud-cloud-controller-manager",
            "--allow-untagged-cloud",
            "--cloud-provider=hcloud",
            "--leader-elect=false",
            "--route-reconciliation-period=30s",
            "--allocate-node-cidrs=true",
            "--cluster-cidr=10.244.0.0/16"
          ]
          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "HCLOUD_TOKEN"
            value_from {
              secret_key_ref {
                name = "hcloud"
                key  = "token"
              }
            }
          }
          env {
            name = "HCLOUD_NETWORK"
            value_from {
              secret_key_ref {
                name = "hcloud"
                key  = "network"
              }
            }
          }
          image = "hetznercloud/hcloud-cloud-controller-manager:v1.14.2"
          port {
            name           = "metrics"
            container_port = 8233
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "50Mi"
            }
          }
        }
        priority_class_name = "system-cluster-critical"
      }
    }
  }
}
