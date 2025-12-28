variable "description" {
  description = "Container description"
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "storage_location" {
  description = "Storage location for container disk"
  type        = string
}

variable "hostname" {
  description = "Container hostname"
  type        = string
}

variable "ip_address" {
  description = "Container IP address with CIDR"
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
  description = "Disk size (e.g., '8G')"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for root user"
  type        = string
  default     = ""
}

variable "nesting" {
  description = "Enable nesting (required for Docker)"
  type        = bool
  default     = false
}
