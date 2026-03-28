# Homelab Infrastructure as Code (IaC) Setup

This documentation tracks the progress of setting up a homelab managed by GitHub Actions.

## Goals
- [x] Set up a GitHub Actions self-hosted runner on Proxmox.
- [ ] Manage Proxmox infrastructure via Terraform/OpenTofu.
- [ ] Automate deployments via GitHub Actions.

## Current Setup
- **Proxmox Host:** 10.1.23.4
- **Repository:** Managed on GitHub

---

## Steps Taken

### 1. GitHub Actions Self-Hosted Runner
The GitHub Actions runner executes the IaC code against the local infrastructure.

- **Location:** Proxmox LXC (Ubuntu 24.04).
- **Resources:** 6 vCPU, 4GB RAM, 10GB+ Disk.
- **Status:** Completed

#### Implementation Details:
1.  **LXC Container Creation:** Created via Proxmox Web UI using `ubuntu-25.04-standard` template.
2.  **Base Dependencies:** Installed `curl`, `unzip`, and `nodejs` (v20+) on the runner.
3.  **Runner Registration:**
    *   Created a dedicated `runner` user on the LXC.
    *   Registered with labels: `self-hosted`, `infra`.
    *   Installed as a system service using `./svc.sh install` and started it with `./svc.sh start`.
4.  **Verification:** 
    *   Created `.github/workflows/test-runner.yml`.
    *   Successfully confirmed connectivity between GitHub and the Proxmox internal network.

### 2. Infrastructure as Code (IaC) Setup
Managing Proxmox resources via code using Terraform.

- **Status:** In Progress (Planning phase)

#### Implementation Details:
1.  **Proxmox API Token:**
    *   User: `terraform` (Proxmox VE authentication realm).
    *   Token ID: `terraform-prov`.
    *   Full Token ID: `terraform@pve!terraform-prov`.
    *   **Crucial Step:** Go to **Datacenter** -> **Permissions** -> **Add** -> **API Token Permission**.
    *   Set **Path:** `/`, **Token:** `terraform@pve!terraform-prov`, **Role:** `Administrator`.
2.  **GitHub Secrets:** Stored these secrets in the repository settings.
    *   `PROXMOX_URL`
    *   `PROXMOX_API_TOKEN_ID`
    *   `PROXMOX_API_TOKEN_SECRET`
3.  **Terraform Configuration:**
    *   `terraform/provider.tf`: Configured the `telmate/proxmox` provider.
4.  **Automation Workflows:**
    *   `.github/workflows/terraform-plan.yml`: Preview changes on every push/PR.
    *   `.github/workflows/terraform-apply.yml`: Automatically deploy changes when merging to `main`.
5.  **First Managed Resource:**
    *   **File:** `terraform/main.tf`.
    *   **Resource:** `test-nixos-vm` (Cloned from Template 119).
    *   **Node:** `phil`.
    *   **Configuration:** `2 vCPU`, `4GB RAM`, `vm_state = "running"`, `agent = 0`.
    *   **Status:** Defined and ready for first apply.

---

## Development Workflow (IaC)

To make changes to your infrastructure, follow these steps:

1.  **Create a Feature Branch:** `git checkout -b my-new-change`
2.  **Make Changes:** Edit `.tf` files or workflows.
3.  **Push and Open PR:** `git push origin my-new-change` and open a Pull Request to `main`.
4.  **Verify the Plan:** Check the GitHub Actions tab on the PR to ensure the `Terraform Plan` output is what you expect.
5.  **Merge to Main:** Once reviewed, merge the PR. This will trigger the `Terraform Apply` workflow, which deploys the changes to your Proxmox host.
