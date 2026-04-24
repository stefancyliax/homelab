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
| [Jellyfin](https://jellyfin.org/) | NAS | 🔲 Planned |
| [Frigate](https://frigate.video/) | Docker Compose (`services-stack`) | 🔲 Planned |
| [n8n](https://n8n.io/) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [NocoDB](https://nocodb.com/) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [Grimmory](https://github.com/grimmory-tools/grimmory) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [Open-WebUI](https://github.com/open-webui/open-webui) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [ESPHome](https://esphome.io/) | Docker Compose (`services-stack`) | 🔲 Planned |
| [Tududi](https://github.com/chrisvel/tududi) | Docker Compose (`services-stack`) | 🔲 Planned |
| Cloud Storage (Nextcloud or Seafile) | Docker Compose (`services-stack`) | 🔲 Planned |
| [Paperless-AI](https://github.com/clusterzx/paperless-ai) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [Paperless-GPT](https://github.com/icereed/paperless-gpt) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [NextExplorer](https://github.com/nxzai/explorer) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [Ollama](https://ollama.com/) | Dedicated NixOS VM (`ollama-node`) | 🚧 Deployed |
| [llama-swap](https://github.com/mostlygeek/llama-swap) | Native NixOS service (`gpu-worker`) | 🚧 Config defined |
| [Speaches](https://github.com/speaches-ai/speaches) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [Kestra](https://kestra.io/) | Docker Compose (`services-stack`) | 🚧 Deployed |

### Paperless AI Integrations

> [!NOTE]
> There are currently two local AI document processors running alongside Paperless-ngx: **Paperless-GPT** and **Paperless-AI**.
> 
> **Paperless-GPT** acts as the primary tool for document parsing, tagging, and metadata extraction. **Paperless-AI** will remain active in the stack as a fallback and will be used if the tagging capabilities of the `-gpt` variant do not work sufficiently.

See [home-assistant.md](home-assistant.md) for the full Home Assistant ecosystem details.

> [!NOTE]
> This list will grow as new services are added to the homelab. Each service gets its Docker Compose definition in `services-stack/docker-compose.yml` and is deployed automatically via the GitOps pipeline.
