terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

resource "proxmox_lxc" "homeassistant" {
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
    nesting = true # Für Docker in LXC falls benötigt
  }

  # Startup Script für HomeAssistant Installation
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y curl wget software-properties-common apt-transport-https ca-certificates",
      
      # Python und Dependencies installieren
      "apt-get install -y python3 python3-dev python3-venv python3-pip",
      "apt-get install -y libffi-dev libssl-dev libjpeg-dev zlib1g-dev autoconf build-essential",
      "apt-get install -y libopenjp2-7 libtiff6 libturbojpeg0-dev tzdata",
      
      # HomeAssistant User erstellen
      "useradd -rm homeassistant -G dialout,gpio,i2c || true",
      "mkdir -p /srv/homeassistant",
      "chown homeassistant:homeassistant /srv/homeassistant",
      
      # Virtual Environment erstellen
      "sudo -u homeassistant -H -s bash -c 'python3 -m venv /srv/homeassistant'",
      "sudo -u homeassistant -H -s bash -c 'source /srv/homeassistant/bin/activate && pip3 install --upgrade pip'",
      "sudo -u homeassistant -H -s bash -c 'source /srv/homeassistant/bin/activate && pip3 install wheel'",
      "sudo -u homeassistant -H -s bash -c 'source /srv/homeassistant/bin/activate && pip3 install homeassistant'",
      
      # Systemd Service erstellen
      "cat > /etc/systemd/system/homeassistant.service << 'EOF'",
      "[Unit]",
      "Description=Home Assistant",
      "After=network-online.target",
      "",
      "[Service]",
      "Type=simple",
      "User=homeassistant",
      "ExecStart=/srv/homeassistant/bin/hass -c /home/homeassistant/.homeassistant",
      "Restart=on-failure",
      "RestartSec=5s",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      
      # Service aktivieren und starten
      "systemctl daemon-reload",
      "systemctl enable homeassistant.service",
      "systemctl start homeassistant.service",
      
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
      "systemctl start node_exporter.service"
    ]

    connection {
      type = "ssh"
      user = "root"
      host = split("/", var.ip_address)[0]
    }
  }
}
