terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

resource "proxmox_lxc" "grafana" {
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

  # Startup Script für Grafana Installation
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y curl wget software-properties-common apt-transport-https",
      
      # Grafana Repository hinzufügen
      "mkdir -p /etc/apt/keyrings/",
      "wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main' | tee /etc/apt/sources.list.d/grafana.list",
      
      # Grafana installieren
      "apt-get update",
      "apt-get install -y grafana",
      
      # Grafana starten
      "systemctl daemon-reload",
      "systemctl enable grafana-server",
      "systemctl start grafana-server",
      
      # Warte bis Grafana bereit ist
      "sleep 10",
      
      # Prometheus Datasource konfigurieren (falls URL vorhanden)
      var.prometheus_url != "" ? "cat > /tmp/datasource.yaml << 'DSEOF'\napiVersion: 1\ndatasources:\n  - name: Prometheus\n    type: prometheus\n    access: proxy\n    url: ${var.prometheus_url}\n    isDefault: true\n    editable: true\nDSEOF" : "echo 'No Prometheus URL provided'",
      
      var.prometheus_url != "" ? "cp /tmp/datasource.yaml /etc/grafana/provisioning/datasources/prometheus.yaml" : "echo 'Skipping datasource configuration'",
      var.prometheus_url != "" ? "chown root:grafana /etc/grafana/provisioning/datasources/prometheus.yaml" : "echo 'Skipping chown'",
      var.prometheus_url != "" ? "systemctl restart grafana-server" : "echo 'Skipping restart'",
      
      # Node Exporter für Prometheus
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
