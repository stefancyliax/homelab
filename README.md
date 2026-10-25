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
| Monitoring (VictoriaMetrics/Grafana/Loki) | ✅ Done | [monitoring.md](docs/monitoring.md) |
| GPU Worker / AI Stack (llama-swap) | ✅ Done | [gpu-worker.md](docs/gpu-worker.md) |
| Hermes Node (Remote AI Agent) | ✅ Done | [architecture.md](docs/architecture.md) |
| ~~Ollama Node (LLM Inference)~~ | ❌ Deprecated | GPU Worker handles all inference |
| Services (Paperless, Grimmory, etc.) | 🚧 Ongoing | [services.md](docs/services.md) |
| Home Assistant | ✅ Done | [home-assistant.md](docs/home-assistant.md) |
| NAS & Media on `vault` | 🚧 Ongoing | [architecture.md](docs/architecture.md#workload-placement) |
| Ingress & SSL (Caddy + Porkbun DNS) | ✅ Done | [deployment.md](docs/deployment.md) |
| Single Sign-On (Authelia OIDC & Proxy) | ✅ Done | [deployment.md](docs/deployment.md) |
| Scanner Service (HP ScanJet Pro 2600 f1) | ✅ Done | [scanner/README.md](storage-stack/scanner/README.md) |

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
- [x] **Hindsight Local Models on `vault` (Embedding & SLM):** Both run as llama.cpp sidecars on `agent-tools-node` (see the two items under Implementation). Measured on the i5-12600K with 6 threads: Gemma 4 E2B generates about 17 tokens/s, so retaining a short note takes 46–81 s in the background; recall needs no LLM and answers instantly. The embedding sidecar uses about 0.7 GB RAM. Reflect stays on the `gpu-worker`. Not pursued unless recall quality gives a reason: calibrating `HINDSIGHT_API_SEMANTIC_LINK_MIN_SIMILARITY` (default 0.7), a multilingual reranker, and pinning the VM to P-cores.
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
- [ ] **Pi-hole Deployment:** Deploy [Pi-hole](https://pi-hole.net/) to the `infra-stack`. See [services.md](docs/services.md).
- [x] **Tududi Deployment:** Docker Compose definition drafted in `services-stack` (later dropped and removed).
- [ ] **BamBuddy Deployment:** Write the Docker Compose definitions to deploy the [BamBuddy](https://bambuddy.cool/index.html) service to the `storage-stack` on `storage-node`.
- [ ] **Pilot Deployment:** Deploy [Pilot](https://pilot.quantflow.studio/) (`ghcr.io/qf-studio/pilot`, gateway on `:9090`) to the `agent-tools-stack` on `agent-tools-node` as an autonomous ticket-to-PR agent. Spike outcome: GitHub issue polling (label `pilot`, no public ingress needed), Claude Pro subscription via `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token`, state and repo checkouts bind-mounted on the VM, Caddy route behind Authelia, `/metrics` scraped by VictoriaMetrics. Open points: Pilot's intent classifier and epic decomposition expect an `ANTHROPIC_API_KEY`; there is no Gemini backend (only via `opencode` with a Gemini API key); target repo still to be chosen.
- [x] **Host `google/embeddinggemma-2` for Hindsight:** `hindsight-embeddings` in the `agent-tools-stack` serves EmbeddingGemma 2 (Q8_0 GGUF, 768 dimensions) through llama.cpp's OpenAI-compatible `/v1/embeddings`, and both Hindsight instances use it via `HINDSIGHT_API_EMBEDDINGS_PROVIDER=openai` (port 8082). This replaced the built-in `bge-small-en-v1.5` (384 dimensions, English only); the memory store was started fresh, because Hindsight cannot change the dimension of stored memories.
- [x] **Host Extraction SLM on `vault` for Hindsight:** `hindsight-llm` in the `agent-tools-stack` runs Gemma 4 E2B (Q4_K_M) on llama.cpp with 6 threads, CPU only. Hindsight sends retain and consolidation to it, so background memory work no longer needs the `gpu-worker`; reflect stays on the `gpu-worker`. The work instance uses it for all LLM calls (port 8081).
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
- [ ] **`vault` DMI ASPM:** The CPU package on `vault` idles at 2.3 W but never gets past package C3 (limit is C10, PCIe L1 is on everywhere, SATA, USB, chipset LTR and the iGPU driver are ruled out). Next time in the BIOS, check the DMI entries under Advanced → Platform Misc Configuration (DMI Link ASPM Control, DMI ASPM, DMI Gen3 ASPM) and set them to enabled / L1. Verify with `powertop` (Idle stats): the Pkg column should show time in C6 or deeper. Worth about 2 W at most.
- [ ] **Grafana Dashboards:** Set up proper Grafana dashboards for monitoring, covering both Proxmox hosts (`phil`, `vault`) and all nodes. See [monitoring.md](docs/monitoring.md).

### Expansion: NAS, Media and New Nodes

Plan and rationale: [architecture.md](docs/architecture.md#workload-placement), [proxmox-setup.md](docs/proxmox-setup.md).

#### Decisions

- [x] **Frigate on `phil`:** Uses the stronger Iris Xe iGPU (80 EU vs. 32 EU on `vault`) and a dedicated SSD (the 512 GB SanDisk Ultra 3D, replacing the 250 GB Samsung planned at first).
- [x] **Garage scope:** Dev use only, ~100 GB, no redundancy needed.
- [x] **No cluster:** `phil` and `vault` are standalone and managed through Proxmox Datacenter Manager, which runs as a VM on `phil` (a two-node cluster needs a QDevice for quorum).
- [x] **HDD layout:** No parity. 6 TB bulk/media, 1 TB scratch, 2 TB local backup copy of important shares.
- [x] **No PBS:** No Proxmox Backup Server and no VM image backups.
- [x] **`agent-node`:** Supersedes `hermes-node`; headless with herdr. Planned as `chiefofstaff-node` before the rename.
- [x] **Artifact hosting:** Garage website bucket with one path per artifact. No Authelia in front; sharing the `home.stefancyliax.de` parent domain with the other services is accepted.
- [x] **`services-node` data disk:** Replace the virtual disk on `ZFS-Store` with an SSD passed through whole (ext4) and retire the ZFS pool on `phil`. Leaner (no ZFS cache on a 32 GB host) and consistent with the Frigate SSD and the `vault` HDDs; costs Proxmox-side snapshots of that disk.
- [x] **`vault` disks:** Proxmox on the NVMe SSD only for now (`local` 100 GB, `local-lvm` ~400 GB); the SATA SSD goes to `agent-tools-node` for Garage. HDD filesystems: btrfs on the 6 TB and 2 TB, XFS on the 1 TB (Garage's recommended filesystem for its data directory).
- [x] **Frigate VM:** Dedicated `frigate-node` VM. Not a CT: Frigate does not officially support LXC, and nothing else on `phil` needs to share the iGPU.
- [x] **GitHub runner exposure:** `nixos-check.yml` runs on `pull_request` on the self-hosted runner. Covered: the repo requires approval for all outside contributors before workflows run.
- [ ] **NAS share layout:** Define which shares `storage-node` offers and which count as important for backup (ties in with the Volume Layout Design item above).
- [ ] **`agent-node` scope:** List the maintenance flows that run there and decide what the autonomous agents may reach on the LAN and which credentials they hold.
- [x] **Service distribution:** `storage-node` (was `nas-node`) holds the shares, Jellyfin, the scanner service, NextExplorer and BamBuddy. A new `agent-tools-node` on `vault` holds what the agents rely on: Hindsight, Parakeet, Open-WebUI, NocoDB, Garage, artifact hosting and pilot. A new `work-tools-node` on `phil` runs a separate Hindsight instance for work. See [architecture.md](docs/architecture.md#workload-placement).
- [x] **Dropped services:** ESPHome as a standalone container, Stirling PDF, Tududi and Paperless-AI.
- [x] **`vault` RAM reserve:** `vault` has 48 GB and keeps at least 16 GB unallocated for experiments.
- [ ] **VM sizing:** Allocate RAM and CPU per guest. `phil` runs fine at about 26 GB allocated. First draft for `vault` (32 GB of 48 GB): `storage-node` 6 GB (pinned by the passthrough), `runner-node` 6 GB, `agent-node` 6 GB, `agent-tools-node` 12 GB (raised from 10 GB for the Hindsight models), host 2 GB. Estimates, to be checked against real use.
- [x] **Garage data disk:** Garage moved from `storage-node` to `agent-tools-node` and gets the SATA SSD in `vault`, passed through whole (XFS, mounted by label `garage-data` at `/mnt/garage`). The 1 TB HDD stays with `storage-node` as scratch.
#### Implementation

- [x] **Migrate the `services-node` data disk:** Done on 2026-10-11. The 860 EVO is passed through whole with one ext4 partition at `/mnt/data`; `ZFS-Store` is destroyed. Staged on the SanDisk 512 GB SSD and verified by checksum in both directions; Paperless's sanity checker found no issues on all 508 documents. The filesystem UUID was kept, so `services-node/configuration.nix` is unchanged. See [proxmox-setup.md](docs/proxmox-setup.md#storage-configuration).
    - [x] The next ZeroByte run succeeded against the new disk.
    - [ ] Rollback copies: the SanDisk still holds one at `/mnt/staging` on `services-node`, and there is an archive on the MacBook (`~/homelab-backups/`). Remove both once the new disk has run for a while; the SanDisk then goes to `frigate-node`.
- [ ] **iGPU passthrough spike:** Validate Iris Xe → VM on `phil` (OVMF, `intel_gpu_top`, VAAPI/QSV test) before building on it. Fallback: CT with `/dev/dri`. UHD 770 → `storage-node` on `vault` is done, see [proxmox-setup.md](docs/proxmox-setup.md#igpu-passthrough).
- [x] **`vault` baseline:** `vault` is online with its Caddy route, OIDC login, metric server → VictoriaMetrics and ntfy webhook.
- [x] **Proxmox Datacenter Manager:** Running as a VM on `phil` at `proxmox.home.stefancyliax.de`, with both hosts as remotes.
- [x] **`vault` RAM:** Second 16 GB stick installed (32 → 48 GB).
- [x] **`storage-node` VM:** NixOS VM on `vault`, in the flake with Comin and Hawser, with the UHD 770 passed through.
- [ ] **`storage-node` disks and shares:** Pass the 6 TB and 2 TB HDDs (btrfs) and the 1 TB (XFS) through by-id, then set up the Samba/NFS shares. The 2 TB and 6 TB are done: btrfs `backup` at `/mnt/backup` and `data` at `/mnt/data`, each with a monthly scrub.
- [ ] **Data migration:** Inventory the existing data on the three HDDs and fix the shuffle order before any disk is reformatted.
    - [x] 2 TB (`sdc`, WD20EFRX): one XFS partition, empty apart from an empty `isos` folder (240 KB used). Free to reformat. SMART on 2026-10-18: PASSED, 22,827 power-on hours (~2.6 years), no reallocated, pending or uncorrectable sectors.
    - [x] 6 TB: the media still needed was copied to the 2 TB and verified, then the disk was wiped and formatted as one btrfs filesystem (`data`, `/mnt/data`). The media library stays on the 2 TB for now (`/mnt/backup/media`).
    - [ ] 1 TB (`sdb`, WD10EACS): holds an old encrypted backup. Check on another machine whether anything on it is still needed before reformatting. SMART on 2026-10-18: PASSED, 34,172 power-on hours (~3.9 years), no reallocated, pending or uncorrectable sectors. Healthy but old; fit for scratch, not for anything important.
- [ ] **NAS backups:** Local restic copy of the important shares on the 2 TB disk plus offsite via ZeroByte/restic; media stays unprotected by design.
- [ ] **Backups for services on `vault`:** ZeroByte runs on `services-node` on `phil` and only covers `/mnt/data` there, so the guests on `vault` are not backed up. Go through every guest (`agent-tools-node` with NocoDB, Open-WebUI, Hindsight and Garage; `storage-node`; `agent-node`; `hermes-node`; `runner-node`), decide which data is worth keeping, and set up a backup for it.
- [ ] **HAOS backups:** Point Home Assistant's built-in backups at a NAS share so they are covered without PBS.
- [x] **`agent-tools-node` / `agent-tools-stack`:** NixOS VM on `vault`; add to the flake with Comin and Hawser and a `dockhand-agent-tools.yml` workflow. Move Hindsight, Parakeet, Open-WebUI and NocoDB over from the `services-stack` including their volumes, then repoint their Caddy routes, Homepage entries and the Hindsight URLs the agents use.
- [x] **`work-tools-node` / `work-tools-stack`:** NixOS VM on `phil` with a second Hindsight instance for work, with its own Caddy routes and a `dockhand-work-tools.yml` workflow.
- [x] **Garage:** `services.garage` on `agent-tools-node` (single node, data on the passed-through SATA SSD, metadata on the VM disk, RPC secret via Agenix). Config is in `modules/garage.nix`.
- [x] **Artifact hosting:** One Garage bucket (`artifacts`) in website mode behind a single Caddy route (`artifacts.home.stefancyliax.de` → Garage web endpoint, no Authelia). Each artifact is a path in the bucket, so pushing a file publishes it without touching Caddy or DNS. The S3 API is exposed at `s3.home.stefancyliax.de` for uploads, with one write key per machine (`agent-node`, `desktop`); the `agent-node` key comes from Agenix as `~/.aws/credentials`. Uploads go through the `publish-s3` agent skill, which uploads and prints the URL.
- [ ] **Jellyfin:** Runs in the `storage-stack` on `storage-node` at `jellyfin.home.stefancyliax.de`, with the UHD 770 render node mapped in and `/mnt/backup/media` (on the 2 TB disk for now) as the library.
    - [x] First-run wizard.
    - [ ] Add `10.1.23.184` (Caddy) under Networking → Known proxies.
    - [ ] Enable Intel QuickSync under Playback → Transcoding and confirm a transcode shows up in `intel_gpu_top`.
    - [x] Authelia via the SSO plugin: OIDC client in `infra-stack/authelia/configuration.yml` and the provider in the plugin settings.
    - [ ] Libraries under `/media` in Jellyfin, which is `/mnt/backup/media` on the 2 TB disk.
    - [ ] Later: move the media library to the 6 TB; only the host path in the compose file changes.
- [x] **NextExplorer move:** NextExplorer runs in the `storage-stack` with a `dockhand-storage.yml` workflow, and its Caddy route points at `storage-node`. No data moved: it only gave access to `/mnt/data` on `services-node`.
- [x] **Remove dropped services:** Delete the commented-out Stirling PDF, Tududi and Paperless-AI blocks and their volumes from the `services-stack` compose files.
- [x] **Scanner service:** The HP ScanJet Pro 2600 f1 container runs in the `storage-stack` on `storage-node` on `vault`, where the scanner physically stands. The scanner is passed through by USB (see [proxmox-setup.md](docs/proxmox-setup.md#usb-passthrough)); the container gets the whole `/dev/bus/usb` tree and writes to the `paperless-consume` share of `services-node`, which `storage-node` automounts at `/mnt/paperless-consume`. See [scanner/README.md](storage-stack/scanner/README.md).
- [ ] **`frigate-node` / `frigate-stack`:** NixOS VM on `phil` with Iris Xe and the 512 GB SanDisk SSD passed through (SMART checked on 2026-10-09: no errors, about 3% wear; detach it from `services-node` first) and a NIC on the IoT VLAN; ballooning disabled; OpenVINO detector; 1–2 cameras with motion/event-based retention sized to the SSD; Home Assistant integration; ntfy `homelab-security`; Authelia forward_auth.
- [ ] **`agent-node` headless check:** Verify Obsidian Sync runs headless (official headless client) and how Antigravity is used without a desktop (remote SSH from the laptop or CLI).
- [ ] **`agent-node`:** Headless NixOS VM on `vault` with Hermes, Claude Code, Antigravity, herdr, the Obsidian vault (Obsidian Sync) and systemd timers for the maintenance flows.
- [ ] **Retire `hermes-node`:** After migrating to `agent-node`, remove the node from the flake, its Syncthing route in Caddy and its scrape targets.
- [ ] **`nuc`:** Bare-metal NixOS node for development (i3-8109U, 16 GB), scaffolded in the flake (`nodes/nuc/`) with Comin. Install NixOS, swap in the generated `hardware-configuration.nix`, add its host key to `secrets.nix` for the Comin PAT and bootstrap it. Runs on Ethernet only. See [deployment.md](docs/deployment.md#provisioning-the-nuc).
- [ ] **Observability & ingress for new guests:** Scrape targets, Homepage entries and Caddy routes for `vault` and every new node.

### Completed


- [x] **Centralized Logging:** Deployed Loki in infra-stack and Promtail (now Grafana Alloy) via NixOS common module for shipping journald and Docker logs from all nodes.
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
│   │   ├── nuc/                # Physical Intel NUC, development (bare metal)
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
    ├── dockhand-work-tools.yml
    ├── dockhand-frigate.yml
    ├── dockhand-agent-tools.yml
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