#!/bin/bash
# Backup-Script für Home-Server Daten
# Kopiert Daten aus den Containern auf den Proxmox Host

set -e

BACKUP_DIR="/backup/home-server"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"

echo "=== Home-Server Backup ==="
echo "Backup-Ziel: $BACKUP_PATH"
echo ""

# Backup-Verzeichnis erstellen
mkdir -p "$BACKUP_PATH"

# Container IDs ermitteln
HOMEASSISTANT_CT=$(pct list | grep homeassistant | awk '{print $1}')
PROMETHEUS_CT=$(pct list | grep prometheus | awk '{print $1}')
GRAFANA_CT=$(pct list | grep grafana | awk '{print $1}')
PIHOLE_CT=$(pct list | grep pihole | awk '{print $1}')

# Daten aus Containern sichern
echo "Sichere HomeAssistant Config..."
pct exec $HOMEASSISTANT_CT -- tar czf /tmp/ha-backup.tar.gz -C /opt/homeassistant config 2>/dev/null || true
pct pull $HOMEASSISTANT_CT /tmp/ha-backup.tar.gz "$BACKUP_PATH/homeassistant.tar.gz"

echo "Sichere Prometheus Daten..."
pct exec $PROMETHEUS_CT -- tar czf /tmp/prom-backup.tar.gz -C /var/lib prometheus 2>/dev/null || true
pct pull $PROMETHEUS_CT /tmp/prom-backup.tar.gz "$BACKUP_PATH/prometheus.tar.gz"

echo "Sichere Grafana Daten..."
pct exec $GRAFANA_CT -- tar czf /tmp/grafana-backup.tar.gz -C /var/lib grafana 2>/dev/null || true
pct pull $GRAFANA_CT /tmp/grafana-backup.tar.gz "$BACKUP_PATH/grafana.tar.gz"

echo "Sichere PiHole Config..."
pct exec $PIHOLE_CT -- tar czf /tmp/pihole-backup.tar.gz -C /etc pihole 2>/dev/null || true
pct pull $PIHOLE_CT /tmp/pihole-backup.tar.gz "$BACKUP_PATH/pihole.tar.gz"

# Backup-Info erstellen
cat > "$BACKUP_PATH/backup-info.txt" <<EOF
Backup erstellt: $(date)
Hostname: $(hostname)
Container IDs:
- HomeAssistant: $HOMEASSISTANT_CT
- Prometheus: $PROMETHEUS_CT
- Grafana: $GRAFANA_CT
- PiHole: $PIHOLE_CT
EOF

echo ""
echo "✓ Backup abgeschlossen: $BACKUP_PATH"
echo ""

# Optional: Alte Backups löschen (älter als 30 Tage)
find "$BACKUP_DIR" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true

# Backup-Größe anzeigen
echo "Backup-Größe:"
du -sh "$BACKUP_PATH"
