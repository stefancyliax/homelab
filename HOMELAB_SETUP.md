# Homelab Infrastructure as Code (IaC) Setup

This documentation tracks the progress of setting up a homelab managed by GitHub Actions.

## Goals
- [x] Set up a GitHub Actions self-hosted runner on Proxmox.
- [ ] Manage Proxmox infrastructure via Terraform/OpenTofu.
- [ ] Automate deployments via GitHub Actions.

## Current Setup
- **Proxmox Host:** 10.1.23.4
- **Repository:** Managed on GitHub

## Steps

### 1. GitHub Actions Self-Hosted Runner
The GitHub Actions runner will execute the IaC code against the local infrastructure.
- **Location:** Proxmox LXC (Ubuntu 24.04).
- **Status:** Completed

#### Steps taken:
1. **Create LXC Container in Proxmox Web UI:**
   - **Template:** `ubuntu-24.04-standard`.
   - **Hostname:** `gh-runner`.
   - **Resources:** 6 vCPU, 4GB RAM, 10GB+ Disk.
   - **Networking:** Static IP or DHCP (Bridge `vmbr0`).
2. **Start & Login:** Booted the container and logged in via the Proxmox Console.
3. **Register GitHub Runner:**
   - **User:** Created a dedicated `runner` user.
   - **Configuration:** Followed GitHub Actions "New self-hosted runner" instructions.
   - **Labels:** Added `homelab` label.
5. **Verification:**
   - **Action:** Created `.github/workflows/test-runner.yml` to test the connection.
   - **Labels used:** `self-hosted`, `homelab`.
   - **Result:** Successfully executed commands within the Proxmox LXC container.
