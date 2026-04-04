# Homelab Architecture & GitOps Workflow

This repository contains the Infrastructure as Code (IaC) and application deployments for a Proxmox-based homelab. 

## 🏗️ Core Architecture

The homelab utilizes a GitOps approach, separating the base operating system configuration from the application deployment layer.

* **Source of Truth:** GitHub (This repository)
* **OS Configuration Management:** NixOS & Colmena (Push Model) - See `/NixOS`
* **Application Deployment:** Docker Compose & Komodo (Pull Model)

## 🖥️ Node Provisioning

The infrastructure is split into several virtual machines and physical nodes to ensure proper separation of concerns:

### Core Proxmox VMs
- **GitHub Runner (NixOS VM):** Executes GitHub Actions pipelines for `colmena` deployments.
- **Infrastructure Stack (NixOS VM):** Hosts core infrastructure services via Docker Compose (e.g., Komodo).
- **Services Stack (NixOS VM):** Hosts the main application services via Docker Compose.
- **HAOS (VM):** Dedicated Home Assistant Operating System.
- **Tailscale Subnet Router (VM):** Dedicated routing for Tailscale access (may move to infrastructure stack later).

### Additional Nodes
- **NAS / MiniPC:** Handling storage and backups (OS TBD: ZimaOS or Unraid. Currently an Intel NUC i3).
- **GPU-Worker (NixOS Physical Node):** Dedicated workstation with an Nvidia 5060ti 16GB for AI workloads (not always online).

## 🚀 Services Overview

Below is the planned list of services running in the homelab. This list acts as a TODO and guide for implementation.

| Purpose | Tool | Notes |
| :--- | :--- | :--- |
| **Deployment / GitOps** | Komodo | Core deployment tool pulling compose files. |
| **Smart Home** | Home Assistant | Hosted in dedicated HAOS VM. |
| **Microcontrollers** | ESPHome | Firmwares for smart switches and sensors. |
| **Security / CCTV** | Frigate | |
| **Document Mgmt** | Paperless-ngx | Alongside Paperless-ai / Paperless-gpt. |
| **Automation** | n8n | |
| **PDF Tools** | Stirling PDF | |
| **Bookmarks / Archive**| Grimoire | |
| **Database/Spreadsheet**| NocoDB | |
| **Metrics / Data Logs** | InfluxDB | For Home Assistant long-term data tracking. |
| **Media Server** | Jellyfin | Will run on the NAS. |
| **Cloud Storage** | Nextcloud / Seafile | Needs research on which to pick. |
| **Monitoring** | Uptime Kuma | |
| **Visualization** | Grafana | |
| **Dashboard** | Homepage / Glance | |

## 🔄 Deployment Workflows

* **Infrastructure/OS Changes:** Push `.nix` updates to GitHub ➡️ Runner VM triggers ➡️ Colmena builds and pushes state to the nodes via SSH.
* **Application Changes:** Push `docker-compose.yml` updates to GitHub ➡️ Komodo detects changes ➡️ Komodo pulls configurations and updates Docker stacks on the Infrastructure/Services VMs.

## 📋 Master To-Do List

### Research & Decisions
- [x] **CPU Host Mode:** Research using CPU `host` mode for Proxmox VMs and its impact on performance vs live-migration natively.
- [ ] **Docker Rootless Mode:** Research whether configuring Docker natively in "rootless" mode via NixOS is necessary or strongly desirable for security, and how it impacts volume/bind-mount permissions.
- [ ] **GPU-Worker Desktop Environment:** Research and decide which desktop environment (e.g., KDE Plasma, GNOME, Hyprland) to provision via NixOS on the GPU-worker, as it doubles as a daily workstation and LLM backend.
- [ ] **Offline Node Handling:** Research the best practice in Colmena / GitHub Actions to cleanly skip or handle nodes (like the `gpu-worker`) that aren't inherently online during deployment, avoiding failed CI pipelines.
- [ ] **Comin Deployment Orchestration:** Research migrating from GitHub Actions to `comin` (a GitOps pull-model tool for NixOS) for infrastructure updates. A pull model natively solves the offline node problem since nodes fetch changes when they wake up.
- [ ] **Wake-on-LAN Integration:** Explore how Wake-on-LAN (WOL) can be integrated into the infrastructure stack to automatically wake the `gpu-worker` specifically when its AI endpoints are queried.
- [ ] **Volume Layout Design:** Figure out the optimal logic for where and how Docker containers bind-mount their persistent config and data within the NixOS VMs, mapping it back to the backup strategy.
- [ ] **ZeroByte Backups:** Research evaluating "ZeroByte" for configuring internal/external backup pipelines and scheduling, and how it compares to or replaces PBS.
- [ ] **NixOS VM Firmware:** Currently SeaBIOS is used for the NixOS VMs. Research the benefits of moving to UEFI (OVMF) on NixOS. What are the upsides? What would a migration of existing VMs entail?
- [x] **Secrets Management:** Evaluated and picked `agenix`. Need to finalize system keys in `secrets.nix` and encrypt the payloads on disk.
- [ ] **Ingress & SSL:** Research Tailscale's built-in SSL certificate generation for internal HTTPS vs using a standard reverse proxy.
- [ ] **Docker API Security:** Research the best method (TLS certificates or Tailscale network policies) to physically secure the exposed Docker API over the network when managing clients via Dockhand/Hawser.
- [ ] **NAS OS Choice:** Decide on the operating system for the future NAS unit (ZimaOS, Unraid, or managed NixOS).

### Implementation Tasks
- [ ] **Comin Migration:** Migrate the physical deployment workflow to leverage `comin` starting exclusively with the `gpu-worker` (to natively mitigate its offline nature), and weigh rolling it across the rest of the node cluster.
- [ ] **Dockhand & Hawser Migration:** Migrate the application deployment orchestrator from Komodo over to Dockhand, utilizing Hawser on the remote client VMs.
- [ ] **GitHub Actions for Deployment:** Set up GitHub Actions to handle triggering webhook deployments specifically when changes map to the `infra-stack` or `services-stack`.
- [ ] **Home Assistant Migration:** Migrate the configuration and data from the old Home Assistant instance over to the new homelab HAOS VM.
- [ ] **CPU Host Mode Migration:** Migrate the CPU type of existing Proxmox VMs to `host` mode via the Proxmox UI.
- [ ] **Storage Configuration:** Finalize and document the specific roles and mount points for the 3 Proxmox SSDs.
- [ ] **Secrets Implementation:** Remove hardcoded SSH keys from `configuration.nix` and replace them with the chosen secrets management system.
- [ ] **GPU Worker Setup:** Provision the dedicated GPU node with NixOS, Nvidia drivers, and AI tooling (LLM Studio). See [`docs/06-gpu-worker.md`](docs/06-gpu-worker.md).
- [ ] **Cloud Backups:** Implement the encrypted extramural backup pipeline to Google Drive.
- [ ] **Local Backups:** Set up the Proxmox Backup Server (PBS) on the Intel NUC.
- [ ] **Service Deployment:** Write docker-compose files and deploy the planned apps (Paperless-ngx, Frigate, NocoDB, n8n, etc.).

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