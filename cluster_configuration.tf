provider "kubernetes" {
  host = local.cluster_host

  client_certificate     = local.client_cert
  client_key             = local.client_key
  cluster_ca_certificate = local.cluster_ca
}

resource "kubernetes_secret" "hcloud_ccm" {
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }

  data = {
    token   = var.hetzner_token
    network = "${hcloud_network.main.name}"
  }
}

# data "http" "hcloud_ccm" {
#   url = "https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/latest/download/ccm-networks.yaml"

#   request_headers = {
#     Accept = "application/json"
#   }

#   lifecycle {
#     postcondition {
#       condition     = contains([201, 204, 200], self.status_code)
#       error_message = "Please check if the hcloud ccm release is available at the provided address."
#     }
#   }
# }

# locals {
#   hcloud_ccm_manifests_raw = split("---", data.http.hcloud_ccm.response_body)
#   hcloud_ccm_manifests     = toset(slice(local.hcloud_ccm_manifests_raw, 1, length(local.hcloud_ccm_manifests_raw)))
# }

# resource "kubernetes_manifest" "hcloud_ccm" {
#   depends_on = [
#     kubernetes_secret.hcloud_ccm
#   ]
#   for_each = local.hcloud_ccm_manifests
#   manifest = yamldecode(each.value)
# }

resource "kubernetes_service_account" "hcloud_ccm" {
  metadata {
    name      = "cloud-controller-manager"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "hcloud_ccm" {
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
