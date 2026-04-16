# Services

This document describes the user-facing services and applications that the homelab provides. Services are deployed as Docker containers via the `services-stack/` Docker Compose files, orchestrated by Dockhand/Hawser (see [deployment.md](deployment.md)).

Some services run on dedicated VMs or specialized hardware — these are noted below.

## Services

| Service | Type | Status |
|---|---|---|
| [Home Assistant](https://www.home-assistant.io/) | Dedicated HAOS VM | ✅ Running |
| [ZeroByte](https://github.com/nicotsx/zerobyte) | Docker Compose (`services-stack`) | 🚧 Deployed, not configured |
| [Paperless-ngx](https://docs.paperless-ngx.com/) | Docker Compose (`services-stack`) | 🚧 Needs Testing |
| [IT-Tools](https://github.com/CorentinTh/it-tools) | Docker Compose (`services-stack`) | 🔲 Planned |
| [Jellyfin](https://jellyfin.org/) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [Frigate](https://frigate.video/) | Docker Compose (`services-stack`) | 🔲 Planned |
| [n8n](https://n8n.io/) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [NocoDB](https://nocodb.com/) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF) | Docker Compose (`services-stack`) | 🔲 Planned |
| [Grimoire](https://github.com/goniszewski/grimoire) | Docker Compose (`services-stack`) | 🔲 Planned |
| [Open-WebUI](https://github.com/open-webui/open-webui) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [ESPHome](https://esphome.io/) | Docker Compose (`services-stack`) | 🔲 Planned |
| [Tududi](https://github.com/chrisvel/tududi) | Docker Compose (`services-stack`) | 🔲 Planned |
| Cloud Storage (Nextcloud or Seafile) | Docker Compose (`services-stack`) | 🔲 Planned |

See [home-assistant.md](home-assistant.md) for the full Home Assistant ecosystem details.

> [!NOTE]
> This list will grow as new services are added to the homelab. Each service gets its Docker Compose definition in `services-stack/docker-compose.yml` and is deployed automatically via the GitOps pipeline.
