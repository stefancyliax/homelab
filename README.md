# Homelab Architecture & GitOps Workflow

This repository contains the Infrastructure as Code (IaC) and application deployments for a Proxmox-based homelab. 

## 🏗️ Core Architecture

The homelab utilizes a GitOps approach, separating the base operating system configuration from the application deployment layer.

* **Source of Truth:** GitHub (This repository)
* **OS Configuration Management:** NixOS & Colmena (Push Model) - See `/NixOS`
* **Application Deployment:** Docker Compose & Dockhand (Webhooks & Pull Model)

## 🖥️ Node Provisioning

The infrastructure is split into several virtual machines and physical nodes to ensure proper separation of concerns:

### Core Proxmox VMs
- **GitHub Runner (NixOS VM):** Executes GitHub Actions pipelines for `colmena` deployments.
- **Infrastructure Node (NixOS VM):** Runs natively orchestrated foundational engines (Dockhand) and hosts the `infra-stack` Docker Compose workloads.
- **Services Node (NixOS VM):** Dedicated to hosting the main `services-stack` docker application workloads (orchestrated via Hawser).
- **HAOS (VM):** Dedicated Home Assistant Operating System.
- **Tailscale Subnet Router (VM):** Dedicated routing for Tailscale access (may move to infrastructure stack later).

### Additional Nodes
- **NAS / MiniPC:** Handling storage and backups (OS TBD: ZimaOS or Unraid. Currently an Intel NUC i3).
- **GPU-Worker (NixOS Physical Node):** Dedicated workstation with an Nvidia 5060ti 16GB for AI workloads (not always online).

## 🚀 Services Overview

Below is the planned list of services running in the homelab. This list acts as a TODO and guide for implementation.

| Purpose | Tool | Notes |
| :--- | :--- | :--- |
| **Deployment / GitOps** | Dockhand & Hawser | Core deployment tool pulling compose files. |
| **Smart Home** | Home Assistant | Hosted in dedicated HAOS VM. |
| **Microcontrollers** | ESPHome | Firmwares for smart switches and sensors. |
| **Security / CCTV** | Frigate | |
| **Document Mgmt** | Paperless-ngx | Alongside Paperless-ai / Paperless-gpt. |
| **Automation** | n8n | |
| **PDF Tools** | Stirling PDF | |
| **AI / LLM Interface** | OpenWebUI | Universal WebUI connecting backend models (e.g., from gpu-worker) |
| **Bookmarks / Archive**| Grimoire | |
| **Database/Spreadsheet**| NocoDB | |
| **Metrics / Data Logs** | InfluxDB | For Home Assistant long-term data tracking. |
| **Monitoring** | Prometheus | Cluster-wide metrics scraper (Docker & Comin nodes). |
| **Media Server** | Jellyfin | Will run on the NAS. |
| **Cloud Storage** | Nextcloud / Seafile | Needs research on which to pick. |
| **Visualization** | Grafana | |
| **Dashboard** | Homepage | Fully declarative layout via YAML in GitOps. |

## 🔄 Deployment Workflows

* **Infrastructure/OS Changes:** Push `.nix` updates to GitHub ➡️ Runner VM triggers ➡️ Colmena builds and pushes state to the nodes via SSH.
* **Application Changes:** Push `docker-compose.yml` updates to GitHub ➡️ Local GH Runner hits internal Webhook ➡️ Dockhand securely pulls Git configurations and dictates updates mapped to the Infrastructure/Services Nodes via Hawser APIs.

## 📋 Master To-Do List

