variable "hetzner_token" {
  type        = string
  description = "Hetzner Cloud API Token"
}

variable "domain" {
  type        = string
  description = "Domain for the cluster"
}

variable "master_node_count" {
  type        = number
  default     = 1
  description = "value for the number of master nodes"
}

variable "worker_node_count" {
  type        = number
  default     = 0
  description = "value for the number of worker nodes"
}

variable "cluster_name" {
  type        = string
  default     = "rke2"
  description = "value for the cluster name"

  validation {
    condition     = regex("^[a-z0-9]{1,20}$", var.cluster_name) != null
    error_message = "The cluster name must be lowercase and alphanumeric and must not be longer than 20 characters."
  }
}

variable "rke2_version" {
  type        = string
  default     = ""
  description = "value for the rke2 version"
}

variable "rke2_cni" {
  type        = string
  default     = "canal"
  description = "CNI type to use for the cluster"

  validation {
    condition     = contains(["canal","calico","cilium","none"], var.rke2_cni)
    error_message = "The value for CNI must be either 'canal', 'cilium', 'calico' or 'none'."
  }
}

variable "generate_ssh_key_file" {
  type        = bool
  default     = false
  description = "Defines whether the generated ssh key should be stored as local file."
}

variable "lb_location" {
  type        = string
  default     = "hel1"
  description = "Define the location for the management cluster loadbalancer."
}

variable "additional_lb_service_ports" {
  type        = list(string)
  default     = []
  description = "Define additional service ports for the management cluster loadbalancer."
}

variable "network_zone" {
  type        = string
  default     = "eu-central"
  description = "Define the network location for the cluster."
}

variable "node_locations" {
  type        = list(string)
  default     = ["hel1", "nbg1", "fsn1"]
  description = "Define the location in which nodes will be deployed. (Most be in the same network zone.)"
}

variable "master_node_image" {
  type        = string
  default     = "ubuntu-22.04"
  description = "Define the image for the master nodes."
}

variable "master_node_server_type" {
  type        = string
  default     = "cpx21"
  description = "Define the server type for the master nodes."
}

variable "worker_node_image" {
  type        = string
  default     = "ubuntu-22.04"
  description = "Define the image for the worker nodes."
}

variable "worker_node_server_type" {
  type        = string
  default     = "cpx21"
  description = "Define the server type for the worker nodes."
}

variable "cluster_configuration" {
  type = object({
    hcloud_controller = optional(object({
      version    = optional(string, "1.19.0")
      preinstall = optional(bool, true)
    }), {})
    monitoring_stack = optional(object({
      kube_prom_stack_version = optional(string, "45.25.0")
      loki_stack_version      = optional(string, "2.9.10")
      preinstall              = optional(bool, false)
    }), {})
    istio_service_mesh = optional(object({
      version    = optional(string, "1.18.0")
      preinstall = optional(bool, false)
    }), {})
    tracing_stack = optional(object({
      tempo_version = optional(string, "1.3.1")
      preinstall    = optional(bool, false)
    }), {})
    cert_manager = optional(object({
      version                         = optional(string, "1.13.3")
      preinstall                      = optional(bool, true)
      use_for_preinstalled_components = optional(bool, true)
    }), {})
  })
  default = {}
  description = "Define the cluster configuration. (See README.md for more information.)"

  validation {
    condition     = (var.cluster_configuration.monitoring_stack.preinstall == true && var.cluster_configuration.istio_service_mesh.preinstall == true) || var.cluster_configuration.tracing_stack.preinstall == false
    error_message = "The tracing stack can only be installed if the monitoring stack and the istio service mesh are installed."
  }
}

variable "enable_nginx_modsecurity_waf" {
  type        = bool
  default     = false
  description = "Defines whether the nginx modsecurity waf should be enabled."
}

variable "expose_kubernetes_metrics" {
  type        = bool
  default     = false
  description = "Defines whether the kubernetes metrics (scheduler, etcd, ...) should be exposed on the nodes."
}

variable "create_cloudflare_dns_record" {
  type        = bool
  default     = false
  description = "Defines whether a cloudflare dns record should be created for the cluster nodes."
}

variable "cloudflare_token" {
  type        = string
  default     = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  description = "The Cloudflare API token. (Required if create_cloudflare_dns_record is true.)"
}

variable "cloudflare_zone_id" {
  type        = string
  default     = ""
  description = "The Cloudflare zone id. (Required if create_cloudflare_dns_record is true.)"
}

variable "letsencrypt_issuer" {
  type        = string
  default     = ""
  description = "The email to send notifications regarding let's encrypt."
}

variable "enable_auto_os_updates" {
  type        = bool
  default     = true
  description = "Whether the OS should be updated automatically."
}

variable "enable_auto_kubernetes_updates" {
  type        = bool
  default     = true
  description = "Whether the kubernetes version should be updated automatically."
}

variable "preinstall_gateway_api_crds" {
  type        = bool
  default     = false
  description = "Whether the gateway api crds should be preinstalled."
}

variable "gateway_api_version" {
  type        = string
  default     = "v0.7.1"
  description = "The version of the gateway api to install."
}

variable "expose_oidc_issuer_url" {
  type        = bool
  default     = false
  description = "The exposed oidc issuer url. (If set enables oidc)"
}
