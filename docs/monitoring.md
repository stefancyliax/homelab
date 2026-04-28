# Monitoring

This document describes the monitoring and observability strategy for the homelab — how metrics are collected, stored, and visualized.

**Current status:** ✅ Done — Fully deployed via Docker Compose with declarative provisioning.

## Overview

The monitoring stack will be hosted within the `infra-stack` on the Infrastructure Node. Keeping it in the infrastructure layer ensures visibility into the entire cluster remains available even if the main application services go down.

## Components

### Prometheus

**Role:** Metrics aggregation and scraping.

Prometheus periodically polls defined endpoints to collect time-series metrics.

| Scrape Target | Port | Description |
|---|---|---|
| Comin nodes | 4242 | GitOps deployment status (pull success, current revision) |
| Docker daemon | Configurable | Container health and resource utilization |
| Node Exporters | 9100 | Hardware telemetry (CPU, RAM, disk) from all NixOS VMs and bare-metal nodes |

### Grafana

**Role:** Visualization and alerting.

Grafana connects to Prometheus (and InfluxDB) as data sources to provide real-time dashboards.

**Planned dashboards:**

| Dashboard | Data Source | Description |
|---|---|---|
| Node Health | Prometheus | CPU, memory, and disk usage across all NixOS VMs |
| Docker Overview | Prometheus | Resource utilization per container |
| Comin Status | Prometheus | Pull-based deployment success and revision history |
| Deployment Tracking | Prometheus | Deployment frequency and success/failure rates |
| Home Assistant Sensors | InfluxDB | Temperature, energy, and sensor trends over time |

### InfluxDB

**Role:** Long-term time-series storage.

Primarily used for high-resolution logging and long-term data archival where Prometheus's default short-term retention would be insufficient. The main consumer is Home Assistant, which pushes sensor data via its `recorder` integration.

## Setup Guide

### 1. Deploy Services

Add Prometheus, Grafana, and InfluxDB to `infra-stack/docker-compose.yml`. All three run as Docker containers orchestrated by Dockhand.

### 2. Configure Prometheus

Create a `prometheus.yml` configuration file defining:
- Scrape intervals
- Job definitions for each target (Comin, Docker, Node Exporters)
- Target addresses for all nodes in the cluster

### 3. Enable Node Exporters

On each NixOS VM, enable `node_exporter` via NixOS configuration to expose hardware metrics on port 9100. Configure Docker to expose daemon metrics on the bridge network.

### 4. Provision Grafana

Use Grafana's declarative provisioning YAMLs to pre-configure:
- Prometheus as a data source
- InfluxDB as a data source
- Community-standard dashboards for Node Exporter and Docker

### 5. Connect Home Assistant

Configure Home Assistant's `recorder` integration to push sensor data to InfluxDB for long-term storage and Grafana visualization.

## Notifications

Cluster-wide push notifications are handled by a self-hosted [ntfy](https://ntfy.sh/) instance running in the `infra-stack`. ntfy provides a simple HTTP-based pub-sub API — any service can send a notification with a single `curl` call, and subscribers receive instant push notifications on Android, iOS, or the web UI.

**Why self-hosted instead of ntfy.sh?** The public ntfy.sh service imposes a 250 messages/day cap, which is easily exceeded by Grafana alerts, document consumption events, and workflow completions combined. Self-hosting removes all rate limits and keeps notification payloads entirely on the LAN.

### Topic Convention

| Topic | Source | Description |
|---|---|---|
| `homelab-alerts` | Grafana | Infrastructure alerts (CPU, disk, container health) |
| `homelab-deployments` | Comin / Dockhand / GitHub Actions | Deployment status events |
| `homelab-backups` | ZeroByte | Backup success/failure reports |
| `homelab-documents` | Paperless-ngx (via n8n) | New document consumption events |
| `homelab-workflows` | n8n / Kestra | Workflow completion/failure events |
| `homelab-security` | Frigate / fail2ban | Motion detection, intrusion attempts |
| `homelab-system` | Proxmox / General | Hypervisor events, container restarts, system events |

### Integration Points

- **Proxmox → ntfy:** Native webhook target in Datacenter → Notifications. See [proxmox-setup.md](proxmox-setup.md#notifications-ntfy).
- **Grafana → ntfy:** Configured as a Webhook contact point with a custom JSON payload template targeting the `homelab-alerts` topic.
- **n8n / Kestra → ntfy:** Native HTTP request nodes publishing to the appropriate topic.
- **ZeroByte → ntfy:** Post-backup hook script using `curl` to publish results.
- **Comin → ntfy:** Systemd `OnSuccess`/`OnFailure` hooks on the `comin.service` unit, configured in `modules/comin.nix`. Reports deployment success/failure with the node hostname.
- **Home Assistant → ntfy:** REST-based notify integration or the native ntfy HA integration.

