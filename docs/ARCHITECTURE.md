# Architektur

## Überblick

Diese Infrastruktur nutzt Proxmox VE als Hypervisor und betreibt alle Services in isolierten LXC-Containern.

## Architektur-Diagramm

```
┌─────────────────────────────────────────────────────────────┐
│                    Lenovo ThinkCentre M910q                  │
│                         Proxmox VE                           │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │  HomeAssistant │  │     PiHole     │  │  Prometheus   │ │
│  │   LXC (Deb12)  │  │  LXC (Deb12)   │  │  LXC (Deb12)  │ │
│  │                │  │                │  │               │ │
│  │  :8123         │  │  :80, :53      │  │  :9090        │ │
│  │  2 Cores       │  │  1 Core        │  │  2 Cores      │ │
│  │  2048 MB RAM   │  │  512 MB RAM    │  │  1024 MB RAM  │ │
│  │  8 GB Disk     │  │  4 GB Disk     │  │  10 GB Disk   │ │
│  │                │  │                │  │               │ │
│  │  + Node Exp.   │  │  + Node Exp.   │  │  + Node Exp.  │ │
│  │    :9100       │  │    :9100       │  │    :9100      │ │
│  │                │  │  + PiHole Exp. │  │               │ │
│  │                │  │    :9617       │  │               │ │
│  └────────────────┘  └────────────────┘  └───────────────┘ │
│           │                  │                    │         │
│           └──────────────────┼────────────────────┘         │
│                              │                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                      Grafana                            │ │
│  │                   LXC (Debian 12)                       │ │
│  │                                                         │ │
│  │  :3000                                                  │ │
│  │  1 Core                                                 │ │
│  │  1024 MB RAM                                            │ │
│  │  8 GB Disk                                              │ │
│  │                                                         │ │
│  │  + Node Exporter :9100                                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                              │                              │
└──────────────────────────────┼──────────────────────────────┘
                               │
                        ┌──────▼──────┐
                        │   vmbr0     │
                        │  (Bridge)   │
                        └──────┬──────┘
                               │
                        ┌──────▼──────┐
                        │   Router    │
                        │  Gateway    │
                        └─────────────┘
```

## Netzwerk-Architektur

### IP-Adressen (Standard)

| Service | IP-Adresse | Ports | Beschreibung |
|---------|------------|-------|--------------|
| HomeAssistant | 192.168.1.10 | 8123, 9100 | Smart Home Hub |
| PiHole | 192.168.1.11 | 80, 53, 9100, 9617 | DNS + Ad-Blocker |
| Prometheus | 192.168.1.12 | 9090, 9100 | Metrics Collection |
| Grafana | 192.168.1.13 | 3000, 9100 | Monitoring Dashboards |

### Port-Übersicht

| Port | Service | Protokoll | Beschreibung |
|------|---------|-----------|--------------|
| 53 | PiHole | UDP/TCP | DNS Server |
| 80 | PiHole | TCP | Web Interface |
| 3000 | Grafana | TCP | Web Interface |
| 8123 | HomeAssistant | TCP | Web Interface |
| 9090 | Prometheus | TCP | Web Interface + API |
| 9100 | Node Exporter | TCP | System Metrics |
| 9617 | PiHole Exporter | TCP | PiHole Metrics |

## Container-Spezifikationen

### HomeAssistant Container

```
OS: Debian 12
CPU: 2 Cores
RAM: 2048 MB
Disk: 8 GB
Services:
  - HomeAssistant Core (Python venv)
  - Node Exporter
Features:
  - Nesting enabled (für Docker falls benötigt)
```

### PiHole Container

```
OS: Debian 12
CPU: 1 Core
RAM: 512 MB
Disk: 4 GB
Services:
  - PiHole
  - Node Exporter
  - PiHole Exporter
```

### Prometheus Container

```
OS: Debian 12
CPU: 2 Cores
RAM: 1024 MB
Disk: 10 GB
Services:
  - Prometheus Server
  - Node Exporter
Retention: 15 Tage (Standard)
```

### Grafana Container

```
OS: Debian 12
CPU: 1 Core
RAM: 1024 MB
Disk: 8 GB
Services:
  - Grafana Server
  - Node Exporter
Datasources:
  - Prometheus (auto-provisioned)
```

