# 08 - Services Stack

This document tracks the main user-facing applications deployed within the homelab.

## 🏢 Purpose
The Services Stack runs on its own dedicated NixOS VM. It houses the primary applications used day-to-day. All services here are declarative and managed by Komodo pulling configurations straight from the repository.

## 📱 Planned Services
The following services are mapped out for deployment:

* **Document Management:** Paperless-ngx (paired with Paperless-ai / Paperless-gpt)
* **Automation:** n8n
* **Utilities:** Stirling PDF, Grimoire, NocoDB
* **Cloud Storage:** Nextcloud or Seafile (Awaiting research)

## 🚀 Deployment Checklist
> [!NOTE]
> Review the Master To-Do list regarding "Volume Layout Design" before mapping persistent volumes for these services.

- [ ] Write the structured `services-stack/docker-compose.yml` defining the application containers.
- [ ] Configure networking so services are cleanly reachable internally via Tailscale MagicDNS.
- [ ] Set up the Paperless ecosystem.
