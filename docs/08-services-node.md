# 08 - Services Node

This document tracks the main user-facing container applications deployed natively within the homelab.

## 🏢 Purpose
The Services Node runs on its own dedicated similarly-named NixOS VM. It securely houses the primary workloads utilized day-to-day. All services here are declarative and strictly managed by Dockhand (via the node's local `Hawser` proxy agent) applying robust pull configurations fetched out of the central repository.

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
