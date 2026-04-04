# 01 - Architecture Overview

This document outlines the high-level architecture of the homelab, including hardware specifications, network topology, and the virtual machine landscape.

## 🖥️ Hardware Specifications

### Main Proxmox Node
* **CPU:** Intel Core i5-1235U
* **RAM:** 32GB
* **Storage:** 3x 512GB SSDs (each designated for a different purpose, no ZFS)

### GPU-Worker Node (Physical)
* **Purpose:** Dedicated workstation for AI workloads (not always online).
* **OS:** NixOS (managed)
* **GPU:** Nvidia RTX 5060 Ti 16GB

### Backup NAS / Storage Node
* **Current Hardware:** Intel NUC i3, 16GB RAM, 256GB SSD.
* **Future Hardware:** Dedicated NAS / MiniPC.
* **OS:** TBD (Considering ZimaOS or Unraid or managed NixOS).

## 🌍 Networking

* **DHCP / DNS Names:** Handled by a Unifi networking system.
* **VLANs:** Dedicated VLAN for IoT devices. (Handling of services routing across this VLAN is TBD).
* **Remote Access:** Tailscale is used for secure remote access and DNS (MagicDNS). 
* **Public Exposure:** Nothing is exposed to the public internet.
* **SSL Certificates:** TBD. Planning to research Tailscale's built-in SSL capabilities.

## 🏗️ Virtual Machine Landscape

The main Proxmox node runs multiple isolated Virtual Machines to separate concerns:

1. **GitHub Runner (NixOS VM):** Responsible for executing GitHub Actions pipelines (specifically `colmena` deploy steps) in a secure, isolated manner.
2. **Infrastructure Node (NixOS VM):** Runs core infrastructure toolsets (like Dockhand and ZeroByte).
3. **Services Node (NixOS VM):** Runs the main application workloads via Docker Compose (Paperless, NocoDB, Nextcloud, etc.).
4. **HAOS (VM):** A dedicated Home Assistant Operating System instance for smart home control.
5. **Tailscale Subnet Router (VM):** Provides network access between Tailscale and internal subnets. (May eventually be merged into the Infrastructure Node).

## 🔄 Deployment Strategy

The environment follows a strict **GitOps** philosophy:
* **OS Level:** NixOS configurations are written in this repository and pushed to standard nodes natively via `Colmena`. Intermittent nodes (like `gpu-worker`) utilize `comin` to actively natively "pull" state changes safely upon boot.
* **Application Level:** Docker Compose files are maintained in this repository. A local GitHub Actions runner natively triggers physical webhooks to Dockhand, initiating Docker deployment pulls onto the `Infrastructure` and `Services` VMs via the `Hawser` agent endpoint.
