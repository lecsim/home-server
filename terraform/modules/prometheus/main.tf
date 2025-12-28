terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

resource "proxmox_lxc" "prometheus" {
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

  # Startup Script für Prometheus Installation
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y curl wget",
      
      # Prometheus User erstellen
      "useradd --no-create-home --shell /bin/false prometheus || true",
      
      # Prometheus installieren
      "wget https://github.com/prometheus/prometheus/releases/download/v2.48.0/prometheus-2.48.0.linux-amd64.tar.gz",
      "tar xvfz prometheus-2.48.0.linux-amd64.tar.gz",
      "mv prometheus-2.48.0.linux-amd64/prometheus /usr/local/bin/",
      "mv prometheus-2.48.0.linux-amd64/promtool /usr/local/bin/",
      "mkdir -p /etc/prometheus /var/lib/prometheus",
      "mv prometheus-2.48.0.linux-amd64/consoles /etc/prometheus",
      "mv prometheus-2.48.0.linux-amd64/console_libraries /etc/prometheus",
      "rm -rf prometheus-2.48.0.linux-amd64*",
      "chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus",
      
      # Prometheus Konfiguration erstellen
      "cat > /etc/prometheus/prometheus.yml << 'PROMEOF'",
      "global:",
      "  scrape_interval: 15s",
      "  evaluation_interval: 15s",
      "",
      "scrape_configs:",
      "  # Prometheus selbst",
      "  - job_name: 'prometheus'",
      "    static_configs:",
      "      - targets: ['localhost:9090']",
      "",
      "  # Node Exporter auf allen Hosts",
      "  - job_name: 'node_exporter'",
      "    static_configs:",
      "      - targets:",
      "        - '${split("/", var.ip_address)[0]}:9100'",
      var.homeassistant_ip != "" ? "        - '${var.homeassistant_ip}:9100'" : "",
      var.pihole_ip != "" ? "        - '${var.pihole_ip}:9100'" : "",
      var.grafana_ip != "" ? "        - '${var.grafana_ip}:9100'" : "",
      "",
      var.pihole_ip != "" ? "  # PiHole Exporter" : "",
      var.pihole_ip != "" ? "  - job_name: 'pihole'" : "",
      var.pihole_ip != "" ? "    static_configs:" : "",
      var.pihole_ip != "" ? "      - targets: ['${var.pihole_ip}:9617']" : "",
      "PROMEOF",
      
      "chown prometheus:prometheus /etc/prometheus/prometheus.yml",
      
      # Systemd Service erstellen
      "cat > /etc/systemd/system/prometheus.service << 'EOF'",
      "[Unit]",
      "Description=Prometheus",
      "Wants=network-online.target",
      "After=network-online.target",
      "",
      "[Service]",
      "User=prometheus",
      "Group=prometheus",
      "Type=simple",
      "ExecStart=/usr/local/bin/prometheus \\",
      "  --config.file=/etc/prometheus/prometheus.yml \\",
      "  --storage.tsdb.path=/var/lib/prometheus/ \\",
      "  --web.console.templates=/etc/prometheus/consoles \\",
      "  --web.console.libraries=/etc/prometheus/console_libraries",
      "Restart=on-failure",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      
      # Service aktivieren und starten
      "systemctl daemon-reload",
      "systemctl enable prometheus.service",
      "systemctl start prometheus.service",
      
      # Node Exporter für Prometheus selbst
      "wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz",
      "tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz",
      "mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/",
      "rm -rf node_exporter-1.7.0.linux-amd64*",
      
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
      "systemctl start node_exporter.service"
    ]

    connection {
      type = "ssh"
      user = "root"
      host = split("/", var.ip_address)[0]
    }
  }
}
