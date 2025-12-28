output "container_id" {
  description = "Proxmox container ID"
  value       = proxmox_virtual_environment_container.homeassistant.id
}

output "ip_address" {
  description = "Container IP address"
  value       = split("/", var.ip_address)[0]
}

output "hostname" {
  description = "Container hostname"
  value       = var.hostname
}

output "web_url" {
  description = "HomeAssistant web interface URL"
  value       = "http://${split("/", var.ip_address)[0]}:8123"
}
