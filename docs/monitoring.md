# Monitoring

This document describes the monitoring and observability strategy for the homelab — how metrics are collected, stored, and visualized.

**Current status:** ✅ Done — Fully deployed via Docker Compose with declarative provisioning.

## Overview

The monitoring stack will be hosted within the `infra-stack` on the Infrastructure Node. Keeping it in the infrastructure layer ensures visibility into the entire cluster remains available even if the main application services go down.

## Components

### VictoriaMetrics

**Role:** Consolidated time-series database (TSDB) and metrics collector.

VictoriaMetrics acts as the unified metrics backbone for the entire homelab, replacing both Prometheus and InfluxDB:
- **Scraping (Pull):** Periodically scrapes defined Prometheus endpoints via `infra-stack/victoriametrics/scrape.yml`.
- **Ingestion (Push):** Accepts push metrics via InfluxDB Line Protocol (`/write` and `/api/v2/write`) from Home Assistant and Proxmox VE.
- **Long-term Storage:** Configured with a 36-month retention period (`-retentionPeriod=36M`) and high-efficiency compression while consuming minimal RAM (typically 50–150 MB).

| Scrape Target | Port | Description |
|---|---|---|
| VictoriaMetrics self | 8428 | Internal TSDB performance and ingestion telemetry |
| Comin nodes | 4243 | GitOps deployment status (pull success, current revision) |
| Docker daemon | 9323 | Container health and resource utilization |
| Node Exporters | 9100 | Hardware telemetry (CPU, RAM, disk) from all NixOS nodes (including `hermes-node` & `gpu-worker`) |

### Grafana

**Role:** Visualization and alerting.

Grafana connects to VictoriaMetrics as its primary Prometheus-compatible data source to provide real-time dashboards. Dashboards are declaratively provisioned via `infra-stack/grafana/provisioning/dashboards/`:

**Provisioned dashboards:**

| Dashboard | Data Source | Description |
|---|---|---|
| Node Exporter | VictoriaMetrics / Prometheus | CPU, memory, network, and disk usage across all NixOS VMs (`node_exporter.json`) |
| Docker Overview | VictoriaMetrics / Prometheus | Resource utilization and container status (`docker.json`) |
| Comin Status | VictoriaMetrics / Prometheus | Pull-based deployment status and revision history (`comin.json`) |
| NixOS Versions | VictoriaMetrics / Prometheus | Running Git commit SHA tracking across all nodes (`nixos_versions.json`) |
| Proxmox Cluster | VictoriaMetrics | Hypervisor resource allocation and VM metrics (`proxmox.json`) |
| Home Assistant Sensors | VictoriaMetrics | Temperature, energy, and sensor trends over time |

### Loki & Promtail

**Role:** Centralized Log Aggregation.

Loki provides log storage and indexing (similar to Prometheus/VictoriaMetrics but for logs). Promtail runs on every node as an agent to collect and forward logs to Loki.

**Sources:**
- **systemd-journal**: Captures all host-level logs from NixOS services (SSH, Comin, Node Exporter, Hermes, etc.).
- **Docker**: Captures JSON logs from all running containers.

Logs are retained for 14 days by default. The Hermes agent programmatically queries the Loki HTTP API at `http://10.1.23.184:3100` to access cluster logs without requiring SSH.

## Setup Guide

### 1. Deploy Services

Deploy VictoriaMetrics, Grafana, and Loki in `infra-stack/docker-compose.yml`. All run as Docker containers orchestrated by Dockhand.

### 2. Configure Scrape Targets

Maintain `infra-stack/victoriametrics/scrape.yml` defining:
- Scrape intervals
- Job definitions for each target (VictoriaMetrics self, Comin, Docker, Node Exporters)
- Target addresses for all nodes in the cluster

### 3. Enable Node Exporters

On each NixOS VM, enable `node_exporter` via NixOS configuration to expose hardware metrics on port 9100. Configure Docker to expose daemon metrics on the bridge network.

### 4. Provision Grafana

Use Grafana's declarative provisioning YAMLs (`infra-stack/grafana/provisioning/datasources/datasources.yml`) to pre-configure:
- VictoriaMetrics as default Prometheus-compatible data source (`http://victoriametrics:8428`)
- Prometheus alias datasource for backward compatibility with community dashboards
- Loki data source for logs

### 5. Connect Home Assistant & Proxmox

- **Home Assistant:** Configure Home Assistant's `influxdb` integration (or native `prometheus:` integration) to push sensor data to `http://10.1.23.184:8428/write` for long-term storage and Grafana visualization.
- **Proxmox VE:** Configure Datacenter → Metric Server → InfluxDB (v1) pointing to `10.1.23.184:8428` to export cluster telemetry.

### 6. Enable Logging

Promtail is deployed natively via the NixOS `common.nix` module to automatically ship journald and Docker logs from all nodes. Loki runs alongside the other monitoring services in the `infra-stack` and is pre-provisioned as a Grafana datasource.

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

- **Proxmox → ntfy:** ✅ Native webhook target in Datacenter → Notifications. See [proxmox-setup.md](proxmox-setup.md#notifications-ntfy).
- **Comin → ntfy:** ✅ `postDeploymentCommand` hook in `modules/comin.nix`. Reports deployment success/failure with node hostname and commit info to `homelab-deployments`.
- **Dockhand → ntfy:** ✅ Configured via the Dockhand web UI. Reports deployment events to `homelab-deployments`.
- **ZeroByte → ntfy:** ✅ Built-in ntfy notification provider, configured via the ZeroByte dashboard to publish to `homelab-backups`.
- **GitHub Actions → ntfy:** ✅ `nixos-check.yml` sends failure notifications to `homelab-deployments` on CI build failures.
- **Grafana → ntfy:** 🔲 Planned. Webhook contact point targeting `homelab-alerts`.
- **Home Assistant → ntfy:** 🔲 Planned. Will likely use Telegram instead.

