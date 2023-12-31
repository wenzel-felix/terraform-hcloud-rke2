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

variable "domain" {
  type        = string
  description = "value for the rancher domain"
}

variable "rke2_version" {
  type        = string
  default     = "v1.26.11+rke2r1"
  description = "rke2 version"
}

variable "rancher_version" {
  type        = string
  default     = "2.7.9"
  description = "rancher_version"
}
