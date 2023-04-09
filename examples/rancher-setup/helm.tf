provider "helm" {
  kubernetes {
    host = module.rke2.cluster_host

    client_certificate     = module.rke2.client_cert
    client_key             = module.rke2.client_key
    cluster_ca_certificate = module.rke2.cluster_ca
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [
    cloudflare_record.rancher
  ]
  name       = "cert-manager"
  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.11.0"

  wait             = true
  create_namespace = true
  force_update     = true
  replace          = true

  set {
    name  = "installCRDs"
    value = true
  }
}

resource "random_password" "rancher_init_password" {
  length  = 16
  special = false
}

resource "helm_release" "rancher" {
  name       = "rancher"
  namespace  = "cattle-system"
  chart      = "rancher"
  version    = "2.7.1"
  repository = "https://releases.rancher.com/server-charts/stable"
  depends_on = [helm_release.cert_manager]

  wait             = true
  create_namespace = true
  force_update     = true
  replace          = true

  set {
    name  = "hostname"
    value = "${var.rancher_domain_prefix}.${var.cloudflare_domain}"
  }

  set {
    name  = "bootstrapPassword"
    value = random_password.rancher_init_password.result
  }

  set {
    name  = "ingress.tls.source"
    value = "letsEncrypt"
  }

  set {
    name  = "letsEncrypt.email"
    value = var.letsencrypt_issuer
  }
}
