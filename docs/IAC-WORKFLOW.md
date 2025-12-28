# Infrastructure as Code (IaC) - Vollständiger Workflow

Dieses Projekt verwendet einen vollständigen IaC-Ansatz für den Home-Server mit Terraform und Bash-Scripten.

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

```bash
cd terraform
terraform apply
cd ..
bash scripts/setup-from-proxmox.sh
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
