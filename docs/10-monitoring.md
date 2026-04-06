# 10 - Monitoring (Prometheus & Grafana)

This document outlines the monitoring strategy for the homelab, focusing on metrics collection and visualization.

## 📊 Overview

The monitoring stack is hosted within the `infra-stack` on the Infrastructure Node. This ensures that visibility into the health of the entire cluster (including the services-node and physical workers) remains active even if the main application layer experiences issues.

## 🛠️ Components

### Prometheus
* **Role:** Metrics Aggregator & Scraper.
* **Function:** Periodically polls defined metrics endpoints.
* **Scrape Targets:**
    * **Comin Nodes:** Port 4242 (Natively exports GitOps status).
    * **Docker Containers:** Docker daemon metrics for container health and resources.
    * **Node Exporters:** Hardware telemetry from Proxmox VMs and bare-metal nodes.

### Grafana
* **Role:** Visualization & Alerting.
* **Function:** Connects to Prometheus as a data source to provide real-time dashboards.
* **Initial Dashboards:**
    * **Node Health:** CPU, Memory, and Disk usage across all NixOS VMs.
    * **Docker Overview:** Resource utilization per container.
    * **Comin Status:** Tracking the pull-based deployment success and revision history.

### InfluxDB
* **Role:** Long-term Time-Series Storage.
* **Function:** Primarily used for high-resolution logging or long-term data archival for Home Assistant and other services where Prometheus's short-term retention might be limiting.

## 🚀 Implementation Steps

1. **Provision Docker Services:** Add Prometheus, Grafana, and InfluxDB images to the `infra-stack/docker-compose.yml`.
2. **Prometheus Configuration:** Create a `prometheus.yml` configuration to define job targets and scrape intervals.
3. **Grafana Provisioning:** Pre-configure Prometheus as a data source using Grafana's declarative provisioning YAMLs.
4. **Export Cluster Metrics:**
    * Enable `virtualisation.oci-containers` with node_exporter in NixOS for each VM.
    * Configure Docker to expose metrics locally on the bridge network.
5. **Dashboard Creation:** Import community-standard dashboards for Node Exporter and Docker.

## 🛠️ To-Dos
- [ ] Add `prometheus` service to `infra-stack/docker-compose.yml`.
- [ ] Add `grafana` service to `infra-stack/docker-compose.yml`.
- [ ] Add `influxdb` service to `infra-stack/docker-compose.yml`.
- [ ] Create initial `prometheus.yml` with node and docker targets.
- [ ] Verify connectivity from `infra-node` to other nodes on required ports (4242, 9100, etc.).
