####################
# Proxmox Connection
####################

variable "proxmox_api_url" {
  description = "Proxmox API URL (z.B. https://192.168.1.100:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID (z.B. root@pam!terraform)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "TLS-Zertifikat-Validierung überspringen (für selbstsignierte Zertifikate)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Name des Proxmox Nodes"
  type        = string
  default     = "pve"
}

####################
# Network Configuration
####################

variable "network_bridge" {
  description = "Netzwerk-Bridge für Container"
  type        = string
  default     = "vmbr0"
}

variable "network_gateway" {
  description = "Standard-Gateway"
  type        = string
}

variable "network_dns" {
  description = "DNS-Server"
  type        = string
}

variable "network_cidr" {
  description = "CIDR Notation für Netzwerk (z.B. /24)"
  type        = string
  default     = "/24"
}

####################
# Storage
####################

variable "storage_location" {
  description = "Proxmox Storage für Container"
  type        = string
  default     = "local-lvm"
}

####################
# HomeAssistant
####################

variable "homeassistant_enabled" {
  description = "HomeAssistant Container aktivieren"
  type        = bool
  default     = true
}

variable "homeassistant_ip" {
  description = "IP-Adresse für HomeAssistant"
  type        = string
}

variable "homeassistant_hostname" {
  description = "Hostname für HomeAssistant"
  type        = string
  default     = "homeassistant"
}

variable "homeassistant_cores" {
  description = "CPU-Kerne für HomeAssistant"
  type        = number
  default     = 2
}

variable "homeassistant_memory" {
  description = "RAM in MB für HomeAssistant"
  type        = number
  default     = 2048
}

variable "homeassistant_disk_size" {
  description = "Disk-Größe für HomeAssistant (z.B. 8G)"
  type        = string
  default     = "8G"
}

####################
# PiHole
####################

variable "pihole_enabled" {
  description = "PiHole Container aktivieren"
  type        = bool
  default     = true
}

variable "pihole_ip" {
  description = "IP-Adresse für PiHole"
  type        = string
}

variable "pihole_hostname" {
  description = "Hostname für PiHole"
  type        = string
  default     = "pihole"
}

variable "pihole_cores" {
  description = "CPU-Kerne für PiHole"
  type        = number
  default     = 1
}

variable "pihole_memory" {
  description = "RAM in MB für PiHole"
  type        = number
  default     = 512
}

variable "pihole_disk_size" {
  description = "Disk-Größe für PiHole (z.B. 4G)"
  type        = string
  default     = "4G"
}

####################
# Prometheus
####################

variable "prometheus_enabled" {
  description = "Prometheus Container aktivieren"
  type        = bool
  default     = true
}

variable "prometheus_ip" {
  description = "IP-Adresse für Prometheus"
  type        = string
}

variable "prometheus_hostname" {
  description = "Hostname für Prometheus"
  type        = string
  default     = "prometheus"
}

variable "prometheus_cores" {
  description = "CPU-Kerne für Prometheus"
  type        = number
  default     = 2
}

variable "prometheus_memory" {
  description = "RAM in MB für Prometheus"
  type        = number
  default     = 1024
}

variable "prometheus_disk_size" {
  description = "Disk-Größe für Prometheus (z.B. 10G)"
  type        = string
  default     = "10G"
}

####################
# Grafana
####################

variable "grafana_enabled" {
  description = "Grafana Container aktivieren"
  type        = bool
  default     = true
}

variable "grafana_ip" {
  description = "IP-Adresse für Grafana"
  type        = string
}

variable "grafana_hostname" {
  description = "Hostname für Grafana"
  type        = string
  default     = "grafana"
}

variable "grafana_cores" {
  description = "CPU-Kerne für Grafana"
  type        = number
  default     = 1
}

variable "grafana_memory" {
  description = "RAM in MB für Grafana"
  type        = number
  default     = 1024
}

variable "grafana_disk_size" {
  description = "Disk-Größe für Grafana (z.B. 8G)"
  type        = string
  default     = "8G"
}

####################
# SSH Configuration
####################

variable "ssh_public_key" {
  description = "SSH Public Key für Container-Zugriff"
  type        = string
  default     = ""
}
