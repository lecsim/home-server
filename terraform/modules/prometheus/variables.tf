variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "storage_location" {
  description = "Storage location for container"
  type        = string
}

variable "hostname" {
  description = "Container hostname"
  type        = string
}

variable "ip_address" {
  description = "IP address with CIDR (e.g., 192.168.1.12/24)"
  type        = string
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "dns" {
  description = "DNS server"
  type        = string
}

variable "bridge" {
  description = "Network bridge"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
}

variable "memory" {
  description = "Memory in MB"
  type        = number
}

variable "disk_size" {
  description = "Disk size (e.g., 10G)"
  type        = string
}

variable "homeassistant_ip" {
  description = "HomeAssistant IP address"
  type        = string
}

variable "pihole_ip" {
  description = "PiHole IP address"
  type        = string
}

variable "grafana_ip" {
  description = "Grafana IP address"
  type        = string
}

variable "ssh_public_key" {
}
