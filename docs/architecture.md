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

A dedicated physical workstation for AI inference and daily use. Not always online — powers on when needed. See [gpu-worker.md](gpu-worker.md) for the full provisioning guide.

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
| SSL Certificates | TBD — researching Tailscale's built-in SSL capabilities |

## Virtual Machine Landscape

All VMs run on the single Proxmox host. Each VM is isolated to separate concerns.

### Node Details

#### Infrastructure Node (NixOS VM)

Hosts foundational services that must remain operational even if the application layer fails.

| Service | Type | Status |
|---|---|---|
| [Dockhand](https://github.com/nicotsx/dockhand) | Native NixOS OCI container | ✅ Running |
| [ZeroByte](https://github.com/nicotsx/zerobyte) | Docker Compose (`infra-stack`) | 🚧 Deployed, not configured |
| [Homepage](https://gethomepage.dev/) | Docker Compose (`infra-stack`) | ✅ Running |
| Prometheus / Grafana / InfluxDB | Docker Compose (`infra-stack`) | 🔲 Planned |

Dockhand is deployed natively via NixOS modules (`virtualisation.oci-containers`) to ensure it stays operational independently of Docker Compose. It orchestrates application deployments across the cluster by receiving webhooks from the CI pipeline.

#### Services Node (NixOS VM)

Hosts user-facing application workloads via Docker Compose, orchestrated by Dockhand through the [Hawser](https://github.com/nicotsx/hawser) agent. See [services.md](services.md) for the full list.

#### GitHub Runner (NixOS VM)

Executes GitHub Actions pipelines. When code is pushed to `main`, it triggers `colmena apply` for OS deployments and Dockhand webhooks for application deployments. See [deployment.md](deployment.md).

#### HAOS (VM)

Dedicated Home Assistant Operating System instance for smart home control. Attached to the IoT VLAN. See [home-assistant.md](home-assistant.md).

#### Tailscale Subnet Router (VM)

Provides network access between Tailscale and internal subnets. May eventually be merged into the Infrastructure Node.

## Deployment Strategy

The environment follows a strict **GitOps** philosophy where this repository is the single source of truth:

- **OS Level:** NixOS configurations are pushed to always-online nodes via Colmena. Intermittent nodes (like `gpu-worker`) use Comin to pull their state from Git on boot.
- **Application Level:** Docker Compose files are deployed via Dockhand/Hawser, triggered by GitHub Actions webhooks.

See [deployment.md](deployment.md) for the full workflow.
