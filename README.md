# Homelab Architecture & GitOps Workflow

This repository contains the Infrastructure as Code (IaC) and application deployments for a Proxmox-based homelab. 

## 🏗️ Core Architecture

The homelab utilizes a GitOps approach, separating the base operating system configuration from the application deployment layer.

* **Hypervisor:** Proxmox VE
* **Source of Truth:** GitHub (This repository)
* **OS Configuration Management:** NixOS & Colmena (Push Model)
* **Application Deployment:** Docker Compose & Komodo (Pull Model)

## 🖥️ Node Provisioning

The infrastructure is split to ensure lightweight operation and proper separation of concerns:

### 1. GitHub Runner (LXC)
* **Purpose:** Executes GitHub Actions pipelines.
* **Role:** Runs `colmena apply` to evaluate NixOS configurations and push them to target machines via SSH.
* **Why LXC:** Extremely low resource overhead since it only needs to run the Colmena binary and an SSH client.

### 2. Primary Docker Host (NixOS VM)
* **Resources:** 2GB RAM
* **Purpose:** Hosts the Docker engine and the Komodo deployment service.
* **Role:** Acts as the central application server. Komodo monitors this GitHub repository for changes to `docker-compose.yml` files and pulls those updates directly to deploy or update containers (e.g., Home Assistant, Paperless-ngx).
* **Why VM:** Avoids the file system and permission quirks of running nested Docker containers inside an LXC, while remaining resource-efficient by running NixOS headless.

## 🔄 Deployment Workflows

* **Infrastructure/OS Changes:** Push `.nix` updates to GitHub ➡️ LXC Runner triggers ➡️ Colmena builds and pushes state to the VM via SSH.
* **Application Changes:** Push `docker-compose.yml` updates to GitHub ➡️ Komodo detects changes ➡️ Komodo pulls configurations and updates Docker stacks on the VM.