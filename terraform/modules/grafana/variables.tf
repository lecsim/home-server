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
  description = "IP address with CIDR (e.g., 192.168.1.13/24)"
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
  description = "Disk size (e.g., 8G)"
  type        = string
}

variable "prometheus_url" {
  description = "Prometheus URL for datasource (e.g., 192.168.0.12:9090)"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for access"
}
