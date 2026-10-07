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

The homelab runs on two standalone Proxmox hosts, `phil` and `vault`, with multiple isolated VMs, plus a physical GPU workstation.

For full hardware specs, networking, and service placement details, see [docs/architecture.md](docs/architecture.md).

## Features & Status

| Feature | Status | Details |
|---|---|---|
| NixOS Provisioning (Comin) | ✅ Done | [deployment.md](docs/deployment.md) |
| Secrets Management (Agenix) | ✅ Done | [deployment.md](docs/deployment.md) |
| GitOps App Deployment (Dockhand/Hawser) | ✅ Done | [deployment.md](docs/deployment.md) |
| GitHub Actions CI/CD | ✅ Done | [deployment.md](docs/deployment.md) |
| Dashboard (Homepage) | ✅ Done | [architecture.md](docs/architecture.md) |
| Cloud Backups (ZeroByte) | ✅ Done | [backup.md](docs/backup.md) |
| ~~Local Backups (PBS)~~ | ❌ Dropped | [backup.md](docs/backup.md#local-backups) |
| Monitoring (Prometheus/Grafana/InfluxDB) | ✅ Done | [monitoring.md](docs/monitoring.md) |
| GPU Worker / AI Stack (llama-swap) | ✅ Done | [gpu-worker.md](docs/gpu-worker.md) |
| Hermes Node (Remote AI Agent) | ✅ Done | [architecture.md](docs/architecture.md) |
| ~~Ollama Node (LLM Inference)~~ | ❌ Deprecated | GPU Worker handles all inference |
| Services (Paperless, Grimmory, etc.) | 🚧 Ongoing | [services.md](docs/services.md) |
| Home Assistant | ✅ Done | [home-assistant.md](docs/home-assistant.md) |
| NAS & Media on `vault` | 🔲 Planned | [architecture.md](docs/architecture.md#workload-placement) |
| Ingress & SSL (Caddy + Porkbun DNS) | ✅ Done | [deployment.md](docs/deployment.md) |
| Single Sign-On (Authelia OIDC & Proxy) | ✅ Done | [deployment.md](docs/deployment.md) |
| Scanner Service (HP ScanJet Pro 2600 f1) | 🔲 Planned | [scanner/README.md](scanner/README.md) |

## To-Do

### Research & Decisions

- [ ] **Docker Rootless Mode:** Research whether configuring Docker natively in rootless mode via NixOS is necessary for security, and how it impacts volume/bind-mount permissions.
- [x] **Paperless-AI Integration:** ~~Researched and deployed~~. Commented out — insufficient benefit to justify running it alongside Paperless-GPT.
- [x] **GPU Worker Desktop Environment:** Decided against a desktop environment. The GPU Worker is a dedicated AI worker only.
- [x] **Wake-on-LAN Integration:** WOL enabled via NetworkManager profile on the gpu-worker (`enp7s0`). Magic packets sent from Home Assistant or the `infra-node` via `wakeonlan`.
- [ ] **Volume Layout Design:** Define the logic for where and how Docker containers bind-mount persistent config and data within the NixOS VMs, tied to the backup strategy.
- [x] **ZeroByte Configuration:** Backup targets, schedules, and retention policies configured and functional.
- [x] **Ingress & SSL:** Caddy deployed with automatic wildcard TLS via Porkbun DNS-01 ACME challenge. All services accessible via `*.home.stefancyliax.de`.
- [x] **NAS OS Choice:** Decided on a managed NixOS VM (`storage-node`) on `vault`, without parity — with 6 TB + 2 TB + 1 TB disks Unraid's parity array would leave only 3 TB usable. See [architecture.md](docs/architecture.md#storage-node-nixos-vm).
- [x] **Single Sign-On (SSO):** Authelia deployed as OIDC provider on the `infra-stack`. See [deployment.md](docs/deployment.md#single-sign-on-sso) for onboarding procedures.
- [x] **Cloud Storage Choice:** Decided to keep NextExplorer for file storage. Nextcloud and Seafile will not be deployed.
- [x] **Notifications:** Decided on self-hosted [ntfy](https://ntfy.sh/). Gotify lacks UnifiedPush and requires WebSocket clients; HA notifications are not cluster-aware. ntfy is deployed in the `infra-stack`. See [monitoring.md](docs/monitoring.md).
- [x] **Dozzle:** Evaluated and dropped — too little functionality to justify deployment.
- [x] **Nemoclaw:** Decided against it; Hermes is the agent.
- [ ] **GLM-OCR on `vault`:** Benchmark GLM-OCR on `vault`'s CPU (llama.cpp, quantized GGUF, a few real scans) to see whether it can serve as an always-on OCR backend for Paperless-GPT when the `gpu-worker` is off. The iGPU is reserved for Jellyfin, so CPU only. Runs as a temporary test in `vault`'s unallocated RAM, not as a planned resident of a VM.
- [x] **GLM-OCR VM Migration:** Ollama node deprecated — too slow for inference. GPU Worker now handles all OCR and tagging tasks via llama-swap.
### Implementation

- [x] **GitHub Runner:** `runner-node` runs on `vault`, declared in the flake (`modules/github-runner.nix`) and managed via Comin; runner package bumps are proposed as pull requests by `update-runner.yml`. The legacy VM on `phil` is retired. See [deployment.md](docs/deployment.md#cicd-pipeline).
- [x] **Home Assistant Migration:** Configuration and data migrated from the legacy instance to the HAOS VM.
- [x] **Storage Configuration:** 512 GB SSD is formatted with ext4 and mounted at `/mnt/data` on the `services-node` for application data and media.
- [x] **GPU Worker Setup:** Provisioned with NixOS, Nvidia drivers, CUDA, and llama-swap. Functional as a dedicated AI worker. See [gpu-worker.md](docs/gpu-worker.md).
- [x] **GPU Top:** `nvtop` deployed on the `gpu-worker` node.
- [x] **Paperless-GPT OCR:** ~~Replace OCR provider for `paperless-gpt` with `docling-serve`.~~ Dropped — GLM-OCR on the `gpu-worker` covers OCR.
- [x] **Paperless-GPT Native Parsing:** ~~Set up a secondary instance of `paperless-gpt` using `docling` as the backend for non-scanned/digital native documents (e.g., received via email).~~ Dropped — Paperless-ngx already extracts the text layer of digital documents itself.
- [x] **Paperless Email Ingress:** Email fetching, accounts, and routing rules configured and functional in Paperless-ngx.
- [x] **LLM Backend Migration (gpu-worker):** Migrated the `gpu-worker` from `ollama` to `llama-swap` as a native NixOS service with CUDA-accelerated `llama-cpp`. Initial model: Qwen3-VL-8B-Instruct (Q4_K_M). See [gpu-worker.md](docs/gpu-worker.md).
- [ ] **Tune Hermes GPU Offload:** Tune the `--n-gpu-layers` for the Qwen3.6-35B-A3B model on the GPU worker to maximize VRAM usage while leaving room for context.
- [x] **LLM Backend Migration (ollama-node):** Deprecated. The `ollama-node` proved too slow for inference. All LLM tasks now handled by the `gpu-worker` via llama-swap.
- [x] **Vision LLM Tuning:** Vision LLM parameters tuned and finalized.
- [ ] **ComfyUI Deployment:** Deploy [ComfyUI](https://github.com/comfyanonymous/ComfyUI) on the `gpu-worker` for GPU-accelerated image generation workflows.
- [x] **Cloud Backups:** Configure ZeroByte with Rclone for encrypted backups to Google Drive.
- [x] **Local Backups:** Decided against Proxmox Backup Server. VMs are rebuilt from the repo; data is covered by ZeroByte and the NAS copies. See [backup.md](docs/backup.md#local-backups).
- [ ] **Service Deployment:** Write Docker Compose files and deploy planned apps (Paperless-ngx, Frigate, NocoDB, etc.). See [services.md](docs/services.md).
- [x] **Tududi Deployment:** Docker Compose definition drafted in `services-stack` (currently commented out).
- [ ] **BamBuddy Deployment:** Write the Docker Compose definitions to deploy the [BamBuddy](https://bambuddy.cool/index.html) service to the `storage-stack` on `storage-node`.
- [ ] **Pilot Deployment:** Deploy [Pilot](https://pilot.quantflow.studio/) (`ghcr.io/qf-studio/pilot`, gateway on `:9090`) to the `agent-tools-stack` on `agent-tools-node` as an autonomous ticket-to-PR agent. Spike outcome: GitHub issue polling (label `pilot`, no public ingress needed), Claude Pro subscription via `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token`, state and repo checkouts bind-mounted on the VM, Caddy route behind Authelia, `/metrics` scraped by VictoriaMetrics. Open points: Pilot's intent classifier and epic decomposition expect an `ANTHROPIC_API_KEY`; there is no Gemini backend (only via `opencode` with a Gemini API key); target repo still to be chosen.
- [x] **ntfy Service Integrations:** Connect services to the self-hosted ntfy instance:
    - [x] ZeroByte backup notifications (configured via ZeroByte UI).
    - [x] Comin deployment notifications via `postDeploymentCommand` in `modules/comin.nix`.
    - [x] Dockhand deployment notifications (configured via Dockhand UI).
    - [x] Proxmox hypervisor events (configured via Proxmox webhook target).
    - [x] GitHub Actions CI failure notifications (`nixos-check.yml`).
- [ ] **Dashboard APIs:** Connect Homepage widgets to live data sources:
    - [x] ~~Proxmox API token for hypervisor metrics.~~ Widget removed; Homepage only links to PDM, `vault` and `phil`.
    - [x] ~~PBS API tokens for backup metrics.~~ PBS dropped.
    - [ ] Home Assistant long-lived access token for entity telemetry.
    - [ ] Paperless-ngx API token for inbox count badges.
    - [ ] Grafana & SSO metrics via the Homepage REST parser.
- [ ] **Scanner Service Deployment:** Deploy the HP ScanJet Pro 2600 f1 container stack (`scanner/`) on the secondary Proxmox node once online. See [scanner/README.md](scanner/README.md) for open checklist items.
- [ ] **`vault` DMI ASPM:** The CPU package on `vault` idles at 2.3 W but never gets past package C3 (limit is C10, PCIe L1 is on everywhere, SATA, USB, chipset LTR and the iGPU driver are ruled out). Next time in the BIOS, check the DMI entries under Advanced → Platform Misc Configuration (DMI Link ASPM Control, DMI ASPM, DMI Gen3 ASPM) and set them to enabled / L1. Verify with `powertop` (Idle stats): the Pkg column should show time in C6 or deeper. Worth about 2 W at most.
- [ ] **Grafana Dashboards:** Set up proper Grafana dashboards for monitoring, covering both Proxmox hosts (`phil`, `vault`) and all nodes. See [monitoring.md](docs/monitoring.md).

### Expansion: NAS, Media and New Nodes

Plan and rationale: [architecture.md](docs/architecture.md#workload-placement), [proxmox-setup.md](docs/proxmox-setup.md).

#### Decisions

- [x] **Frigate on `phil`:** Uses the stronger Iris Xe iGPU (80 EU vs. 32 EU on `vault`) and a dedicated 250 GB Samsung SSD.
- [x] **Garage scope:** Dev use only, ~100 GB, no redundancy needed.
- [x] **No cluster:** `phil` and `vault` are standalone and managed through Proxmox Datacenter Manager, which runs as a VM on `phil` (a two-node cluster needs a QDevice for quorum).
- [x] **HDD layout:** No parity. 6 TB bulk/media, 1 TB scratch (and Garage data, if the disk follows Garage), 2 TB local backup copy of important shares.
- [x] **No PBS:** No Proxmox Backup Server and no VM image backups.
- [x] **`agent-node`:** Supersedes `hermes-node`; headless with herdr. Planned as `chiefofstaff-node` before the rename.
- [x] **Artifact hosting:** Garage website bucket with one path per artifact. No Authelia in front; sharing the `home.stefancyliax.de` parent domain with the other services is accepted.
- [x] **`services-node` data disk:** Replace the virtual disk on `ZFS-Store` with an SSD passed through whole (ext4) and retire the ZFS pool on `phil`. Leaner (no ZFS cache on a 32 GB host) and consistent with the Frigate SSD and the `vault` HDDs; costs Proxmox-side snapshots of that disk.
- [x] **`vault` disks:** Proxmox on the NVMe SSD only for now (`local` 100 GB, `local-lvm` ~400 GB); the SATA SSD stays unassigned. HDD filesystems: btrfs on the 6 TB and 2 TB, XFS on the 1 TB (Garage's recommended filesystem for its data directory).
- [x] **Frigate VM:** Dedicated `frigate-node` VM. Not a CT: Frigate does not officially support LXC, and nothing else on `phil` needs to share the iGPU.
- [x] **GitHub runner exposure:** `nixos-check.yml` runs on `pull_request` on the self-hosted runner. Covered: the repo requires approval for all outside contributors before workflows run.
- [ ] **NAS share layout:** Define which shares `storage-node` offers and which count as important for backup (ties in with the Volume Layout Design item above).
- [ ] **`agent-node` scope:** List the maintenance flows that run there and decide what the autonomous agents may reach on the LAN and which credentials they hold.
- [x] **Service distribution:** `storage-node` (was `nas-node`) holds the shares, Jellyfin, the scanner service, NextExplorer and BamBuddy. A new `agent-tools-node` on `vault` holds what the agents rely on: Hindsight, Parakeet, Open-WebUI, NocoDB, Garage, artifact hosting and pilot. A new `work-tools-node` on `phil` runs a separate Hindsight instance for work. See [architecture.md](docs/architecture.md#workload-placement).
- [x] **Dropped services:** ESPHome as a standalone container, Stirling PDF, Tududi and Paperless-AI.
- [x] **`vault` RAM reserve:** `vault` goes from 32 GB to 48 GB and keeps at least 16 GB unallocated for experiments.
- [ ] **VM sizing:** Allocate RAM and CPU per guest. `phil` runs fine at about 26 GB allocated. First draft for `vault` (30 GB of 48 GB): `storage-node` 6 GB (pinned by the passthrough), `runner-node` 6 GB, `agent-node` 6 GB, `agent-tools-node` 10 GB, host 2 GB. Estimates, to be checked against real use.
- [ ] **Garage data disk:** Garage moved from `storage-node` to `agent-tools-node`. Decide whether the 1 TB HDD is passed through to `agent-tools-node` instead, or Garage's ~100 GB live on the VM disk on the NVMe.
#### Implementation

- [ ] **⚠️ Migrate the `services-node` data disk (important data):** `/mnt/data` holds the Paperless documents and the Grimmory books. Convert the 860 EVO from the `ZFS-Store` pool to a whole-disk ext4 passthrough, using a spare SanDisk Ultra 500 GB SSD as staging copy so there is always at least one verified local copy besides the cloud backup:
    - [ ] Verify a fresh ZeroByte backup and Paperless export by test-restoring a sample.
    - [ ] Attach the SanDisk SSD to `phil` temporarily (free bay or USB adapter), pass it to `services-node` and format it ext4.
    - [ ] Stop everything using `/mnt/data` (Paperless incl. Postgres, Grimmory, ZeroByte, Samba), copy to the SanDisk with `rsync -aHAX`, then verify with a checksum pass.
    - [ ] Only after that verification: remove the virtual disk, destroy `ZFS-Store`, pass the 860 EVO through whole, format it ext4, copy the data back and verify again.
    - [ ] Switch `fileSystems."/mnt/data"` in `services-node/configuration.nix` to the new UUID, reboot, and check Paperless (document count, open a few documents), the Samba shares and the next ZeroByte run.
    - [ ] Keep the SanDisk copy as rollback for at least two weeks; it can sit unplugged on the shelf. Afterwards it is a spare.
- [ ] **iGPU passthrough spike:** Validate Iris Xe → VM on `phil` and UHD 770 → VM on `vault` (OVMF, `intel_gpu_top`, VAAPI/QSV test) before building on it. Fallback: CT with `/dev/dri`.
- [x] **`vault` baseline:** `vault` is online with its Caddy route, OIDC login, metric server → VictoriaMetrics and ntfy webhook.
- [x] **Proxmox Datacenter Manager:** Running as a VM on `phil` at `proxmox.home.stefancyliax.de`, with both hosts as remotes.
- [ ] **`vault` RAM:** Install the second 16 GB stick (32 → 48 GB).
- [ ] **`storage-node`:** NixOS VM on `vault` with the 6 TB and 2 TB HDDs passed through by-id (btrfs), plus the 1 TB (XFS) unless it goes to `agent-tools-node`; add to the flake with Comin and Hawser; Samba/NFS shares.
- [ ] **Data migration:** Inventory the existing data on the three HDDs and fix the shuffle order before any disk is reformatted.
- [ ] **NAS backups:** Local restic copy of the important shares on the 2 TB disk plus offsite via ZeroByte/restic; media stays unprotected by design.
- [ ] **HAOS backups:** Point Home Assistant's built-in backups at a NAS share so they are covered without PBS.
- [ ] **`agent-tools-node` / `agent-tools-stack`:** NixOS VM on `vault`; add to the flake with Comin and Hawser and a `dockhand-agent-tools.yml` workflow. Move Hindsight, Parakeet, Open-WebUI and NocoDB over from the `services-stack` including their volumes, then repoint their Caddy routes, Homepage entries and the Hindsight URLs the agents use.
- [ ] **`work-tools-node` / `work-tools-stack`:** NixOS VM on `phil` with a second Hindsight instance for work, with its own Caddy route.
- [ ] **Garage:** `services.garage` on `agent-tools-node` (single node, data per the Garage data disk decision, metadata on the VM disk, secrets via Agenix).
- [ ] **Artifact hosting:** One Garage bucket (`artifacts`) in website mode behind a single Caddy route (`artifacts.home.stefancyliax.de` → Garage web endpoint, no Authelia). Each artifact is a path in the bucket, so pushing a file publishes it without touching Caddy or DNS. Also expose the S3 API (`s3.home.stefancyliax.de`) for uploads, create one write key per machine (Agenix on `agent-node`), and add a small `publish-artifact` helper that uploads and prints the URL.
- [ ] **`storage-stack` / Jellyfin:** New Compose stack on `storage-node` with QuickSync, a `dockhand-storage.yml` workflow, and Authelia via the SSO plugin.
- [x] **NextExplorer move:** NextExplorer runs in the `storage-stack` with a `dockhand-storage.yml` workflow, and its Caddy route points at `storage-node`. No data moved: it only gave access to `/mnt/data` on `services-node`.
- [ ] **Remove dropped services:** Delete the commented-out Stirling PDF, Tududi and Paperless-AI blocks and their volumes from the `services-stack` compose files.
- [ ] **Scanner service:** Move the HP ScanJet Pro 2600 f1 container from `services-node` to `storage-node` on `vault`, where the scanner physically stands: merge the `setup_scanner_raspberry_pi` branch (in progress), pass the scanner through by USB to the VM, map `/dev/bus/usb` in the Compose file, and mount the `paperless-consume` share from `services-node` as the output directory.
- [ ] **`frigate-node` / `frigate-stack`:** NixOS VM on `phil` with Iris Xe and the 250 GB Samsung SSD passed through (check its SMART wear level first) and a NIC on the IoT VLAN; ballooning disabled; OpenVINO detector; 1–2 cameras with motion/event-based retention sized to the SSD; Home Assistant integration; ntfy `homelab-security`; Authelia forward_auth.
- [ ] **`agent-node` headless check:** Verify Obsidian Sync runs headless (official headless client) and how Antigravity is used without a desktop (remote SSH from the laptop or CLI).
- [ ] **`agent-node`:** Headless NixOS VM on `vault` with Hermes, Claude Code, Antigravity, herdr, the Obsidian vault (Obsidian Sync) and systemd timers for the maintenance flows.
- [ ] **Retire `hermes-node`:** After migrating to `agent-node`, remove the node from the flake, its Syncthing route in Caddy and its scrape targets.
- [ ] **Observability & ingress for new guests:** Scrape targets, Homepage entries and Caddy routes for `vault` and every new node.

### Completed


- [x] **Centralized Logging:** Deployed Loki in infra-stack and Promtail via NixOS common module for shipping journald and Docker logs from all nodes.
- [x] **Monitoring Stack:** Consolidated onto VictoriaMetrics, Grafana, and Loki with node exporters and fully declarative dashboards!
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
- [x] **Speaches STT Migration:** Replaced Whisper model with NVIDIA Parakeet v3 ONNX model for improved transcription speed.

## Repository Structure

```
homelab/
├── NixOS/                  # NixOS configurations (Flake & Comin)
│   ├── flake.nix           # Flake entry point
│   ├── common.nix          # Shared base config for all nodes
│   ├── nodes/              # Per-node configurations
│   │   ├── infra-node/
│   │   ├── services-node/
│   │   ├── gpu-worker/
│   │   ├── hermes-node/        # Hermes AI coding agent
│   │   ├── runner-node/        # Self-hosted GitHub Actions runner
│   │   └── another-node/       # Auxiliary / test node
│   ├── modules/            # Reusable NixOS modules (Dockhand, Hawser, Llama-swap)
│   ├── secrets/            # Agenix-encrypted secret files (.age)
│   └── secrets.nix         # SSH key → secret file mappings
├── infra-stack/            # Docker Compose for infrastructure services
│   ├── docker-compose.yml
│   └── homepage/           # Homepage dashboard config (YAML)
├── services-stack/         # Docker Compose for application services
│   ├── docker-compose.yml
│   └── paperless.compose.yml
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
    ├── dockhand-services.yml
    ├── dockhand-paperless.yml
    ├── dockhand-storage.yml
    ├── nixos-check.yml
    └── update-runner.yml
```

## Documentation

| Document | Description |
|---|---|
| [Architecture](docs/architecture.md) | Hardware specs, networking, VM landscape, and service placement |
| [Proxmox Setup](docs/proxmox-setup.md) | Hypervisor configuration and VM provisioning baseline |
| [Deployment](docs/deployment.md) | NixOS provisioning (Comin), app deployment (Dockhand/Hawser), CI/CD, and commands |
| [Backup](docs/backup.md) | Backup strategy (ZeroByte, NAS copies) and recovery procedures |
| [GPU Worker](docs/gpu-worker.md) | AI workstation provisioning and tooling |
| [Services](docs/services.md) | Catalog of user-facing homelab services |
| [Home Assistant](docs/home-assistant.md) | Smart home ecosystem and integrations |
| [Monitoring](docs/monitoring.md) | Prometheus, Grafana, and InfluxDB monitoring stack |