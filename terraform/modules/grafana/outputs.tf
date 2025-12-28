output "container_id" {
  description = "Proxmox container ID"
  value       = proxmox_virtual_environment_container.grafana.id
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
  description = "Grafana web interface URL"
  value       = "http://${split("/", var.ip_address)[0]}:3000"
}

output "default_credentials" {
  description = "Default login credentials"
  value       = "admin/admin"
  sensitive   = true
}
