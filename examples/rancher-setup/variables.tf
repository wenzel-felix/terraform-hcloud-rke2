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

variable "cloudflare_domain" {
  type        = string
  description = "Cloudflare Domain"
}

variable "letsencrypt_issuer" {
  type        = string
  description = "value for the letsencrypt issuer"
}

variable "rancher_domain_prefix" {
  type        = string
  default     = "rancher"
  description = "value for the rancher domain prefix"
}
