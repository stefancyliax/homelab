# Homelab

A fully open-source, GitOps-managed homelab — built as a learning project to explore NixOS, DevOps, and infrastructure-as-code.

## Why

This project exists to learn by doing. The goal is to build a full-featured homelab where **everything is defined in this repository** — from the operating system and its services down to the container deployments and monitoring dashboards. It's an ongoing experiment with NixOS, GitOps workflows, and modern DevOps tooling.

The repo is fully open source and designed to contain no secrets or attack surfaces. All sensitive credentials are encrypted at rest using [Agenix](https://github.com/ryantm/agenix) and decrypted only at deployment time by the target machines.

## Why this architecture?

This architecture is weird. I know. A pure NixOS architecture would have been cleaner and better documents in this repo. But I wanted to look at Proxmox for a long time and also not get rusty in the career-relevant skills like Docker. 
Reasoning for this architecture is that 
Overall I wanted to rework my homelab from years ago and learn about new tools and play around with local hosted AI. 

## Architecture

The homelab runs on a single Proxmox host with multiple isolated VMs, a physical GPU workstation, and a NAS.

For full hardware specs, networking, and service placement details, see [docs/architecture.md](docs/architecture.md).

## Features & Status

| Feature | Status | Details |
|---|---|---|
| NixOS Provisioning (Colmena) | ✅ Done | [deployment.md](docs/deployment.md) |
| Pull-Based Deployment (Comin) | ✅ Done | [deployment.md](docs/deployment.md) |
| Secrets Management (Agenix) | ✅ Done | [deployment.md](docs/deployment.md) |
| GitOps App Deployment (Dockhand/Hawser) | ✅ Done | [deployment.md](docs/deployment.md) |
| GitHub Actions CI/CD | ✅ Done | [deployment.md](docs/deployment.md) |
| Dashboard (Homepage) | ✅ Done | [architecture.md](docs/architecture.md) |
| Cloud Backups (ZeroByte) | 🚧 Deployed, not configured | [backup.md](docs/backup.md) |
| Local Backups (PBS) | 🔲 Planned | [backup.md](docs/backup.md) |
| Monitoring (Prometheus/Grafana/InfluxDB) | ✅ Done | [monitoring.md](docs/monitoring.md) |
| GPU Worker / AI Stack (llama-swap) | 🚧 Config defined, not yet provisioned | [gpu-worker.md](docs/gpu-worker.md) |
| Ollama Node (LLM Inference) | 🚧 Config defined, VM provisioned | — |
| Services (Paperless, Jellyfin, etc.) | 🔲 Planned | [services.md](docs/services.md) |
| Home Assistant | 🚧 VM running, migration pending | [home-assistant.md](docs/home-assistant.md) |
| Ingress & SSL | 🔲 Planned | — |
| Single Sign-On (SSO) | 🔲 Planned | — |

## To-Do

### Research & Decisions

- [ ] **Docker Rootless Mode:** Research whether configuring Docker natively in rootless mode via NixOS is necessary for security, and how it impacts volume/bind-mount permissions.
- [ ] **Paperless-AI Integration:** Research configuration parameters, setup Ollama on the `gpu-worker`, and define the prompt templates and routing for Paperless-AI before enabling it in the stack. [Paperless-AI Github](https://github.com/clusterzx/paperless-ai)
- [ ] **GPU Worker Desktop Environment:** Decide which desktop environment (KDE Plasma, GNOME, Hyprland) to provision on the GPU Worker.
- [ ] **Wake-on-LAN Integration:** Explore how WOL can automatically wake the GPU Worker when its AI endpoints are queried.
- [ ] **Volume Layout Design:** Define the logic for where and how Docker containers bind-mount persistent config and data within the NixOS VMs, tied to the backup strategy.
- [ ] **ZeroByte Configuration:** Finalize backup targets, schedules, and retention policies for the cloud backup pipeline.
- [ ] **Ingress & SSL:** Research Tailscale's built-in SSL certificate generation for internal HTTPS vs. a standard reverse proxy.
- [ ] **NAS OS Choice:** Decide on the operating system for the NAS (ZimaOS, Unraid, or managed NixOS).
- [ ] **Single Sign-On (SSO):** Evaluate SSO solutions (Authentik, Authelia, Keycloak) for centralized login across services.
- [ ] **Cloud Storage Choice:** Research Nextcloud vs. Seafile for self-hosted file sync.
- [ ] **Notifications:** Research the best way to handle cluster-wide push notifications (e.g., NTFY, Gotify, or Home Assistant) for backup reports, Grafana alerts, and container failures.
- [ ] **Dozzle:** Look into deploying Dozzle for real-time web-based Docker log viewing.
- [ ] **Nemoclaw:** Research Nemoclaw and evaluate its potential use-case in the homelab.
### Implementation

- [ ] **Home Assistant Migration:** Migrate configuration and data from the legacy HA instance to the new HAOS VM.
- [ ] **Storage Configuration:** Finalize and document the specific roles and mount points for the 3 Proxmox SSDs.
- [ ] **GPU Worker Setup:** Provision the node with NixOS, Nvidia drivers, and AI tooling. See [gpu-worker.md](docs/gpu-worker.md).
- [ ] **GPU Top:** Add `nvtop` to the `gpu-worker` node's system packages for monitoring GPU usage.
- [ ] **Paperless-GPT OCR:** Replace OCR provider for `paperless-gpt` with `docling-serve`.
- [ ] **Paperless-GPT Native Parsing:** Set up a secondary instance of `paperless-gpt` using `docling` as the backend for non-scanned/digital native documents (e.g., received via email).
- [ ] **Paperless Email Ingress:** Configure email fetching, accounts, and routing rules in Paperless-ngx.
- [x] **LLM Backend Migration (gpu-worker):** Migrated the `gpu-worker` from `ollama` to `llama-swap` as a native NixOS service with CUDA-accelerated `llama-cpp`. Initial model: Qwen3-VL-8B-Instruct (Q4_K_M). See [gpu-worker.md](docs/gpu-worker.md).
- [ ] **LLM Backend Migration (ollama-node):** Evaluate migrating the `ollama-node` VM to `llama-swap` as well, to unify the AI inference backend across all nodes.
- [ ] **Vision LLM Tuning:** Tune the vision LLM parameters based on the recommendations in this [Reddit discussion](https://www.reddit.com/r/LocalLLaMA/s/6GYklK8kvY).
- [ ] **ComfyUI Deployment:** Deploy [ComfyUI](https://github.com/comfyanonymous/ComfyUI) on the `gpu-worker` for GPU-accelerated image generation workflows.
- [ ] **Cloud Backups:** Configure ZeroByte with Rclone for encrypted backups to Google Drive.
- [ ] **Local Backups:** Set up Proxmox Backup Server on the Intel NUC.
- [ ] **Service Deployment:** Write Docker Compose files and deploy planned apps (Paperless-ngx, Frigate, NocoDB, n8n, IT-Tools, etc.). See [services.md](docs/services.md).
- [ ] **Tududi Deployment:** Write the Docker Compose definitions to deploy the [Tududi](https://github.com/chrisvel/tududi) task management service to the `services-stack`.
- [ ] **Dashboard APIs:** Connect Homepage widgets to live data sources:
    - [ ] Proxmox & PBS API tokens for hypervisor metrics.
    - [ ] Home Assistant long-lived access token for entity telemetry.
    - [ ] Paperless-ngx API token for inbox count badges.
    - [ ] Grafana & SSO metrics via the Homepage REST parser.

### Completed

- [x] **Monitoring Stack:** Deployed Prometheus, Grafana, and InfluxDB with node exporters and fully declarative dashboards!
- [x] **Comin Migration:** Natively implemented Comin across all nodes, removing all traces of Colmena.
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
│   │   ├── gpu-worker/
│   │   └── ollama-node/
│   ├── modules/            # Reusable NixOS modules (Dockhand, Hawser, Ollama)
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