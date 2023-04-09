terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 1.25.0"
    }
  }
}