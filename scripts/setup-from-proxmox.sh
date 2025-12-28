#!/bin/bash
# Setup-Skript zum Ausführen auf dem Proxmox-Host
# Setzt Passwörter und installiert Software auf allen Containern

set -e

echo "=== Container Setup auf Proxmox Host ==="
echo ""

# Container IDs dynamisch ermitteln
echo "Ermittle Container IDs..."
HOMEASSISTANT_CT=$(pct list | grep homeassistant | awk '{print $1}')
PIHOLE_CT=$(pct list | grep pihole | awk '{print $1}')
PROMETHEUS_CT=$(pct list | grep prometheus | awk '{print $1}')
GRAFANA_CT=$(pct list | grep grafana | awk '{print $1}')

echo "  HomeAssistant: $HOMEASSISTANT_CT"
echo "  PiHole: $PIHOLE_CT"
echo "  Prometheus: $PROMETHEUS_CT"
echo "  Grafana: $GRAFANA_CT"
echo ""

# Passwort setzen
echo "Schritt 1: Root-Passwörter setzen..."
for ct in $HOMEASSISTANT_CT $PIHOLE_CT $PROMETHEUS_CT $GRAFANA_CT; do
  echo "  Container $ct..."
  pct exec $ct -- bash -c 'echo "root:terraform123" | chpasswd'
done
echo "✓ Passwörter gesetzt"
echo ""

# ============================
# HomeAssistant Installation (Docker-based)
# ============================
echo "=== 1. HomeAssistant Installation ===" 
pct exec $HOMEASSISTANT_CT -- bash -c '
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
apt-get update && apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

mkdir -p /opt/homeassistant/config

cat > /opt/homeassistant/docker-compose.yml <<DOCKEREOF
version: "3"
services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    volumes:
      - /opt/homeassistant/config:/config
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
    privileged: true
    network_mode: host
DOCKEREOF

cat > /etc/systemd/system/homeassistant.service <<HAEOF
[Unit]
Description=Home Assistant Docker Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/homeassistant
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
HAEOF

systemctl daemon-reload
systemctl enable --now homeassistant.service

# Node Exporter
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-1.8.2.linux-amd64.tar.gz
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.8.2.linux-amd64*

cat > /etc/systemd/system/node_exporter.service <<NODEEOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
NODEEOF

systemctl daemon-reload
systemctl enable --now node_exporter.service
'
echo "✓ HomeAssistant installiert"
echo ""

# ============================
# PiHole Installation
# ============================
echo "=== 2. PiHole Installation ==="
pct exec $PIHOLE_CT -- bash -c '
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
apt-get update && apt-get install -y curl

mkdir -p /etc/pihole
cat > /etc/pihole/setupVars.conf <<PIEOF
PIHOLE_INTERFACE=eth0
PIHOLE_DNS_1=8.8.8.8
PIHOLE_DNS_2=8.8.4.4
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=single
WEBPASSWORD=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
IPV4_ADDRESS=192.168.0.11/24
IPV6_ADDRESS=
PIHOLE_SKIP_OS_CHECK=true
PIEOF

curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended || echo "PiHole installation may have warnings - continuing"

# Wait for PiHole to be ready
sleep 5

# Set password if pihole command exists
if command -v pihole &> /dev/null; then
  pihole -a -p admin
fi

# Node Exporter
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-1.8.2.linux-amd64.tar.gz
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.8.2.linux-amd64*

cat > /etc/systemd/system/node_exporter.service <<NODEEOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
NODEEOF

systemctl daemon-reload
systemctl enable --now node_exporter.service

# PiHole Exporter (optional - skip if download fails)
wget -q https://github.com/eko/pihole-exporter/releases/download/v0.4.0/pihole_exporter-0.4.0_linux_amd64.tar.gz && \
tar xzf pihole_exporter-0.4.0_linux_amd64.tar.gz && \
cp pihole_exporter /usr/local/bin/ && \
rm -rf pihole_exporter* && \
cat > /etc/systemd/system/pihole_exporter.service <<PIEXPEOF
[Unit]
Description=PiHole Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/pihole_exporter -pihole_hostname 127.0.0.1
Restart=on-failure

