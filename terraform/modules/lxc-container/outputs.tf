output "container_id" {
  description = "ID of the created container"
  value       = proxmox_virtual_environment_container.container.id
}

output "hostname" {
  description = "Container hostname"
  value       = proxmox_virtual_environment_container.container.initialization[0].hostname
}

output "ip_address" {
  description = "Container IP address"
  value       = proxmox_virtual_environment_container.container.initialization[0].ip_config[0].ipv4[0].address
}
