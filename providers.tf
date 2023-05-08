terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.38.2"
    }
    remote = {
      source  = "tenstad/remote"
      version = "0.1.1"
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