[Install]
WantedBy=multi-user.target
PIEXPEOF
systemctl daemon-reload
systemctl enable --now pihole_exporter.service || echo "PiHole Exporter installation skipped"
'
echo "✓ PiHole installiert"
echo ""

# ============================
# Prometheus Installation
# ============================
echo "=== 3. Prometheus Installation ==="
pct exec $PROMETHEUS_CT -- bash -c '
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
apt-get update && apt-get install -y curl wget

useradd --no-create-home --shell /bin/false prometheus || true

wget -q https://github.com/prometheus/prometheus/releases/download/v3.0.1/prometheus-3.0.1.linux-amd64.tar.gz
tar xzf prometheus-3.0.1.linux-amd64.tar.gz
cp prometheus-3.0.1.linux-amd64/prometheus /usr/local/bin/
cp prometheus-3.0.1.linux-amd64/promtool /usr/local/bin/
mkdir -p /etc/prometheus /var/lib/prometheus
cp -r prometheus-3.0.1.linux-amd64/consoles /etc/prometheus 2>/dev/null || true
cp -r prometheus-3.0.1.linux-amd64/console_libraries /etc/prometheus 2>/dev/null || true
rm -rf prometheus-3.0.1.linux-amd64*

cat > /etc/prometheus/prometheus.yml <<PROMEOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  
  - job_name: "homeassistant"
    static_configs:
      - targets: ["192.168.0.10:9100"]
  
  - job_name: "pihole"
    static_configs:
      - targets: ["192.168.0.11:9100", "192.168.0.11:9617"]
  
  - job_name: "grafana"
    static_configs:
      - targets: ["192.168.0.13:9100"]
PROMEOF

cat > /etc/systemd/system/prometheus.service <<PROMSVCEOF
[Unit]
Description=Prometheus
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus
Restart=on-failure

[Install]
WantedBy=multi-user.target
PROMSVCEOF

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

systemctl daemon-reload
systemctl enable --now prometheus.service

# Node Exporter
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-1.8.2.linux-amd64.tar.gz
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.8.2.linux-amd64*

cat > /etc/systemd/system/node_exporter.service <<NODEEOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
NODEEOF

systemctl daemon-reload
systemctl enable --now node_exporter.service
'
echo "✓ Prometheus installiert"
echo ""

# ============================
# Grafana Installation
# ============================
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
echo "=== 4. Grafana Installation ==="
pct exec $GRAFANA_CT -- bash -c '
apt-get update && apt-get install -y curl wget apt-transport-https software-properties-common

mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list

apt-get update
apt-get install -y grafana

mkdir -p /etc/grafana/provisioning/datasources
cat > /etc/grafana/provisioning/datasources/prometheus.yml <<GRAFEOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://192.168.0.12:9090
    isDefault: true
    editable: true
GRAFEOF

systemctl daemon-reload
systemctl enable --now grafana-server

# Node Exporter
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-1.8.2.linux-amd64.tar.gz
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.8.2.linux-amd64*

cat > /etc/systemd/system/node_exporter.service <<NODEEOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
NODEEOF

systemctl daemon-reload
systemctl enable --now node_exporter.service
'
echo "✓ Grafana installiert"
echo ""

echo "=== Setup abgeschlossen! ==="
echo ""
echo "Services:"
echo "  • HomeAssistant: http://192.168.0.10:8123"
echo "  • PiHole:        http://192.168.0.11/admin (admin/admin)"
echo "  • Prometheus:    http://192.168.0.12:9090"
echo "  • Grafana:       http://192.168.0.13:3000 (admin/admin)"
echo ""
echo "Container Root-Passwort: terraform123"
