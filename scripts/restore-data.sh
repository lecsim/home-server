#!/bin/bash
# Restore-Script für Home-Server Daten
# Stellt Daten aus einem Backup in die Container wieder her

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <backup-path>"
  echo ""
  echo "Verfügbare Backups:"
  ls -lh /backup/home-server/ 2>/dev/null || echo "Keine Backups gefunden"
  exit 1
fi

BACKUP_PATH="$1"

if [ ! -d "$BACKUP_PATH" ]; then
  echo "Fehler: Backup-Verzeichnis nicht gefunden: $BACKUP_PATH"
  exit 1
fi

echo "=== Home-Server Restore ==="
echo "Restore von: $BACKUP_PATH"
echo ""

# Sicherheitsabfrage
read -p "WARNUNG: Bestehende Daten werden überschrieben! Fortfahren? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Abgebrochen."
  exit 0
fi

# Container IDs ermitteln
HOMEASSISTANT_CT=$(pct list | grep homeassistant | awk '{print $1}')
PROMETHEUS_CT=$(pct list | grep prometheus | awk '{print $1}')
GRAFANA_CT=$(pct list | grep grafana | awk '{print $1}')
PIHOLE_CT=$(pct list | grep pihole | awk '{print $1}')

# Container stoppen
echo "Stoppe Container..."
pct stop $HOMEASSISTANT_CT $PROMETHEUS_CT $GRAFANA_CT $PIHOLE_CT 2>/dev/null || true
sleep 3

# Daten wiederherstellen
echo "Stelle HomeAssistant Config wieder her..."
pct push $HOMEASSISTANT_CT "$BACKUP_PATH/homeassistant.tar.gz" /tmp/ha-restore.tar.gz
pct exec $HOMEASSISTANT_CT -- bash -c "cd /opt/homeassistant && tar xzf /tmp/ha-restore.tar.gz"

echo "Stelle Prometheus Daten wieder her..."
pct push $PROMETHEUS_CT "$BACKUP_PATH/prometheus.tar.gz" /tmp/prom-restore.tar.gz
pct exec $PROMETHEUS_CT -- bash -c "cd /var/lib && tar xzf /tmp/prom-restore.tar.gz && chown -R prometheus:prometheus prometheus"

echo "Stelle Grafana Daten wieder her..."
pct push $GRAFANA_CT "$BACKUP_PATH/grafana.tar.gz" /tmp/grafana-restore.tar.gz
pct exec $GRAFANA_CT -- bash -c "cd /var/lib && tar xzf /tmp/grafana-restore.tar.gz"

echo "Stelle PiHole Config wieder her..."
pct push $PIHOLE_CT "$BACKUP_PATH/pihole.tar.gz" /tmp/pihole-restore.tar.gz
pct exec $PIHOLE_CT -- bash -c "cd /etc && tar xzf /tmp/pihole-restore.tar.gz"

# Container starten
echo ""
echo "Starte Container..."
pct start $HOMEASSISTANT_CT $PROMETHEUS_CT $GRAFANA_CT $PIHOLE_CT

echo ""
echo "✓ Restore abgeschlossen!"
