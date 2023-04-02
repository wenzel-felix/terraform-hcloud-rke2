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

variable "master_node_count" {
  type = number
  default = 1
  description = "value for the number of master nodes"
}

variable "worker_node_count" {
  type = number
  default = 0
  description = "value for the number of worker nodes"
}

variable "letsencrypt_issuer" {
  type = string
  description = "value for the letsencrypt issuer"
}

variable "rke2_version" {
  type = string
  default = ""
  description = "value for the rke2 version"
}