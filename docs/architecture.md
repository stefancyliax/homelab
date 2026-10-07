# Architecture Overview

This document describes the physical and virtual infrastructure of the homelab, including hardware, networking, and how services are distributed across nodes.

## Hardware

### Proxmox Host `phil`

| Component | Spec |
|---|---|
| CPU | Intel Core i5-1235U |
| iGPU | Iris Xe (80 EU) — 🔲 planned passthrough to `frigate-node` |
| RAM | 32 GB |
| Storage | Boot SSD (`local`, `local-lvm`) and a 500 GB Samsung 860 EVO (`ZFS-Store`). 🔲 Planned: a 250 GB Samsung SSD for Frigate. See [proxmox-setup.md](proxmox-setup.md#storage-configuration) |

Runs the control plane and the light application VMs. See [proxmox-setup.md](proxmox-setup.md) for the hypervisor configuration details.

### Proxmox Host `vault`

| Component | Spec |
|---|---|
| CPU | Intel Core i5-12600K |
| iGPU | UHD 770 (32 EU) — 🔲 planned passthrough to `storage-node` for Jellyfin |
| RAM | 32 GB — 🔲 planned: 48 GB (one more 16 GB stick) |
| Storage | NVMe SSD (Proxmox and VM disks), SATA SSD (unassigned for now); HDDs: 6 TB, 2 TB, 1 TB (9 TB total, carrying some existing data) |

The NAS box: a standalone Proxmox host that holds the HDDs and runs the storage, media and compute-heavy VMs. The NAS shares themselves are 🔲 planned as the [`storage-node`](#storage-node-nixos-vm) VM. Not clustered with `phil` — see [proxmox-setup.md](proxmox-setup.md#multi-host-management).

### GPU Worker (Physical Node)

| Component | Spec |
|---|---|
| CPU | Desktop-class (TBD) |
| GPU | Nvidia RTX 5060 Ti 16 GB |
| OS | NixOS (managed via Comin) |

A dedicated physical node for AI inference. Not always online — powers on when needed. See [gpu-worker.md](gpu-worker.md) for the full provisioning guide.

## Networking

| Concern | Solution |
|---|---|
| DHCP / DNS | Unifi networking system |
| IoT Isolation | Dedicated VLAN for IoT devices |
| Remote Access | Tailscale (MagicDNS for device name resolution) |
| Public Exposure | **None** — nothing is forwarded from the WAN router |
| SSL Certificates | Caddy with automatic ACME via Porkbun DNS challenge |

### DNS Configuration

All services are accessed via `*.home.stefancyliax.de` subdomains. DNS is configured at two levels:

| Level | Record | Target | Purpose |
|---|---|---|---|
| **Porkbun (Public DNS)** | `*.home.stefancyliax.de` → A record | `10.1.23.184` | Ensures all clients (LAN, Tailscale, any DNS resolver) resolve to the infra-node |
| **Unifi (Local DNS)** | `*.home.stefancyliax.de` → A record | `10.1.23.184` | Local override (optional, but provides faster resolution on LAN) |

> [!NOTE]
> The public A record points to a private RFC 1918 IP. This is intentional — the address is only reachable on the LAN or via Tailscale. External users get a valid DNS response but cannot connect.

### SSL / TLS

Caddy runs on the `infra-node` and automatically provisions wildcard TLS certificates for `*.home.stefancyliax.de` using the Porkbun DNS-01 ACME challenge. All service subdomains get trusted HTTPS without manual certificate management.

### Tailscale Configuration

The `infra-node` acts as a Tailscale Subnet Router, allowing remote devices to access internal subnets without opening WAN ports.

**Manual Setup Steps:**
1. **NixOS Configuration:** IP forwarding and `services.tailscale.enable = true` are defined declaratively in the `infra-node` flake.
2. **Apply Configuration:** Commit and push so Comin deploys the configuration onto the node.
3. **Advertise Routes:** SSH into the `infra-node` and run:
   ```bash
   sudo tailscale up --advertise-routes=10.1.23.0/24
   ```
4. **Approve in Dashboard:** Go to the Tailscale admin console, locate `infra-node`, select "Edit route settings", and toggle the subnet routes switch to "on".

Remote clients with Tailscale can then access all `*.home.stefancyliax.de` services — DNS resolves to `10.1.23.184` (via the public A record), and traffic reaches the infra-node through the Tailscale subnet route.

## Virtual Machine Landscape

Guests are spread over two standalone Proxmox hosts. Each VM is isolated to separate concerns.

| Guest | Host | Type | Status |
|---|---|---|---|
| `infra-node` | `phil` | NixOS VM | ✅ Running |
| `services-node` | `phil` | NixOS VM | ✅ Running |
| HAOS | `phil` | Appliance VM | ✅ Running |
| `hermes-node` | `phil` | NixOS VM | ✅ Running |
| `frigate-node` | `phil` | NixOS VM (Iris Xe + dedicated SSD passthrough) | 🔲 Planned |
| Proxmox Datacenter Manager | `phil` | Appliance VM | ✅ Running |
| `work-tools-node` | `phil` | NixOS VM | 🔲 Planned |
| `storage-node` | `vault` | NixOS VM (HDD + UHD 770 passthrough) | 🔲 Planned |
| `runner-node` | `vault` | NixOS VM | ✅ Running |
| `agent-node` | `vault` | NixOS VM | 🔲 Planned — supersedes `hermes-node` |
| `agent-tools-node` | `vault` | NixOS VM | 🔲 Planned |

### Workload Placement

**Which host:**

- **`phil`** — control plane and light apps: ingress, SSO, monitoring, Home Assistant, the `services-stack`. Also Frigate, because its iGPU is the stronger one for OpenVINO detection and it sits next to HAOS, and `work-tools-node`, which keeps the work tooling apart from the private one on `vault`.
- **`vault`** — anything that needs the HDDs, CPU for builds, or a device physically attached to it: NAS, Jellyfin, the scanner service, the GitHub runner, `agent-node`, and `agent-tools-node` with the services the agents rely on (Hindsight, Parakeet, Garage and others).

`phil` has 32 GB of RAM. `vault` has 32 GB and gets a second stick (🔲 48 GB); at least 16 GB of that stay unallocated, because `vault` is also the box for trying things out.

Each iGPU is passed through to exactly one VM, so Frigate (`phil`) and Jellyfin (`vault`) never compete for it.

**Which form:**

| Form | Use for | Examples |
|---|---|---|
| Docker Compose in a NixOS VM | Default for anything shipped as a container image. Deployed via Dockhand/Hawser. | Jellyfin, Frigate, BamBuddy, Hindsight, scanner service |
| Native NixOS service in a NixOS VM | Things tied to the OS, the disks or the hardware. | Samba, Garage, GitHub runner, llama-swap, Syncthing |
| Appliance VM | Software that ships its own OS. Not GitOps-managed, so kept to a minimum and documented manually. | HAOS, PDM |
| Proxmox CT | Not used. Only a fallback if iGPU passthrough to a VM fails. | — |

Docker is never run inside a CT.

### Node Details

#### Infrastructure Node (NixOS VM)

Hosts foundational services that must remain operational even if the application layer fails. It also acts as the **Tailscale Subnet Router** to provide secure remote access to the homelab.

| Service | Type | Status |
|---|---|---|
| [Dockhand](https://github.com/nicotsx/dockhand) | Native NixOS OCI container | ✅ Running |
| [Homepage](https://gethomepage.dev/) | Docker Compose (`infra-stack`) | ✅ Running |
| Tailscale Subnet Router | Native NixOS Service | ✅ Running |
| [ntfy](https://ntfy.sh/) | Docker Compose (`infra-stack`) | ✅ Running |
| VictoriaMetrics / Grafana / Loki | Docker Compose (`infra-stack`) | ✅ Running |

Dockhand is deployed natively via NixOS modules (`virtualisation.oci-containers`) to ensure it stays operational independently of Docker Compose. It orchestrates application deployments across the cluster by receiving webhooks from the CI pipeline.

#### Services Node (NixOS VM)

Hosts user-facing application workloads via Docker Compose, orchestrated by Dockhand through the [Hawser](https://github.com/nicotsx/hawser) agent. See [services.md](services.md) for the full list. Also hosts local Samba network shares (`paperless-consume` and `grimmory-bookdrop`) discoverable via WSDD.

🔲 Planned: the scanner service moves to [`storage-node`](#storage-node-nixos-vm) (NextExplorer already has). The AI-supporting services (Open-WebUI, NocoDB, Parakeet, Hindsight) already run on [`agent-tools-node`](#agent-tools-node-nixos-vm). Paperless, ZeroByte and Grimmory stay.

#### GitHub Runner (NixOS VM)

Executes GitHub Actions pipelines. Evaluates pull requests and commits with `NixOS/check-nodes.sh` and triggers Dockhand webhooks for application deployments. See [deployment.md](deployment.md#cicd-pipeline).

| Service | Type | Status |
|---|---|---|
| GitHub Actions Runner (`github-runner-homelab.service`) | Native NixOS Service | ✅ Running |

The runner lives on `runner-node` on `vault`, declared in the flake (`services.github-runners` in `modules/github-runner.nix`) and managed by Comin like every other NixOS VM. It is a VM rather than a CT because it executes workflow code. `nixos-check.yml` triggers on `pull_request`; the repo requires approval for all outside contributors, so fork PRs cannot run on it unreviewed.

#### Storage Node (NixOS VM)

**Status:** 🔲 Planned, on `vault`.

Managed NixOS rather than Unraid: with a 6 TB + 2 TB + 1 TB set, any parity scheme (Unraid or SnapRAID) needs the 6 TB disk as parity and leaves only 3 TB usable, so Unraid's mixed-size array brings no benefit here.

| Service | Type |
|---|---|
| Samba / NFS shares | Native NixOS service |
| [Jellyfin](https://jellyfin.org/) | Docker Compose (`storage-stack`), QuickSync via the passed-through UHD 770 |
| [NextExplorer](https://github.com/nxzai/explorer) | Docker Compose (`storage-stack`), ✅ moved. Serves `/mnt/data`, which sits on the VM disk until the HDDs are passed through |
| [BamBuddy](https://bambuddy.cool/index.html) | Docker Compose (`storage-stack`) |
| Scanner service (HP ScanJet Pro 2600 f1) | Docker Compose. The scanner stands next to `vault` and is passed through by USB; scans are written to the `paperless-consume` share on `services-node`. Currently runs on `services-node` |

Disk roles (no parity; important shares are backed up instead, media is re-acquirable). The 6 TB and 2 TB disks are passed through by-id to `storage-node`. The 1 TB disk was meant for Garage, which now lives on `agent-tools-node`; where its data goes is still open:

| Disk | Role | Filesystem |
|---|---|---|
| 6 TB | Bulk storage: media and general shares | btrfs |
| 1 TB | Scratch. Garage data only if the disk follows Garage to `agent-tools-node` (open) | XFS |
| 2 TB | Local backup copy of the important shares | btrfs |

btrfs is used where there is no second copy on the same disk set: its checksums reveal which file went bad so it can be restored. XFS is what Garage recommends for its data directory, since Garage checksums its own data.

Storage and Jellyfin share one VM because Jellyfin needs both the disks and the iGPU — this avoids NFS/virtiofs hops between VMs.

#### Agent Tools Node (`agent-tools-node`, NixOS VM)

**Status:** 🔲 Planned, on `vault`.

The services the AI agents and workflows rely on, kept apart from the general apps on `services-node` and from the agents themselves on `agent-node`.

| Service | Type |
|---|---|
| [Hindsight](https://github.com/vectorize-io/hindsight) | Docker Compose (`agent-tools-stack`), ✅ moved |
| [Parakeet](https://github.com/achetronic/parakeet) | Docker Compose (`agent-tools-stack`), ✅ moved. API at `10.1.23.12:8000` |
| [Open-WebUI](https://github.com/open-webui/open-webui) | Docker Compose (`agent-tools-stack`), ✅ moved |
| [NocoDB](https://nocodb.com/) | Docker Compose (`agent-tools-stack`), ✅ moved |
| [Garage](https://garagehq.deuxfleurs.fr/) S3 (~100 GB, dev use) | Native NixOS service (`services.garage`). Data location is open: the 1 TB HDD passed through to this VM, or the VM disk on the NVMe |
| Artifact hosting (Claude/Gemini HTML artifacts) | One Garage website bucket behind one Caddy route on `infra-node`; each artifact is a path, published by an S3 upload. No authentication |
| pilot | To be defined |

#### Work Tools Node (`work-tools-node`, NixOS VM)

**Status:** 🔲 Planned, on `phil`.

Tooling for work, on its own VM and its own host so that it shares neither data nor a memory store with the private setup on `vault`.

| Service | Type |
|---|---|
| [Hindsight](https://github.com/vectorize-io/hindsight) (work instance) | Docker Compose (`work-tools-stack`). UI at `hindsight-work.home.stefancyliax.de` (Authelia), API at `hindsight-work-api.home.stefancyliax.de`. Uses a hosted LLM provider (still to be chosen), configured through the Dockhand stack environment; agents reach the API directly at `10.1.23.47:8888` |

#### Frigate Node (NixOS VM)

**Status:** 🔲 Planned, on `phil`.

Runs [Frigate](https://frigate.video/) as its own Docker Compose stack (`frigate-stack`) via Hawser.

- **iGPU:** Iris Xe passed through for hardware decoding and OpenVINO detection.
- **Storage:** dedicated 250 GB Samsung SSD passed through for recordings and the database, so NVR writes don't touch the other VMs' disks.
- **Network:** second NIC on the IoT VLAN to reach the cameras, like HAOS.
- **Scope:** 1–2 cameras. Retention is motion/event-based with only a short continuous window, since every 1 Mbit/s of camera bitrate recorded around the clock costs about 11 GB per day.

**Why a dedicated VM instead of `services-node`:** that VM is SeaBIOS, GPU passthrough is better trodden on OVMF, and passthrough problems stay isolated from the other apps.

**Why a VM instead of a CT:** a CT would share the iGPU with the host instead of taking it whole, but nothing else on `phil` needs it. Frigate ships as a Docker image, its docs recommend a VM on Proxmox and do not officially support LXC, and a VM keeps it in the NixOS/Hawser GitOps flow. A CT with `/dev/dri` remains the fallback if passthrough fails. Memory ballooning must be disabled on the VM.

#### Agent Node (NixOS VM)

**Status:** 🔲 Planned, on `vault`.

Home of the AI agents and the knowledge base; supersedes `hermes-node`. Headless: reached over SSH/Mosh, with herdr as the workspace for the agents.

| Component | Notes |
|---|---|
| Hermes, Claude Code, Antigravity | Coding/knowledge agents |
| herdr | Terminal workspace for running the agents |
| Obsidian vault | Kept current via Obsidian Sync with a headless client (replaces the Syncthing copy on `hermes-node`) |
| Automatic maintenance flows | Scheduled agent runs, declared as systemd timers |

Antigravity and Obsidian Sync are GUI-first; their headless use is not yet verified.

#### Proxmox Datacenter Manager (VM)

**Status:** ✅ Running, VM on `phil`, reachable at `https://proxmox.home.stefancyliax.de`.

Single pane of glass over `phil` and `vault` without clustering them. See [proxmox-setup.md](proxmox-setup.md#multi-host-management).

#### HAOS (VM)

Dedicated Home Assistant Operating System instance for smart home control. Attached to the IoT VLAN. See [home-assistant.md](home-assistant.md).

#### Hermes Node (NixOS VM)

> [!NOTE]
> To be superseded by the [Agent Node](#agent-node-nixos-vm) on `vault`.

A lightweight VM providing persistent remote access to the Hermes AI coding agent.
Accessible via SSH/Mosh from any device (laptop, phone). Uses tmux for session
persistence. Hermes connects to the GPU-Worker's llama-swap API for LLM inference.
It also hosts a synced copy of your Obsidian vault via Syncthing for the agent to access.

| Service | Type | Status |
|---|---|---|
| Hermes Agent | CLI tool (user-installed) | ✅ Running |
| Dev Tools (Python, Node, etc.) | NixOS packages | ✅ Running |
| nix-ld (for dynamic binaries) | NixOS module | ✅ Enabled |
| [Syncthing](https://syncthing-hermes-node.home.stefancyliax.de) | Native NixOS Service | ✅ Deployed |
| Mosh + tmux | NixOS modules | ✅ Running |
| Port 9119 | NixOS firewall config | ✅ Open |
| Port 8384 (Tailscale only) | NixOS firewall config | ✅ Open |

#### Auxiliary / Test Node (`another-node`, NixOS VM)

A lightweight auxiliary NixOS VM used for testing new modules, packages, and staging GitOps configurations before rolling them out across production nodes. Managed by Comin and monitored by Prometheus. Only started when needed for testing.

#### ~~Ollama Node (NixOS VM)~~ — Deprecated

> [!WARNING]
> The Ollama Node has been deprecated. It proved too slow for practical LLM inference. All OCR and tagging tasks have been migrated to the GPU Worker's llama-swap backend.

[Open-WebUI](https://github.com/open-webui/open-webui) runs on `agent-tools-node` (via Docker Compose) and connects to the GPU Worker's llama-swap API.

#### GPU Worker AI Backend

The GPU Worker runs [llama-swap](https://github.com/mostlygeek/llama-swap) as a native NixOS service with CUDA-accelerated `llama-cpp`. It provides an OpenAI-compatible API on port 8080 and manages model hot-swapping on demand. See [gpu-worker.md](gpu-worker.md) for the full configuration.

| Service | Type | Status |
|---|---|---|
| [llama-swap](https://github.com/mostlygeek/llama-swap) | Native NixOS service | ✅ Functional |

## Deployment Strategy

The environment follows a strict **GitOps** philosophy where this repository is the single source of truth:

- **OS Level:** All NixOS configurations are pulled declaratively by nodes running the Comin GitOps agent on boot and periodically from the `main` branch.
- **Application Level:** Docker Compose files are deployed via Dockhand/Hawser, triggered by GitHub Actions webhooks.

See [deployment.md](deployment.md) for the full workflow.
