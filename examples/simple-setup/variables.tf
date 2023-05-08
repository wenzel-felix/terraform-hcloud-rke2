variable "hetzner_token" {
  type        = string
  description = "Hetzner Cloud API Token"
}

variable "cloudflare_token" {
  type = string
  default = ""
  description = "The Cloudflare API token. (Required if create_cloudflare_dns_record is true.)"
}

variable "cloudflare_zone_id" {
  type = string
  default = ""
  description = "The Cloudflare zone id. (Required if create_cloudflare_dns_record is true.)"
}

variable "cloudflare_domain" {
  type = string
  default = ""
  description = "The Cloudflare domain. (Required if create_cloudflare_dns_record is true.)"
}

variable "letsencrypt_issuer" {
  type = string
  default = ""
  description = "The email to send notifications regarding let's encrypt."
}