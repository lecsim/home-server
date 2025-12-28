output "container_id" {
  description = "Proxmox container ID"
  value       = proxmox_lxc.prometheus.vmid
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
  description = "Prometheus web interface URL"
  value       = "http://${split("/", var.ip_address)[0]}:9090"
}
