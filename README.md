# Homelab

A fully open-source, GitOps-managed homelab — built as a learning project to explore NixOS, DevOps, and infrastructure-as-code.

## Why

This project exists to learn by doing. The goal is to build a full-featured homelab where **everything is defined in this repository** — from the operating system and its services down to the container deployments and monitoring dashboards. It's an ongoing experiment with NixOS, GitOps workflows, and modern DevOps tooling.

The repo is fully open source and designed to contain no secrets or attack surfaces. All sensitive credentials are encrypted at rest using [Agenix](https://github.com/ryantm/agenix) and decrypted only at deployment time by the target machines.

## Architecture

The homelab runs on a single Proxmox host with multiple isolated VMs, a physical GPU workstation, and a NAS.

For full hardware specs, networking, and service placement details, see [docs/architecture.md](docs/architecture.md).

## Features & Status

| Feature | Status | Details |
|---|---|---|
| NixOS Provisioning (Colmena) | ✅ Done | [deployment.md](docs/deployment.md) |
| Pull-Based Deployment (Comin) | 🚧 Partial | [deployment.md](docs/deployment.md) |
| Secrets Management (Agenix) | ✅ Done | [deployment.md](docs/deployment.md) |
| GitOps App Deployment (Dockhand/Hawser) | ✅ Done | [deployment.md](docs/deployment.md) |
| GitHub Actions CI/CD | ✅ Done | [deployment.md](docs/deployment.md) |
| Dashboard (Homepage) | ✅ Done | [architecture.md](docs/architecture.md) |
| Cloud Backups (ZeroByte) | 🚧 Deployed, not configured | [backup.md](docs/backup.md) |
| Local Backups (PBS) | 🔲 Planned | [backup.md](docs/backup.md) |
| Monitoring (Prometheus/Grafana/InfluxDB) | 🔲 Planned | [monitoring.md](docs/monitoring.md) |
| GPU Worker / AI Stack | 🔲 Planned | [gpu-worker.md](docs/gpu-worker.md) |
| Services (Paperless, Jellyfin, etc.) | 🔲 Planned | [services.md](docs/services.md) |
| Home Assistant | 🚧 VM running, migration pending | [home-assistant.md](docs/home-assistant.md) |
| Ingress & SSL | 🔲 Planned | — |
| Single Sign-On (SSO) | 🔲 Planned | — |

## To-Do

### Research & Decisions

- [ ] **Docker Rootless Mode:** Research whether configuring Docker natively in rootless mode via NixOS is necessary for security, and how it impacts volume/bind-mount permissions.
- [ ] **Paperless-GPT Integration:** Research configuration parameters, setup Ollama on the `gpu-worker`, and define the prompt templates and routing for Paperless-GPT before enabling it in the stack. [Paperless-GPT Github](https://github.com/icereed/paperless-gpt?tab=readme-ov-file#docker-compose)
- [ ] **GPU Worker Desktop Environment:** Decide which desktop environment (KDE Plasma, GNOME, Hyprland) to provision on the GPU Worker.
- [ ] **Wake-on-LAN Integration:** Explore how WOL can automatically wake the GPU Worker when its AI endpoints are queried.
- [ ] **Volume Layout Design:** Define the logic for where and how Docker containers bind-mount persistent config and data within the NixOS VMs, tied to the backup strategy.
- [ ] **ZeroByte Configuration:** Finalize backup targets, schedules, and retention policies for the cloud backup pipeline.
- [ ] **Ingress & SSL:** Research Tailscale's built-in SSL certificate generation for internal HTTPS vs. a standard reverse proxy.
- [ ] **NAS OS Choice:** Decide on the operating system for the NAS (ZimaOS, Unraid, or managed NixOS).
- [ ] **Single Sign-On (SSO):** Evaluate SSO solutions (Authentik, Authelia, Keycloak) for centralized login across services.
- [ ] **Cloud Storage Choice:** Research Nextcloud vs. Seafile for self-hosted file sync.

### Implementation

- [ ] **Comin Migration:** Migrate the deployment workflow to Comin starting with the GPU Worker, then evaluate rolling it across the cluster.
- [ ] **Home Assistant Migration:** Migrate configuration and data from the legacy HA instance to the new HAOS VM.
- [ ] **Storage Configuration:** Finalize and document the specific roles and mount points for the 3 Proxmox SSDs.
- [ ] **GPU Worker Setup:** Provision the node with NixOS, Nvidia drivers, and AI tooling. See [gpu-worker.md](docs/gpu-worker.md).
- [ ] **Cloud Backups:** Configure ZeroByte with Rclone for encrypted backups to Google Drive.
- [ ] **Local Backups:** Set up Proxmox Backup Server on the Intel NUC.
- [ ] **Monitoring Stack:** Deploy Prometheus, Grafana, and InfluxDB to the `infra-stack`. See [monitoring.md](docs/monitoring.md).
    - [ ] Configure Prometheus scrapers for Comin and Docker daemon metrics.
    - [ ] Enable Node Exporters on all NixOS VMs.
    - [ ] Set up Grafana dashboards for cluster-wide node and container health.
- [ ] **Service Deployment:** Write Docker Compose files and deploy planned apps (Paperless-ngx, Frigate, NocoDB, n8n, IT-Tools, etc.). See [services.md](docs/services.md).
- [ ] **Dashboard APIs:** Connect Homepage widgets to live data sources:
    - [ ] Proxmox & PBS API tokens for hypervisor metrics.
    - [ ] Home Assistant long-lived access token for entity telemetry.
    - [ ] Paperless-ngx API token for inbox count badges.
    - [ ] Grafana & SSO metrics via the Homepage REST parser.

### Completed

- [x] **Dockhand & Hawser Migration:** Migrated away from Komodo to natively defined Dockhand and Hawser nodes via NixOS.
- [x] **GitHub Actions for Deployment:** Workflows trigger internal webhooks when `infra-stack` or `services-stack` are updated.
- [x] **CPU Host Mode Migration:** All Proxmox VMs migrated to CPU `host` mode.
- [x] **NixOS Node Renaming:** Nodes renamed to `infra-node` and `services-node` to avoid confusion with the Docker Compose stacks.
- [x] **Secrets Management:** Adopted Agenix with encrypted secrets in the repo.
- [x] **Docker API Security:** Hawser proxy eliminates the need for exposing raw Docker API over the network.
- [x] **VM Firmware Decision:** Existing VMs stay on SeaBIOS; new VMs use OVMF/UEFI.
- [x] **Offline Node Strategy:** Solved via Comin for pull-based deployments on intermittent nodes.
- [x] **Homepage Dashboard:** Fully declarative layout via YAML in the `infra-stack`.

## Repository Structure

```
homelab/
├── NixOS/                  # NixOS configurations (Colmena flake)
│   ├── flake.nix           # Flake entry point
│   ├── common.nix          # Shared base config for all nodes
│   ├── nodes/              # Per-node configurations
│   │   ├── infra-node/
│   │   ├── services-node/
│   │   └── gpu-worker/
│   ├── modules/            # Reusable NixOS modules (Dockhand, Hawser)
│   ├── secrets/            # Agenix-encrypted secret files (.age)
│   └── secrets.nix         # SSH key → secret file mappings
├── infra-stack/            # Docker Compose for infrastructure services
│   ├── docker-compose.yml
│   └── homepage/           # Homepage dashboard config (YAML)
├── services-stack/         # Docker Compose for application services
│   └── docker-compose.yml
├── docs/                   # Detailed documentation
│   ├── architecture.md     # Hardware, networking, VM landscape
│   ├── proxmox-setup.md    # Proxmox hypervisor configuration
│   ├── deployment.md       # NixOS provisioning & app deployment
│   ├── backup.md           # Backup strategy & recovery
│   ├── gpu-worker.md       # GPU workstation setup
│   ├── services.md         # End-user services catalog
│   ├── home-assistant.md   # Smart home ecosystem
│   └── monitoring.md       # Prometheus, Grafana, InfluxDB
└── .github/workflows/      # CI/CD pipelines
    ├── nixos-apply.yml
    ├── dockhand-infra.yml
    └── dockhand-services.yml
```

## Documentation

| Document | Description |
|---|---|
| [Architecture](docs/architecture.md) | Hardware specs, networking, VM landscape, and service placement |
| [Proxmox Setup](docs/proxmox-setup.md) | Hypervisor configuration and VM provisioning baseline |
| [Deployment](docs/deployment.md) | NixOS provisioning (Colmena & Comin), app deployment (Dockhand/Hawser), CI/CD, and commands |
| [Backup](docs/backup.md) | Backup strategy (ZeroByte, PBS) and recovery procedures |
| [GPU Worker](docs/gpu-worker.md) | AI workstation provisioning and tooling |
| [Services](docs/services.md) | Catalog of user-facing homelab services |
| [Home Assistant](docs/home-assistant.md) | Smart home ecosystem and integrations |
| [Monitoring](docs/monitoring.md) | Prometheus, Grafana, and InfluxDB monitoring stack |