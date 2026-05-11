# Architecture Overview

This document describes the physical and virtual infrastructure of the homelab, including hardware, networking, and how services are distributed across nodes.

## Hardware

### Proxmox Host

| Component | Spec |
|---|---|
| CPU | Intel Core i5-1235U |
| RAM | 32 GB |
| Storage | 3× 512 GB SSD (no ZFS, independent roles) |

The Proxmox host runs all core virtual machines. See [proxmox-setup.md](proxmox-setup.md) for the hypervisor configuration details.

### GPU Worker (Physical Node)

| Component | Spec |
|---|---|
| CPU | Desktop-class (TBD) |
| GPU | Nvidia RTX 5060 Ti 16 GB |
| OS | NixOS (managed via Comin) |

A dedicated physical node for AI inference. Not always online — powers on when needed. See [gpu-worker.md](gpu-worker.md) for the full provisioning guide.

### NAS / Storage Node

| Component | Spec |
|---|---|
| Current Hardware | Intel NUC i3, 16 GB RAM, 256 GB SSD |
| Future Hardware | Dedicated NAS or MiniPC |
| OS | TBD (ZimaOS, Unraid, or managed NixOS) |

Will serve as local backup target and media storage.

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

All VMs run on the single Proxmox host. Each VM is isolated to separate concerns.

### Node Details

#### Infrastructure Node (NixOS VM)

Hosts foundational services that must remain operational even if the application layer fails. It also acts as the **Tailscale Subnet Router** to provide secure remote access to the homelab.

| Service | Type | Status |
|---|---|---|
| [Dockhand](https://github.com/nicotsx/dockhand) | Native NixOS OCI container | ✅ Running |
| [Homepage](https://gethomepage.dev/) | Docker Compose (`infra-stack`) | ✅ Running |
| Tailscale Subnet Router | Native NixOS Service | ✅ Running |
| [ntfy](https://ntfy.sh/) | Docker Compose (`infra-stack`) | 🚧 Deployed |
| Prometheus / Grafana / InfluxDB | Docker Compose (`infra-stack`) | 🔲 Planned |

Dockhand is deployed natively via NixOS modules (`virtualisation.oci-containers`) to ensure it stays operational independently of Docker Compose. It orchestrates application deployments across the cluster by receiving webhooks from the CI pipeline.

#### Services Node (NixOS VM)

Hosts user-facing application workloads via Docker Compose, orchestrated by Dockhand through the [Hawser](https://github.com/nicotsx/hawser) agent. See [services.md](services.md) for the full list.

#### GitHub Runner (NixOS VM)

Executes GitHub Actions pipelines. When code is pushed to `main`, it triggers `colmena apply` for OS deployments and Dockhand webhooks for application deployments. See [deployment.md](deployment.md).

#### HAOS (VM)

Dedicated Home Assistant Operating System instance for smart home control. Attached to the IoT VLAN. See [home-assistant.md](home-assistant.md).

#### ~~Ollama Node (NixOS VM)~~ — Deprecated

> [!WARNING]
> The Ollama Node has been deprecated. It proved too slow for practical LLM inference. All OCR and tagging tasks have been migrated to the GPU Worker's llama-swap backend.

[Open-WebUI](https://github.com/open-webui/open-webui) runs on the Services Node (via Docker Compose) and now connects to the GPU Worker's llama-swap API.

#### GPU Worker AI Backend

The GPU Worker runs [llama-swap](https://github.com/mostlygeek/llama-swap) as a native NixOS service with CUDA-accelerated `llama-cpp`. It provides an OpenAI-compatible API on port 8080 and manages model hot-swapping on demand. See [gpu-worker.md](gpu-worker.md) for the full configuration.

| Service | Type | Status |
|---|---|---|
| [llama-swap](https://github.com/mostlygeek/llama-swap) | Native NixOS service | ✅ Functional |

## Deployment Strategy

The environment follows a strict **GitOps** philosophy where this repository is the single source of truth:

- **OS Level:** NixOS configurations are pushed to always-online nodes via Colmena. Intermittent nodes (like `gpu-worker`) use Comin to pull their state from Git on boot.
- **Application Level:** Docker Compose files are deployed via Dockhand/Hawser, triggered by GitHub Actions webhooks.

See [deployment.md](deployment.md) for the full workflow.
