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
| Cloud Backups (ZeroByte) | ✅ Done | [backup.md](docs/backup.md) |
| Local Backups (PBS) | 🔲 Planned | [backup.md](docs/backup.md) |
| Monitoring (Prometheus/Grafana/InfluxDB) | ✅ Done | [monitoring.md](docs/monitoring.md) |
| GPU Worker / AI Stack (llama-swap) | ✅ Done | [gpu-worker.md](docs/gpu-worker.md) |
| Hermes Node (Remote AI Agent) | ✅ Done | [architecture.md](docs/architecture.md) |
| ~~Ollama Node (LLM Inference)~~ | ❌ Deprecated | GPU Worker handles all inference |
| Services (Paperless, Jellyfin, etc.) | 🚧 Ongoing | [services.md](docs/services.md) |
| Home Assistant | 🚧 VM running, migration pending | [home-assistant.md](docs/home-assistant.md) |
| Ingress & SSL | 🔲 Planned | — |
| Single Sign-On (SSO) | 🔲 Planned | — |

## To-Do

### Research & Decisions

- [ ] **Docker Rootless Mode:** Research whether configuring Docker natively in rootless mode via NixOS is necessary for security, and how it impacts volume/bind-mount permissions.
- [x] **Paperless-AI Integration:** ~~Researched and deployed~~. Commented out — insufficient benefit to justify running it alongside Paperless-GPT.
- [x] **GPU Worker Desktop Environment:** Decided against a desktop environment. The GPU Worker is a dedicated AI worker only.
- [ ] **Wake-on-LAN Integration:** Explore how WOL can automatically wake the GPU Worker when its AI endpoints are queried.
- [ ] **Volume Layout Design:** Define the logic for where and how Docker containers bind-mount persistent config and data within the NixOS VMs, tied to the backup strategy.
- [x] **ZeroByte Configuration:** Backup targets, schedules, and retention policies configured and functional.
- [ ] **Ingress & SSL:** Research Tailscale's built-in SSL certificate generation for internal HTTPS vs. a standard reverse proxy.
- [ ] **NAS OS Choice:** Decide on the operating system for the NAS (ZimaOS, Unraid, or managed NixOS).
- [ ] **Single Sign-On (SSO):** Evaluate SSO solutions (Authentik, Authelia, Keycloak) for centralized login across services.
- [x] **Cloud Storage Choice:** Decided to keep NextExplorer for file storage. Nextcloud and Seafile will not be deployed.
- [x] **Notifications:** Decided on self-hosted [ntfy](https://ntfy.sh/). Gotify lacks UnifiedPush and requires WebSocket clients; HA notifications are not cluster-aware. ntfy is deployed in the `infra-stack`. See [monitoring.md](docs/monitoring.md).
- [x] **Dozzle:** Evaluated and dropped — too little functionality to justify deployment.
- [ ] **Nemoclaw:** Research Nemoclaw and evaluate its potential use-case in the homelab.
- [x] **GLM-OCR VM Migration:** Ollama node deprecated — too slow for inference. GPU Worker now handles all OCR and tagging tasks via llama-swap.
### Implementation

- [ ] **GitHub Runner:** Provision the GitHub Actions runner declaratively via NixOS and manage it via Comin.
- [ ] **Home Assistant Migration:** Migrate configuration and data from the legacy HA instance to the new HAOS VM.
- [x] **Storage Configuration:** One 512 GB SSD is used for application data in ZFS, the other is reserved for Frigate.
- [x] **GPU Worker Setup:** Provisioned with NixOS, Nvidia drivers, CUDA, and llama-swap. Functional as a dedicated AI worker. See [gpu-worker.md](docs/gpu-worker.md).
- [x] **GPU Top:** `nvtop` deployed on the `gpu-worker` node.
- [ ] **Paperless-GPT OCR:** Replace OCR provider for `paperless-gpt` with `docling-serve`.
- [ ] **Paperless-GPT Native Parsing:** Set up a secondary instance of `paperless-gpt` using `docling` as the backend for non-scanned/digital native documents (e.g., received via email).
- [x] **Paperless Email Ingress:** Email fetching, accounts, and routing rules configured and functional in Paperless-ngx.
- [x] **LLM Backend Migration (gpu-worker):** Migrated the `gpu-worker` from `ollama` to `llama-swap` as a native NixOS service with CUDA-accelerated `llama-cpp`. Initial model: Qwen3-VL-8B-Instruct (Q4_K_M). See [gpu-worker.md](docs/gpu-worker.md).
- [ ] **Tune Hermes GPU Offload:** Tune the `--n-gpu-layers` for the Qwen3.6-35B-A3B model on the GPU worker to maximize VRAM usage while leaving room for context.
- [x] **LLM Backend Migration (ollama-node):** Deprecated. The `ollama-node` proved too slow for inference. All LLM tasks now handled by the `gpu-worker` via llama-swap.
- [x] **Vision LLM Tuning:** Vision LLM parameters tuned and finalized.
- [ ] **ComfyUI Deployment:** Deploy [ComfyUI](https://github.com/comfyanonymous/ComfyUI) on the `gpu-worker` for GPU-accelerated image generation workflows.
- [ ] **Cloud Backups:** Configure ZeroByte with Rclone for encrypted backups to Google Drive.
- [ ] **Local Backups:** Set up Proxmox Backup Server on the Intel NUC.
- [ ] **Service Deployment:** Write Docker Compose files and deploy planned apps (Paperless-ngx, Frigate, NocoDB, n8n, IT-Tools, etc.). See [services.md](docs/services.md).
- [ ] **Tududi Deployment:** Write the Docker Compose definitions to deploy the [Tududi](https://github.com/chrisvel/tududi) task management service to the `services-stack`.
- [ ] **BamBuddy Deployment:** Write the Docker Compose definitions to deploy the [BamBuddy](https://bambuddy.cool/index.html) service to the `services-stack`.
- [ ] **ntfy Service Integrations:** Connect services to the self-hosted ntfy instance:
    - [ ] Grafana Webhook contact point with custom JSON payload template.
    - [ ] ZeroByte post-backup hook script.
    - [ ] Comin systemd `OnSuccess`/`OnFailure` notification units.
    - [ ] n8n / Kestra workflow failure notifications.
    - [ ] Home Assistant ntfy notify integration.
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
│   │   ├── hermes-node/        # Hermes AI coding agent
│   │   └── ollama-node/     # Deprecated
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