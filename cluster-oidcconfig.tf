resource "kubernetes_ingress_v1" "oidc" {
  depends_on = [hcloud_load_balancer_service.management_lb_k8s_service]
  count      = var.expose_oidc_issuer_url != null ? 1 : 0

  metadata {
    name      = "oidc-ingress"
    namespace = "default"
    annotations = {
      "cert-manager.io/cluster-issuer"               = "cloudflare"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = local.oidc_issuer_subdomain
      http {
        path {
          backend {
            service {
              name = "kubernetes"
              port {
                number = 443
              }
            }
          }
          path      = "/.well-known/openid-configuration"
          path_type = "Exact"
        }
        path {
          backend {
            service {
              name = "kubernetes"
              port {
                number = 443
              }
            }
          }
          path      = "/openid/v1/jwks"
          path_type = "Exact"
        }
      }
    }

    tls {
      hosts = [
        local.oidc_issuer_subdomain
      ]
      secret_name = "oidc-tls"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
    ]
  }
}

resource "kubernetes_cluster_role_binding" "oidc" {
  count = var.expose_oidc_issuer_url != null ? 1 : 0
  metadata {
    name = "service-account-issuer-discovery"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "system:service-account-issuer-discovery"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "Group"
    name      = "system:unauthenticated"
    api_group = "rbac.authorization.k8s.io"
  }
}
