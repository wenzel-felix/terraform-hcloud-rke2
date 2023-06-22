terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.40"
    }
    remote = {
      source  = "tenstad/remote"
      version = "0.1.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.3"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_token
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

provider "helm" {
  kubernetes {
    host = local.cluster_host

    client_certificate     = local.client_cert
    client_key             = local.client_key
    cluster_ca_certificate = local.cluster_ca
  }
}

provider "kubectl" {
  host = local.cluster_host

  client_certificate     = local.client_cert
  client_key             = local.client_key
  cluster_ca_certificate = local.cluster_ca
  load_config_file = false
}

provider "kubernetes" {
  host = local.cluster_host

  client_certificate     = local.client_cert
  client_key             = local.client_key
  cluster_ca_certificate = local.cluster_ca
}