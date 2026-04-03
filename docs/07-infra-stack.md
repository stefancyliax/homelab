# 07 - Infrastructure Stack

This document details the configuration and services running on the dedicated Infrastructure Stack NixOS VM.

## 🏢 Purpose
The Infrastructure Stack is isolated from the main application layer to ensure that foundational services—like deployment controllers, network bridges, or core network databases—remain stable and completely independent of user-facing application failures.

## 🛠️ Deployed Services
Currently, this stack is deployed via Docker Compose files located centrally in the `infra-stack/` directory.

### Komodo
* **Role:** Operations and deployment orchestrator.
* **Function:** Runs in "Pull" mode. It actively observes this GitHub repository and triggers Docker Compose updates inherently when changes are pushed to `main`.

### Monitoring (Uptime Kuma)
* **Role:** Uptime and service health tracking.
* **Function:** It must reside in the Infra Stack so that if the `Services-Stack` VM fully crashes, Kuma remains online to send you the failure alert. 

### Dashboards (Homepage / Glance)
* **Role:** Central point of access for all homelab services.
* **Function:** Housed here so you can always reach the portal interface even if half of the backend applications are down. 

## 🚀 Deployment Checklist
- [ ] Finalize the base `infra-stack/docker-compose.yml` file.
- [ ] Deploy Komodo and correctly map the Docker socket so it can manage its own host.
- [ ] Deploy Uptime Kuma and Dashboard.
- [ ] Connect Komodo to the GitHub repository webhook or polling mechanism.
