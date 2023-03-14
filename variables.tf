variable "hetzner_token" {
  type        = string
  description = "Hetzner Cloud API Token"
}

variable "cloudflare_token" {
  type        = string
  description = "Cloudflare API Token"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID"
}

variable "rancher_domain_prefix" {
  type        = string
  description = "Domain prefix for the Rancher server"
  default = "rancher"
}

variable "cloudflare_domain" {
  type        = string
  description = "Cloudflare Domain"  
}