## Monitoring-Flow

```
┌─────────────────┐
│  HomeAssistant  │───┐
│  Node Exporter  │   │
└─────────────────┘   │
                      │
┌─────────────────┐   │    ┌─────────────────┐    ┌─────────────────┐
│     PiHole      │───┼───>│   Prometheus    │───>│     Grafana     │
│  Node Exporter  │   │    │                 │    │                 │
│  PiHole Export. │   │    │  Metrics DB     │    │   Dashboards    │
└─────────────────┘   │    │  Scraper        │    │   Datasource    │
                      │    └─────────────────┘    └─────────────────┘
┌─────────────────┐   │              │
│   Prometheus    │───┤              │
│  Node Exporter  │   │              │
└─────────────────┘   │              │
                      │              │
┌─────────────────┐   │              │
│     Grafana     │───┘              │
│  Node Exporter  │                  │
└─────────────────┘                  │
                                     │
                                     v
                              ┌─────────────────┐
                              │   Time Series   │
                              │   Database      │
                              │   (TSDB)        │
                              └─────────────────┘
```

## Datenfluss

1. **Metrics Collection**: Prometheus scraped alle Exporters alle 15 Sekunden
2. **Storage**: Metrics werden in Prometheus TSDB gespeichert
3. **Visualization**: Grafana liest Daten via PromQL aus Prometheus
4. **Alerting**: Prometheus kann Alerts an Alertmanager senden (optional)

## Terraform-Module

```
terraform/
├── main.tf                     # Modul-Orchestrierung
├── providers.tf                # Proxmox Provider
├── variables.tf                # Globale Variablen
├── outputs.tf                  # Output-Werte
└── modules/
    ├── homeassistant/
    │   ├── main.tf             # LXC Container + Installation
    │   ├── variables.tf        # Modul-Variablen
    │   └── outputs.tf          # Container-Outputs
    ├── pihole/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── prometheus/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── grafana/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Sicherheitsaspekte

### Container-Isolation

- Alle Container laufen **unprivileged** (erhöhte Sicherheit)
- Separate Netzwerk-Namespaces
- Resource-Limits via cgroups

### Netzwerk-Sicherheit

- Keine öffentlichen Ports (nur lokales Netzwerk)
- PiHole kann als DNS-Firewall fungieren
- SSH-Zugriff nur mit Key-Auth (empfohlen)

### Secrets-Management

- Terraform Variablen in `.gitignore`
- GitHub Actions Secrets für CI/CD
- Optional: HashiCorp Vault für erweiterte Secrets

## Skalierung

### Horizontale Skalierung

Weitere Services können einfach als Module hinzugefügt werden:

```hcl
module "nextcloud" {
  source = "./modules/nextcloud"
  # ...
}
```

### Vertikale Skalierung

Container-Ressourcen können in `terraform.tfvars` angepasst werden:

```hcl
prometheus_cores  = 4
prometheus_memory = 2048
```

## Backup-Strategie

### Proxmox Backups

```bash
# Automatisches Backup aller Container
pveum backup create <vmid> --storage <backup-storage> --mode snapshot
```

### Terraform State Backup

```bash
# Lokales State-Backup
cp terraform.tfstate terraform.tfstate.backup

# Remote State (empfohlen)
# Siehe providers.tf für Backend-Konfiguration
```

## Disaster Recovery

Bei Totalausfall:

1. Proxmox neu installieren
2. Debian 12 Template herunterladen
3. Terraform State wiederherstellen
4. `terraform apply` ausführen

Alle Container werden automatisch neu erstellt und konfiguriert.

## Performance-Optimierung

### Resource Allocation

- HomeAssistant: CPU-intensiv bei Automatisierungen
- PiHole: RAM-leicht, hauptsächlich DNS-Lookups
- Prometheus: Disk-I/O intensiv bei hohem Scrape-Intervall
- Grafana: RAM bei vielen Dashboards

### Best Practices

- SSD-Storage für Prometheus (TSDB)
- Regelmäßige Prometheus-Retention anpassen
- Grafana Caching aktivieren
- PiHole-Logs rotieren
