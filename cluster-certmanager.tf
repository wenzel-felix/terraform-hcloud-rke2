resource "kubernetes_namespace" "cert_manager" {
  depends_on = [hcloud_load_balancer_service.management_lb_k8s_service]
  count      = var.use_cluster_managed_tls_certificates ? 1 : 0
  metadata {
    name = "cert-manager"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
    ]
  }
}

resource "kubernetes_secret" "cert_manager" {
  depends_on = [kubernetes_namespace.cert_manager]
  count      = var.use_cluster_managed_tls_certificates ? 1 : 0
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = "cert-manager"
  }

  data = {
    api-token = var.cloudflare_token
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
    ]
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [kubernetes_namespace.cert_manager]
  count      = var.use_cluster_managed_tls_certificates ? 1 : 0

  name = "cert-manager"
  # https://cert-manager.io/docs/installation/helm/
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.13.3"

  namespace = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubectl_manifest" "cert_manager_issuer" {
  depends_on = [kubernetes_secret.cert_manager, helm_release.cert_manager]
  count      = var.use_cluster_managed_tls_certificates ? 1 : 0
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: cloudflare
spec:
  acme:
    email: ${var.letsencrypt_issuer}
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
YAML
}
