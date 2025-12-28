# Home Server Infrastructure

Infrastructure as Code (IaC) für Home-Server Setup auf Proxmox VE.

## 🏗️ Architektur

### Hardware
- **Host**: Lenovo ThinkCentre M910q
- **Hypervisor**: Proxmox VE

### Services
- **HomeAssistant**: Smart Home Automation
- **PiHole**: Netzwerk-weiter Ad-Blocker und DNS
- **Prometheus**: Metrics Collection
- **Grafana**: Monitoring Dashboards

## 📋 Voraussetzungen

### Proxmox Setup
- Proxmox VE installiert und erreichbar
- SSH-Zugriff auf Proxmox Host
- API-Token erstellt (siehe [Setup-Anleitung](#proxmox-api-token-erstellen))

### Lokale Tools
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Git](https://git-scm.com/downloads)
- SSH-Client

## 🚀 Quick Start

### 1. Repository klonen
```bash
git clone https://github.com/yourusername/home-server.git
cd home-server
```

### 2. Terraform-Variablen konfigurieren
```bash
cp terraform.tfvars.example terraform.tfvars
# Bearbeite terraform.tfvars mit deinen Proxmox-Credentials
```

### 3. Terraform initialisieren und anwenden
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## 🔧 Konfiguration

### Proxmox API Token erstellen

1. In Proxmox Web UI einloggen
2. Navigiere zu **Datacenter → Permissions → API Tokens**
3. Klicke auf **Add** und erstelle einen Token:
   - User: `root@pam`
   - Token ID: `terraform`
   - Privilege Separation: **Deaktiviert**
4. Notiere den Token-Secret (wird nur einmal angezeigt!)

### Terraform Variables

Wichtige Variablen in `terraform.tfvars`:

```hcl
# Proxmox Connection
proxmox_api_url      = "https://proxmox-ip:8006/api2/json"
proxmox_api_token_id = "root@pam!terraform"
proxmox_api_token    = "your-token-secret"

# Network Configuration
network_gateway      = "192.168.1.1"
network_dns          = "192.168.1.1"

# IP Addresses
homeassistant_ip     = "192.168.1.10"
pihole_ip            = "192.168.1.11"
prometheus_ip        = "192.168.1.12"
grafana_ip           = "192.168.1.13"
```

## 📊 Services

### HomeAssistant
- **URL**: http://192.168.1.10:8123
- **Container**: LXC
- **OS**: Debian 12

### PiHole
- **URL**: http://192.168.1.11/admin
- **Container**: LXC
- **OS**: Debian 12

### Prometheus
- **URL**: http://192.168.1.12:9090
- **Container**: LXC
- **OS**: Debian 12

### Grafana
- **URL**: http://192.168.1.13:3000
- **Default Login**: admin/admin
- **Container**: LXC
- **OS**: Debian 12

## 🔄 Deployment

### Manuelles Deployment
```bash
cd terraform
terraform apply
```

### Automatisches Deployment via GitHub Actions
Push nach `main` Branch triggert automatisches Deployment (siehe `.github/workflows/deploy.yml`)

## 📝 Projektstruktur

```
home-server/
├── terraform/
│   ├── main.tf                 # Hauptkonfiguration
│   ├── variables.tf            # Variable Definitionen
│   ├── outputs.tf              # Output Definitionen
│   ├── providers.tf            # Provider Konfiguration
│   ├── modules/
│   │   ├── homeassistant/      # HomeAssistant Modul
│   │   ├── pihole/             # PiHole Modul
│   │   ├── prometheus/         # Prometheus Modul
│   │   └── grafana/            # Grafana Modul
│   └── terraform.tfvars.example
├── ansible/                     # Ansible Playbooks (optional)
├── monitoring/
│   ├── prometheus/             # Prometheus Config
│   └── grafana/                # Grafana Dashboards
└── .github/
    └── workflows/
        └── deploy.yml          # CI/CD Pipeline
```

## 🛠️ Wartung

### Container Updates
```bash
# Einzelnen Container updaten
terraform taint module.homeassistant.proxmox_lxc.container
terraform apply

# Alle Container neu erstellen
terraform destroy -target=module.homeassistant
terraform apply
```

### Backup
```bash
# Terraform State Backup
cp terraform.tfstate terraform.tfstate.backup

# Proxmox Backup erstellt automatisch Snapshots
```

## 🔒 Sicherheit

- Terraform State enthält Secrets → Verwende [Terraform Cloud](https://cloud.hashicorp.com/products/terraform) oder verschlüsselte Backend-Speicherung
- `terraform.tfvars` ist in `.gitignore` → Niemals committen!
- Nutze SSH-Keys statt Passwörter
- Regelmäßige Updates der Container-Images

## 📚 Ressourcen

- [Proxmox VE API](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [HomeAssistant Docs](https://www.home-assistant.io/docs/)
- [PiHole Docs](https://docs.pi-hole.net/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)

## 📄 Lizenz

Private Repository - All Rights Reserved
