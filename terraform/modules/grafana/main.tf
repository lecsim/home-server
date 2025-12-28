terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.90"
    }
  }
}

resource "proxmox_virtual_environment_container" "grafana" {
  description  = "Grafana Dashboards Container"
  node_name    = var.proxmox_node
  vm_id        = null # Auto-assign
  unprivileged = true

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.dns]
    }

    user_account {
      keys     = var.ssh_public_key != "" ? [var.ssh_public_key] : []
      password = "terraform123"
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    type             = "debian"
  }

  disk {
    datastore_id = var.storage_location
    size         = tonumber(replace(var.disk_size, "G", ""))
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  features {
    nesting = true
  }

  started = true
}
