# 07 - Infrastructure Node

This document details the configuration and services natively running on the dedicated Infrastructure Node NixOS VM.

## 🏢 Purpose
The Infrastructure Node is completely isolated from the main application layer to ensure that foundational deployment configurations and network bridges remain functionally stable and explicitly independent of user-facing application panics.

## 🛠️ Deployed Services

### Native Services (NixOS Managed)
Core architecture engines are deployed natively via NixOS modules (`virtualisation.oci-containers`), ensuring they are physically immune to generic Docker Compose failures.

#### Dockhand
* **Role:** Operations, webhook controller, and deployment orchestrator.
* **Function:** Binds natively to the local Docker socket explicitly defined in its NixOS module. It orchestrates application layers across the cluster natively by receiving internal REST webhooks triggered by the localized CI pipeline.

### Application Services (Docker Compose Managed)
These services are defined natively via the `infra-stack/docker-compose.yml` file and orchestrated passively by Dockhand:

#### ZeroByte
* **Role:** Automated Encrypted Backup Engine.
* **Function:** Triggers deduplicated and explicitly encrypted volume backups securely off-site via automated Restic scheduling.

#### Dashboard (Homepage)
* **Role:** Central point of access for all homelab services.
* **Function:** Housed here so you can rapidly reach the core admin portal even if backend production apps go offline. 

#### Monitoring Stack (Planned)
* **Role:** Cluster-wide Telemetry & Visualization.
* **Function:** Hosts Prometheus (to scrape Docker and Comin node metrics), Grafana (for dashboards), and InfluxDB (for time-series data storage). Keeping this in the infra-stack ensures monitoring stays functional even if the main services layer fails. See [10-monitoring.md](file:///Users/stefan/Documents/workspace/homelab/docs/10-monitoring.md) for the full implementation plan.

## 🚀 Deployment Checklist
- [x] Integrate Dockhand natively into the `infra-node` NixOS layer.
- [x] Finalize the base `infra-stack/docker-compose.yml` file to fully map ZeroByte and Homepage.
- [x] Connect Dockhand definitively to the localized GitHub Actions Webhooks.
- [ ] Deploy the Monitoring Stack (Prometheus, Grafana, InfluxDB) into the `infra-stack/docker-compose.yml`.
