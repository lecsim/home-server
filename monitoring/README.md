# Monitoring Konfiguration

Dieses Verzeichnis enthält erweiterte Prometheus- und Grafana-Konfigurationen.

## Struktur

```
monitoring/
├── prometheus/
│   ├── prometheus.yml          # Prometheus Hauptkonfiguration
│   ├── alerts.yml              # Alert Rules
│   └── rules/                  # Recording Rules
└── grafana/
    └── dashboards/             # Grafana Dashboard JSON-Dateien
```

## Prometheus Konfiguration

Die Prometheus-Konfiguration wird automatisch beim Terraform-Deployment erstellt. Für erweiterte Konfigurationen kannst du die Dateien in diesem Verzeichnis anpassen.

### Alert Rules hinzufügen

Erstelle eine Datei `alerts.yml` mit Alert-Definitionen:

```yaml
groups:
  - name: system_alerts
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for 5 minutes on {{ $labels.instance }}"
      
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 90% on {{ $labels.instance }}"
      
      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"}) * 100 < 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space"
          description: "Disk space is below 10% on {{ $labels.instance }}"
```

## Grafana Dashboards

### Vorinstallierte Dashboards

Die Grafana-Installation enthält automatisch die Prometheus-Datasource. Du kannst zusätzliche Dashboards importieren:

1. Öffne Grafana Web UI
2. Navigiere zu **Dashboards** → **Import**
3. Gib eine Dashboard-ID ein oder lade JSON hoch

### Empfohlene Dashboard IDs

| Dashboard | ID | Beschreibung |
|-----------|----|----|
| Node Exporter Full | 1860 | Vollständige System-Metriken |
| PiHole Exporter | 10176 | PiHole Statistiken |
| Prometheus 2.0 Stats | 3662 | Prometheus Selbst-Monitoring |

### Dashboard exportieren

Dashboards können als JSON exportiert und in diesem Verzeichnis gespeichert werden:

1. Öffne Dashboard in Grafana
2. Klicke auf **Share** → **Export**
3. Speichere JSON-Datei unter `grafana/dashboards/`

## Prometheus Targets

Die folgenden Targets werden automatisch konfiguriert:

- **Prometheus**: `localhost:9090`
- **Node Exporters**: Alle Container-IPs auf Port `9100`
- **PiHole Exporter**: PiHole-IP auf Port `9617`

## Metrics Endpoints

| Service | Endpoint | Beschreibung |
|---------|----------|--------------|
| Prometheus | `http://prometheus-ip:9090/metrics` | Prometheus Metriken |
| Node Exporter | `http://container-ip:9100/metrics` | System-Metriken |
| PiHole Exporter | `http://pihole-ip:9617/metrics` | PiHole-Metriken |

## Alerting Setup (Optional)

Für Alerting kannst du Alertmanager hinzufügen:

```bash
# Auf Prometheus Container
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
tar xvfz alertmanager-0.26.0.linux-amd64.tar.gz
mv alertmanager-0.26.0.linux-amd64/alertmanager /usr/local/bin/
```

Alertmanager Konfiguration (`alertmanager.yml`):

```yaml
global:
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'user'
  smtp_auth_password: 'password'

route:
  receiver: 'email-notifications'
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 12h

receivers:
  - name: 'email-notifications'
    email_configs:
      - to: 'admin@example.com'
```
