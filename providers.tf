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
  }
}

provider "hcloud" {
  token = var.hetzner_token
}