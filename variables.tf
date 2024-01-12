variable "hcloud_token" {
  sensitive   = true
  type        = string
  description = "API Personal Access Token."
}

###### Nomad
variable "nomad_server_count" {
  type        = number
  description = "Number of servers to create"
  default     = 1
}

variable "nomad_client_count" {
  type        = number
  description = "Number of clients to create"
  default     = 2
}

variable "enable_nomad_acls" {
  type        = bool
  description = "Bootstrap Nomad with ACLs"
  default     = true
}

variable "apt_consul_version" {
  type        = string
  description = "Consul version to install"
  default     = "1.17.1-1"
}

variable "apt_nomad_version" {
  type        = string
  description = "Nomad version to install"
  default     = "1.7.2-1"
}

###### Network
variable "hetzner_network_zone" {
  type        = string
  description = "Hetzner Cloud Network Zone"
  default     = "eu-central"
}

variable "virtual_network_cidr" {
  type        = string
  description = "CIDR of the virtual network"
  default     = "10.0.0.0/16"
}

##### Base
variable "location" {
  type    = string
  default = "nbg1"
}

variable "server_type" {
  type    = string
  default = "cax11"
}

variable "image" {
  type        = string
  description = "The image to use for the instances."
  default     = "ubuntu-22.04"
}

variable "load_balancer_type" {
  type        = string
  description = "The load balancer type to use."
  default     = "lb11"

}

variable "generate_ssh_key_file" {
  type        = bool
  description = "Defines whether the generated ssh key should be stored as local file."
  default     = false
}
