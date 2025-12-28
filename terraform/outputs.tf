####################
# HomeAssistant Outputs
####################

output "homeassistant_ip" {
  description = "HomeAssistant IP-Adresse"
  value       = var.homeassistant_enabled ? var.homeassistant_ip : null
}

output "homeassistant_url" {
  description = "HomeAssistant Web-URL"
  value       = var.homeassistant_enabled ? "http://${var.homeassistant_ip}:8123" : null
}

output "homeassistant_container_id" {
  description = "HomeAssistant Proxmox Container ID"
  value       = var.homeassistant_enabled ? module.homeassistant[0].container_id : null
}

####################
# PiHole Outputs
####################

output "pihole_ip" {
  description = "PiHole IP-Adresse"
  value       = var.pihole_enabled ? var.pihole_ip : null
}

output "pihole_url" {
  description = "PiHole Admin Web-URL"
  value       = var.pihole_enabled ? "http://${var.pihole_ip}/admin" : null
}

output "pihole_container_id" {
  description = "PiHole Proxmox Container ID"
  value       = var.pihole_enabled ? module.pihole[0].container_id : null
}

####################
# Prometheus Outputs
####################

output "prometheus_ip" {
  description = "Prometheus IP-Adresse"
  value       = var.prometheus_enabled ? var.prometheus_ip : null
}

output "prometheus_url" {
  description = "Prometheus Web-URL"
  value       = var.prometheus_enabled ? "http://${var.prometheus_ip}:9090" : null
}

output "prometheus_container_id" {
  description = "Prometheus Proxmox Container ID"
  value       = var.prometheus_enabled ? module.prometheus[0].container_id : null
}

####################
# Grafana Outputs
####################

output "grafana_ip" {
  description = "Grafana IP-Adresse"
  value       = var.grafana_enabled ? var.grafana_ip : null
}

output "grafana_url" {
  description = "Grafana Web-URL"
  value       = var.grafana_enabled ? "http://${var.grafana_ip}:3000" : null
}

output "grafana_container_id" {
  description = "Grafana Proxmox Container ID"
  value       = var.grafana_enabled ? module.grafana[0].container_id : null
}

output "grafana_default_credentials" {
  description = "Grafana Default Login-Credentials"
  value       = var.grafana_enabled ? "admin/admin (Bitte nach erstem Login ändern!)" : null
}

####################
# Summary Output
####################

output "service_summary" {
  description = "Übersicht aller Services"
  value = {
    homeassistant = var.homeassistant_enabled ? {
      ip  = var.homeassistant_ip
      url = "http://${var.homeassistant_ip}:8123"
    } : null
    pihole = var.pihole_enabled ? {
      ip  = var.pihole_ip
      url = "http://${var.pihole_ip}/admin"
    } : null
    prometheus = var.prometheus_enabled ? {
      ip  = var.prometheus_ip
      url = "http://${var.prometheus_ip}:9090"
    } : null
    grafana = var.grafana_enabled ? {
      ip  = var.grafana_ip
      url = "http://${var.grafana_ip}:3000"
    } : null
  }
}
