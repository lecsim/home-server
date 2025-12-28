terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

resource "proxmox_lxc" "pihole" {
  target_node  = var.proxmox_node
  hostname     = var.hostname
  ostemplate   = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
  unprivileged = true
  onboot       = true
  start        = true

  cores  = var.cores
  memory = var.memory

  rootfs {
    storage = var.storage_location
    size    = var.disk_size
  }

  network {
    name   = "eth0"
    bridge = var.bridge
    ip     = var.ip_address
    gw     = var.gateway
  }

  nameserver = var.dns

  # SSH-Key konfigurieren falls vorhanden
  ssh_public_keys = var.ssh_public_key != "" ? var.ssh_public_key : null

  # Features aktivieren
  features {
    nesting = false
  }

  # Startup Script für PiHole Installation
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y curl wget",
      
      # PiHole Installation
      "curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended",
      
      # Web-Passwort setzen (Standard: admin)
      "pihole -a -p admin",
      
      # Node Exporter für Prometheus installieren
      "wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz",
      "tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz",
      "mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/",
      "rm -rf node_exporter-1.7.0.linux-amd64*",
      
      # Node Exporter Systemd Service
      "cat > /etc/systemd/system/node_exporter.service << 'EOF'",
      "[Unit]",
      "Description=Node Exporter",
      "After=network.target",
      "",
      "[Service]",
      "Type=simple",
      "ExecStart=/usr/local/bin/node_exporter",
      "Restart=on-failure",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      
      "systemctl daemon-reload",
      "systemctl enable node_exporter.service",
      "systemctl start node_exporter.service",
      
      # PiHole Exporter für detaillierte Metriken
      "wget https://github.com/eko/pihole-exporter/releases/download/v0.4.0/pihole_exporter-linux-amd64",
      "mv pihole_exporter-linux-amd64 /usr/local/bin/pihole_exporter",
      "chmod +x /usr/local/bin/pihole_exporter",
      
      # PiHole Exporter Service
      "cat > /etc/systemd/system/pihole_exporter.service << 'EOF'",
      "[Unit]",
      "Description=PiHole Exporter",
      "After=network.target",
      "",
      "[Service]",
      "Type=simple",
      "ExecStart=/usr/local/bin/pihole_exporter",
      "Environment=\"PIHOLE_HOSTNAME=127.0.0.1\"",
      "Environment=\"PIHOLE_PORT=80\"",
      "Environment=\"PORT=9617\"",
      "Restart=on-failure",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      
      "systemctl daemon-reload",
      "systemctl enable pihole_exporter.service",
      "systemctl start pihole_exporter.service"
    ]

    connection {
      type = "ssh"
      user = "root"
      host = split("/", var.ip_address)[0]
    }
  }
}