### Research & Decisions
- [x] **CPU Host Mode:** Research using CPU `host` mode for Proxmox VMs and its impact on performance vs live-migration natively.
- [ ] **Docker Rootless Mode:** Research whether configuring Docker natively in "rootless" mode via NixOS is necessary or strongly desirable for security, and how it impacts volume/bind-mount permissions.
- [ ] **GPU-Worker Desktop Environment:** Research and decide which desktop environment (e.g., KDE Plasma, GNOME, Hyprland) to provision via NixOS on the GPU-worker, as it doubles as a daily workstation and LLM backend.
- [x] **Offline Node Handling:** Solved via `comin`. The `gpu-worker` will autonomously poll for its branch updates dynamically whenever it goes online, cleanly decoupling it from the rigid timeout vulnerabilities inherent to centralized Colmena pushes.
- [x] **Comin Deployment Orchestration:** Decision made. The `gpu-worker` will exclusively utilize `comin` to natively pull its own configuration state from Git whenever it powers on, flawlessly bypassing the offline timeout vulnerabilities inherent to push-based orchestrators like Colmena. (Tracked in Implementation Tasks)
- [ ] **Wake-on-LAN Integration:** Explore how Wake-on-LAN (WOL) can be integrated into the infrastructure stack to automatically wake the `gpu-worker` specifically when its AI endpoints are queried.
- [ ] **Volume Layout Design:** Figure out the optimal logic for where and how Docker containers bind-mount their persistent config and data within the NixOS VMs, mapping it back to the backup strategy.
- [ ] **ZeroByte Backups:** Initially deployed to the `infra-stack` for active testing. Full research and comparison against PBS is pending before official adoption.
- [x] **NixOS Node Renaming:** Renamed the underlying NixOS nodes to `infra-node` and `services-node` to avoid architectural confusion with the docker-compose stacks natively resting on top of them.
- [x] **NixOS VM Firmware:** Researched. Migrating existing SeaBIOS VMs to UEFI is exceptionally tedious (requires resizing partitions for EFI). SeaBIOS has no performance penalty post-boot. Conclusion: Leave existing VMs on SeaBIOS; build all future VMs with OVMF/UEFI natively.
- [x] **Secrets Management:** Evaluated and picked `agenix`. Need to finalize system keys in `secrets.nix` and encrypt the payloads on disk.
- [ ] **Ingress & SSL:** Research Tailscale's built-in SSL certificate generation for internal HTTPS vs using a standard reverse proxy.
- [x] **Docker API Security:** Resolved natively. Instead of generating manual TLS certificates to expose the raw Docker API over the network, the `Hawser` agent handles security automatically. It mounts the raw local socket under the hood and securely proxies traffic via its own REST interface strictly guarded by the shared `agenix` encrypted token.
- [ ] **NAS OS Choice:** Decide on the operating system for the future NAS unit (ZimaOS, Unraid, or managed NixOS).
- [ ] **Single Sign-On (SSO):** Research and evaluate SSO solutions (e.g., Authentik, Authelia, or Keycloak) to provide centralized login and identity management across the various web services.

### Implementation Tasks
- [ ] **Comin Migration:** Migrate the physical deployment workflow to leverage `comin` starting exclusively with the `gpu-worker` (to natively mitigate its offline nature), and weigh rolling it across the rest of the node cluster.
- [x] **Dockhand & Hawser Migration:** Successfully migrated the infrastructure orchestrator away from Komodo and over to natively defined Dockhand and Hawser nodes via NixOS.
- [x] **GitHub Actions for Deployment:** Workflow files created to automatically trigger internal webhooks inside the self-hosted network when `infra-stack` or `services-stack` are updated.
- [ ] **Home Assistant Migration:** Migrate the configuration and data from the old Home Assistant instance over to the new homelab HAOS VM.
- [x] **CPU Host Mode Migration:** Migrated the CPU type of all existing Proxmox VMs directly to `host` mode via the UI.
- [ ] **Storage Configuration:** Finalize and document the specific roles and mount points for the 3 Proxmox SSDs.
- [ ] **GPU Worker Setup:** Provision the dedicated GPU node with NixOS, Nvidia drivers, and AI tooling (LLM Studio). See [`docs/06-gpu-worker.md`](docs/06-gpu-worker.md).
- [ ] **Cloud Backups:** Implement the encrypted extramural backup pipeline to Google Drive.
- [ ] **Local Backups:** Set up the Proxmox Backup Server (PBS) on the Intel NUC.
- [ ] **Monitoring Stack:** Deploy Prometheus, Grafana, and InfluxDB to the `infra-stack`.
    - [ ] Configure Prometheus scrapers for `comin` and Docker daemon metrics.
    - [ ] Set up basic Grafana dashboards for cluster-wide node and container health.
- [ ] **Service Deployment:** Write docker-compose files and deploy the planned apps (Paperless-ngx, Frigate, NocoDB, n8n, etc.).
- [ ] **Dashboard API: Proxmox & PBS:** Generate an explicit API Token within Proxmox/PBS to extract hypervisor hardware thresholds natively into `widgets.yaml`.
- [ ] **Dashboard API: Home Assistant:** Configure a Long-Lived Access Token to query specific switch/temperature `entity_id` telemetry securely onto internal service buttons.
- [ ] **Dashboard API: Paperless-ngx:** Generate a secure API Token to dynamically poll the scanner "Inbox" count onto the dashboard's service badge.
- [ ] **Dashboard API: Grafana & SSO:** Pipe generic localized metrics or SSO lockout states from Authentik and Grafana securely through the Homepage REST parser.

## 🛠️ NixOS Management (Colmena)

The NixOS configurations are managed using **Colmena**. You can apply changes from your local machine (remote) or directly on a node (local).

### Remote Deployment (from your Mac/Runner)
To push configurations to one or all nodes from your local machine:
```bash
# Apply to all nodes
export COLMENA_SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
colmena apply --flake ./NixOS

# Apply to a specific node (e.g., gpu-worker)
colmena apply --flake ./NixOS --on gpu-worker
```

### Local Provisioning (Directly on a Node)
If you are logged into a NixOS node and want to apply the configuration locally (e.g., during bootstrapping):
```bash
cd NixOS/
sudo colmena apply-local --flake . --on gpu-worker
```

> **Note:** For the first-time provisioning of a new node, ensure your user is added to `trusted-users` in `common.nix` and has `NOPASSWD` sudo rights as defined in the configuration.