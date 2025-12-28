####################
# HomeAssistant LXC Container
####################

module "homeassistant" {
  source = "./modules/homeassistant"
  count  = var.homeassistant_enabled ? 1 : 0

  proxmox_node     = var.proxmox_node
  storage_location = var.storage_location

  hostname = var.homeassistant_hostname
  ip_address = "${var.homeassistant_ip}${var.network_cidr}"
  gateway    = var.network_gateway
  dns        = var.network_dns
  bridge     = var.network_bridge

  cores     = var.homeassistant_cores
  memory    = var.homeassistant_memory
  disk_size = var.homeassistant_disk_size

  ssh_public_key = var.ssh_public_key
}

####################
# PiHole LXC Container
####################

module "pihole" {
  source = "./modules/pihole"
  count  = var.pihole_enabled ? 1 : 0

  proxmox_node     = var.proxmox_node
  storage_location = var.storage_location

  hostname   = var.pihole_hostname
  ip_address = "${var.pihole_ip}${var.network_cidr}"
  gateway    = var.network_gateway
  dns        = var.network_dns
  bridge     = var.network_bridge

  cores     = var.pihole_cores
  memory    = var.pihole_memory
  disk_size = var.pihole_disk_size

  ssh_public_key = var.ssh_public_key
}

####################
# Prometheus LXC Container
####################

module "prometheus" {
  source = "./modules/prometheus"
  count  = var.prometheus_enabled ? 1 : 0

  proxmox_node     = var.proxmox_node
  storage_location = var.storage_location

  hostname   = var.prometheus_hostname
  ip_address = "${var.prometheus_ip}${var.network_cidr}"
  gateway    = var.network_gateway
  dns        = var.network_dns
  bridge     = var.network_bridge

  cores     = var.prometheus_cores
  memory    = var.prometheus_memory
  disk_size = var.prometheus_disk_size

  ssh_public_key = var.ssh_public_key

  # Monitoring Targets
  homeassistant_ip = var.homeassistant_enabled ? var.homeassistant_ip : ""
  pihole_ip        = var.pihole_enabled ? var.pihole_ip : ""
  grafana_ip       = var.grafana_enabled ? var.grafana_ip : ""
}

####################
# Grafana LXC Container
####################

module "grafana" {
  source = "./modules/grafana"
  count  = var.grafana_enabled ? 1 : 0

  proxmox_node     = var.proxmox_node
  storage_location = var.storage_location

  hostname   = var.grafana_hostname
  ip_address = "${var.grafana_ip}${var.network_cidr}"
  gateway    = var.network_gateway
  dns        = var.network_dns
  bridge     = var.network_bridge

  cores     = var.grafana_cores
  memory    = var.grafana_memory
  disk_size = var.grafana_disk_size

  ssh_public_key = var.ssh_public_key

  # Prometheus Datasource
  prometheus_url = var.prometheus_enabled ? "http://${var.prometheus_ip}:9090" : ""
}
