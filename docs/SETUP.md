# Setup Anleitung

Komplette Schritt-für-Schritt-Anleitung zum Aufsetzen der Home-Server-Infrastruktur.

## 📋 Voraussetzungen

### Hardware
- [x] Lenovo ThinkCentre M910q mit Proxmox VE installiert
- [x] SSH-Zugriff auf Proxmox Server
- [x] Mindestens 8GB RAM
- [x] Mindestens 100GB freier Speicher

### Software
- [x] Git installiert
- [x] Terraform >= 1.0 installiert
- [x] SSH-Client

## 🚀 Schritt-für-Schritt Setup

### 1. Proxmox vorbereiten

#### 1.1 Container-Template herunterladen

Verbinde dich per SSH mit deinem Proxmox Server:

```bash
ssh root@<proxmox-ip>
```

Lade das Debian 12 Container-Template herunter:

```bash
pveam update
pveam download local debian-12-standard_12.2-1_amd64.tar.zst
```

#### 1.2 Proxmox API Token erstellen

1. Öffne Proxmox Web UI: `https://<proxmox-ip>:8006`
2. Navigiere zu **Datacenter** → **Permissions** → **API Tokens**
3. Klicke auf **Add**
4. Konfiguration:
   - User: `root@pam`
   - Token ID: `terraform`
   - **Privilege Separation**: Deaktiviert (wichtig!)
5. Klicke **Add** und notiere den Token-Secret (wird nur einmal angezeigt!)

#### 1.3 Netzwerk-Konfiguration überprüfen

Stelle sicher, dass die Bridge `vmbr0` existiert:

```bash
ip addr show vmbr0
```

### 2. GitHub Repository erstellen

#### 2.1 Repository anlegen

1. Gehe zu [GitHub](https://github.com)
2. Klicke auf **New Repository**
3. Name: `home-server`
4. Visibility: **Private**
5. Klicke **Create repository**

#### 2.2 Lokales Repository initialisieren

```bash
cd c:\Users\slechler\Dev\Home-Server
git init
git add .
git commit -m "Initial commit: Terraform IaC setup"
git branch -M main
git remote add origin https://github.com/<dein-username>/home-server.git
git push -u origin main
```

### 3. Terraform konfigurieren

#### 3.1 Terraform-Variablen anpassen

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Öffne `terraform.tfvars` und passe die Werte an:

```hcl
# Proxmox Connection
proxmox_api_url      = "https://<deine-proxmox-ip>:8006/api2/json"
proxmox_api_token_id = "root@pam!terraform"
proxmox_api_token    = "<dein-token-secret>"
proxmox_tls_insecure = true
proxmox_node         = "pve"  # Dein Proxmox Node-Name

# Network Configuration
network_gateway = "<dein-gateway>"      # z.B. 192.168.1.1
network_dns     = "<dein-dns>"          # z.B. 192.168.1.1

# Service IP Addresses (passe an dein Netzwerk an)
homeassistant_ip = "192.168.1.10"
pihole_ip        = "192.168.1.11"
prometheus_ip    = "192.168.1.12"
grafana_ip       = "192.168.1.13"
```

#### 3.2 SSH-Key für Container-Zugriff (Optional)

Falls du SSH-Zugriff auf die Container möchtest:

```bash
# Windows (Git Bash oder WSL)
cat ~/.ssh/id_rsa.pub

# Den Public Key in terraform.tfvars eintragen:
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB..."
```

### 4. Terraform ausführen

#### 4.1 Terraform initialisieren

```bash
cd terraform
terraform init
```

#### 4.2 Plan überprüfen

```bash
terraform plan
```

Überprüfe die geplanten Änderungen sorgfältig!

#### 4.3 Infrastructure erstellen

```bash
terraform apply
```

Bestätige mit `yes`. Der Deployment-Prozess dauert ca. 15-20 Minuten.

### 5. Services überprüfen

Nach erfolgreichem Deployment kannst du auf die Services zugreifen:

#### HomeAssistant
```
URL: http://<homeassistant-ip>:8123
```

Beim ersten Zugriff musst du einen Account erstellen.

#### PiHole
```
URL: http://<pihole-ip>/admin
Username: admin
Password: admin
```

⚠️ **Wichtig**: Ändere das Passwort nach dem ersten Login:

```bash
ssh root@<pihole-ip>
pihole -a -p  # Neues Passwort setzen
```

#### Prometheus
```
URL: http://<prometheus-ip>:9090
```

Überprüfe unter **Status** → **Targets**, ob alle Targets erreichbar sind.

#### Grafana
```
URL: http://<grafana-ip>:3000
Username: admin
Password: admin
```

⚠️ **Wichtig**: Ändere das Passwort beim ersten Login!

### 6. GitHub Actions konfigurieren (Optional)

Für automatische Deployments:

#### 6.1 GitHub Secrets hinzufügen

1. Gehe zu deinem Repository auf GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Füge folgende Secrets hinzu:
   - `PROXMOX_API_URL`
   - `PROXMOX_API_TOKEN_ID`
   - `PROXMOX_API_TOKEN`
   - `PROXMOX_NODE`
   - `NETWORK_GATEWAY`
   - `NETWORK_DNS`
   - `HOMEASSISTANT_IP`
   - `PIHOLE_IP`
   - `PROMETHEUS_IP`
   - `GRAFANA_IP`

Details siehe [.github/workflows/README.md](.github/workflows/README.md)

#### 6.2 Environment Protection (Optional)

1. **Settings** → **Environments**
2. **New environment**: `production`
3. Aktiviere **Required reviewers** (empfohlen)

## ✅ Checkliste

Nach dem Setup solltest du folgendes überprüfen:

- [ ] Alle Container laufen (in Proxmox Web UI überprüfen)
- [ ] HomeAssistant ist erreichbar und Account erstellt
- [ ] PiHole ist erreichbar und Passwort geändert
- [ ] Prometheus zeigt alle Targets als "UP"
- [ ] Grafana ist erreichbar und Passwort geändert
- [ ] Prometheus Datasource in Grafana funktioniert
- [ ] Node Exporter Dashboards in Grafana importiert

## 🔧 Troubleshooting

### Container startet nicht

```bash
# Auf Proxmox Server
pct list                    # Liste aller Container
pct status <vmid>           # Status eines Containers
pct start <vmid>            # Container starten
journalctl -u pve-container@<vmid>  # Logs anzeigen
```

### Service nicht erreichbar

```bash
# SSH in Container
ssh root@<container-ip>

# Service-Status prüfen
systemctl status <service-name>

# Logs anzeigen
journalctl -u <service-name> -f
```

### Terraform State-Probleme

```bash
# State-Liste anzeigen
terraform state list

# Einzelne Ressource aus State entfernen
terraform state rm <resource>

# State neu synchronisieren
terraform refresh
```

## 📚 Nächste Schritte

1. **Grafana Dashboards**: Importiere empfohlene Dashboards (siehe [monitoring/README.md](monitoring/README.md))
2. **PiHole konfigurieren**: Richte Adlists und Blocklisten ein
3. **HomeAssistant**: Integriere deine Smart-Home-Geräte
4. **Backups**: Richte automatische Proxmox-Backups ein
5. **Alerting**: Konfiguriere Prometheus Alertmanager (optional)

## 🆘 Support

Bei Problemen:
1. Prüfe die Terraform-Logs
2. Prüfe die Container-Logs in Proxmox
3. Prüfe die Service-Logs mit `journalctl`
4. Erstelle ein Issue im Repository
