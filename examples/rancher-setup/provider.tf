terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.21.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 3.2.0"
    }
  }
}