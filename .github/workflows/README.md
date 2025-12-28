# GitHub Actions Secrets Setup

Für die CI/CD Pipeline müssen folgende Secrets in deinem GitHub Repository konfiguriert werden:

## Secrets konfigurieren

1. Gehe zu deinem Repository auf GitHub
2. Navigiere zu **Settings** → **Secrets and variables** → **Actions**
3. Klicke auf **New repository secret**
4. Füge folgende Secrets hinzu:

### Proxmox Connection Secrets

| Secret Name | Beschreibung | Beispiel |
|-------------|--------------|----------|
| `PROXMOX_API_URL` | Proxmox API URL | `https://192.168.1.100:8006/api2/json` |
| `PROXMOX_API_TOKEN_ID` | Proxmox API Token ID | `root@pam!terraform` |
| `PROXMOX_API_TOKEN` | Proxmox API Token Secret | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `PROXMOX_NODE` | Proxmox Node Name | `pve` |

### Network Configuration Secrets

| Secret Name | Beschreibung | Beispiel |
|-------------|--------------|----------|
| `NETWORK_GATEWAY` | Netzwerk Gateway | `192.168.1.1` |
| `NETWORK_DNS` | DNS Server | `192.168.1.1` |

### Service IP Addresses

| Secret Name | Beschreibung | Beispiel |
|-------------|--------------|----------|
| `HOMEASSISTANT_IP` | HomeAssistant IP | `192.168.1.10` |
| `PIHOLE_IP` | PiHole IP | `192.168.1.11` |
| `PROMETHEUS_IP` | Prometheus IP | `192.168.1.12` |
| `GRAFANA_IP` | Grafana IP | `192.168.1.13` |

## Environment Protection (Optional)

Für zusätzliche Sicherheit kannst du ein **Production Environment** erstellen:

1. Gehe zu **Settings** → **Environments**
2. Klicke auf **New environment**
3. Name: `production`
4. Aktiviere **Required reviewers** (optional)
5. Speichern

Dies sorgt dafür, dass Deployments auf `main` Branch manuell bestätigt werden müssen.

## Workflow Trigger

Der Workflow wird getriggert bei:
- **Push** auf `main` Branch (automatisches Deployment)
- **Pull Request** auf `main` Branch (nur Plan, kein Apply)
- **Manuell** über GitHub Actions UI (workflow_dispatch)

## Workflow-Dateien

Die Workflow-Datei befindet sich unter:
```
.github/workflows/deploy.yml
```

## Terraform State

⚠️ **Wichtig**: Der Terraform State wird lokal im GitHub Actions Runner gespeichert. Für Production-Umgebungen solltest du ein **Remote Backend** konfigurieren (z.B. Terraform Cloud, AWS S3, Azure Storage).

### Remote Backend Konfiguration (Optional)

Beispiel für Terraform Cloud in [providers.tf](../terraform/providers.tf):

```hcl
terraform {
  backend "remote" {
    organization = "your-org"
    workspaces {
      name = "home-server"
    }
  }
}
```
