variable "hetzner_token" {
  type        = string
  description = "Hetzner Cloud API Token"
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

variable "rke2_version" {
  type = string
  default = ""
  description = "value for the rke2 version"
}

variable "generate_ssh_key_file" {
  type = bool
  default = false
  description = "Defines whether the generated ssh key should be stored as local file."
}

variable "additional_lb_service_ports" {
  type = list(string)
  default = []
  description = "Define additional service ports for the management cluster loadbalancer."
}

variable "network_zone" {
  type = string
  default = "eu-central"
  description = "Define the network location for the cluster."
}

variable "node_locations" {
  type = list(string)
  default = ["hel1", "nbg1", "fsn1"]
  description = "Define the location in which nodes will be deployed. (Most be in the same network zone.)"
}

variable "master_node_image" {
  type = string
  default = "ubuntu-22.04"
  description = "Define the image for the master nodes."
}

variable "master_node_server_type" {
  type = string
  default = "cpx21"
  description = "Define the server type for the master nodes."
}

variable "worker_node_image" {
  type = string
  default = "ubuntu-22.04"
  description = "Define the image for the worker nodes."
}

variable "worker_node_server_type" {
  type = string
  default = "cpx21"
  description = "Define the server type for the worker nodes."
}

variable "preinstall_hcloud_controller" {
  type = bool
  default = true
  description = "Defines whether the Hetzner Cloud Controller should be preinstalled into the cluster."
}

variable "preinstall_monitoring_stack" {
  type = bool
  default = false
  description = "Defines whether the kube prometheus stack helm chart should be preinstalled into the cluster."
}

variable "expose_kubernetes_metrics" {
  type = bool
  default = false
  description = "Defines whether the kubernetes metrics (scheduler, etcd, ...) should be exposed on the nodes."
}

variable "create_cloudflare_dns_record" {
  type = bool
  default = false
  description = "Defines whether a cloudflare dns record should be created for the cluster nodes."
}

variable "cloudflare_token" {
  type = string
  default = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
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

variable "use_cluster_managed_tls_certificates" {
  type = bool
  default = true
  description = "Whether cert manager should be installed on the cluster. If not the CF DNS records will be proxied instead."
}

variable "letsencrypt_issuer" {
  type = string
  default = ""
  description = "The email to send notifications regarding let's encrypt."
}