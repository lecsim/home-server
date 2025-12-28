output "container_id" {
  description = "Proxmox container ID"
  value       = proxmox_virtual_environment_container.pihole.id
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
  description = "PiHole admin interface URL"
  value       = "http://${split("/", var.ip_address)[0]}/admin"
}

output "default_password" {
  description = "Default admin password"
  value       = "admin (Bitte nach erstem Login ändern!)"
  sensitive   = true
}
