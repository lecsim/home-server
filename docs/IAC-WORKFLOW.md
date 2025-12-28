# Infrastructure as Code (IaC) - Vollständiger Workflow

Dieses Projekt verwendet einen vollständigen IaC-Ansatz für den Home-Server mit Terraform und Bash-Scripten.

## 💾 Datenpersistenz

**Wichtig:** Konfigurationsdaten werden **in den Containern** gespeichert. Um sie zu sichern, nutze die Backup-Scripts:

- HomeAssistant: `/opt/homeassistant/config`
- Prometheus: `/var/lib/prometheus`
- Grafana: `/var/lib/grafana`
- PiHole: `/etc/pihole`

**Vor einem Rebuild: Backup erstellen! Dann nach Rebuild: Restore.**

## 🏗️ Architektur

**Terraform** erstellt:
- 4 LXC Container (HomeAssistant, PiHole, Prometheus, Grafana)
- Netzwerk-Konfiguration
- Resource-Limits (CPU, RAM, Disk)

**Setup-Script** installiert:
- Home Assistant (Docker-basiert)
- PiHole
- Prometheus
- Grafana
- Node Exporters für Monitoring

## 🚀 Kompletter Deployment-Workflow

### Von Scratch (erstes Mal):

```bash
# 1. Terraform initialisieren
cd terraform
terraform init

# 2. Infrastructure erstellen
terraform apply

# 3. Software installieren
cd ..
bash scripts/setup-from-proxmox.sh
```

### Alles neu aufbauen:

```bash
# Alles löschen und neu erstellen
bash scripts/test-iac.sh
```

Oder manuell:

```bash
# 1. Alles zerstören
cd terraform
terraform destroy -auto-approve

# 2. Neu erstellen
terraform apply -auto-approve

# 3. Software installieren
cd ..
bash scripts/setup-from-proxmox.sh
```

## 📦 Was ist IaC-fähig?

✅ **Container-Erstellung** (Terraform)
- CPU, RAM, Disk Konfiguration
- IP-Adressen
- DNS Settings
- Unprivileged + Nesting

✅ **Software-Installation** (Setup-Script)
- Home Assistant Docker
- Prometheus + Node Exporters
- Grafana + Datasources
- PiHole DNS Server

✅ **Monitoring** (Auto-konfiguriert)
- Prometheus scrapet alle Targets
- Grafana mit Prometheus Datasource
- Node Exporter auf allen Containern

## 🔄 Updates

### Home Assistant aktualisieren:

```bash
ssh root@192.168.0.228 "pct exec 102 -- docker compose -f /opt/homeassistant/docker-compose.yml pull && docker compose -f /opt/homeassistant/docker-compose.yml up -d"
```

### Alles neu deployen (nach Code-Änderungen):

**Mit Datensicherung:**
```bash
# 1. Backup erstellen
bash scripts/backup-data.sh

# 2. Neu deployen
bash scripts/test-iac.sh

# 3. Daten wiederherstellen
bash scripts/restore-data.sh /backup/home-server/YYYYMMDD_HHMMSS
```

**Ohne Daten (fris (sichert Daten AUS den Containern)che Installation):**
```bash
bash scripts/test-iac.sh
```

## 💾 Backup & Restore

### Backup erstellen

**Auf dem Proxmox Host:**
```bash
# Manuelles Backup
bash scripts/backup-data.sh

# Backups liegen in: /backup/home-server/YYYYMMDD_HHMMSS/
```

**Automatisches Backup (Cronjob):**
```bash
# Tägliches Backup um 3 Uhr nachts - auf Proxmox Host ausführen:
crontab -e
# Dann hinzufügen:
0 3 * * * /root/home-server/scripts/backup-data.sh
```

### Daten wiederherstellen

```bash
# Verfügbare Backups anzeigen
bash scripts/restore-data.sh

# Restore ausführen
bash scripts/restore-data.sh /backup/home-server/20231228_030000
```

### Externes Backup

Sichere `/backup/` auf ein externes Medium:

```bash
# Mit rsync zu NAS/USB
rsync -avz /backup/home-server/ /mnt/nas/home-server-backups/

# Oder mit tar
tar czf /mnt/usb/home-server-$(date +%Y%m%d).tar.gz /backup/home-server
```

## 🧪 Testen ob alles funktioniert:

```bash
# Nach Deployment prüfen:
curl http://192.168.0.10:8123  # Home Assistant (HTTP 302)
curl http://192.168.0.12:9090  # Prometheus (HTTP 302)
curl http://192.168.0.13:3000  # Grafana (HTTP 302)
curl http://192.168.0.11/admin # PiHole (HTTP 301)
```

## 📝 Wichtige Dateien

- `terraform/main.tf` - Hauptkonfiguration (Module)
- `terraform/modules/*/main.tf` - Container-Definitionen
- `scripts/setup-from-proxmox.sh` - Software-Installation
- `scripts/test-iac.sh` - Kompletter Test-Workflow

## 🎯 Das Ziel ist erreicht

**Alles kann gelöscht und neu aufgebaut werden!**

```bash
bash scripts/test-iac.sh
```

Nach ~10 Minuten sind alle Services bereit:
- ✅ Home Assistant: http://192.168.0.10:8123
- ✅ Prometheus: http://192.168.0.12:9090
- ✅ Grafana: http://192.168.0.13:3000
- ✅ PiHole: http://192.168.0.11/admin
