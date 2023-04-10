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