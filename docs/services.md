# Services

This document describes the user-facing services and applications that the homelab provides. Services are deployed as Docker containers via the `services-stack/` Docker Compose files, orchestrated by Dockhand/Hawser (see [deployment.md](deployment.md)).

Some services run on dedicated VMs or specialized hardware — these are noted below.

## Services

| Service | Type | Status |
|---|---|---|
| [Home Assistant](https://www.home-assistant.io/) | Dedicated HAOS VM | ✅ Running |
| [ntfy](https://ntfy.sh/) | Docker Compose (`infra-stack`) | ✅ Functional |
| [ZeroByte](https://github.com/nicotsx/zerobyte) | Docker Compose (`services-stack`) | ✅ Functional |
| [Paperless-ngx](https://docs.paperless-ngx.com/) | Docker Compose (`services-stack`) | ✅ Functional |
| Samba & WSDD | Native NixOS service (`services-node`) | ✅ Functional |
| [IT-Tools](https://github.com/CorentinTh/it-tools) | Docker Compose (`services-stack`) | 🔲 Planned |
| [Jellyfin](https://jellyfin.org/) | NAS | 🔲 Planned |
| [Frigate](https://frigate.video/) | Docker Compose (`services-stack`) | 🔲 Planned |
| ~~[n8n](https://n8n.io/)~~ | Docker Compose (`services-stack`) | ❌ Removed |
| [NocoDB](https://nocodb.com/) | Docker Compose (`services-stack`) | 🚧 Deployed |
| ~~[Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF)~~ | Docker Compose (`services-stack`) | ⏸️ Commented out |
| [Grimmory](https://github.com/grimmory-tools/grimmory) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [Open-WebUI](https://github.com/open-webui/open-webui) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [ESPHome](https://esphome.io/) | Docker Compose (`services-stack`) | 🔲 Planned |
| ~~[Tududi](https://github.com/chrisvel/tududi)~~ | Docker Compose (`services-stack`) | ⏸️ Commented out |
| [BamBuddy](https://bambuddy.cool/index.html) | Docker Compose (`services-stack`) | 🔲 Planned |
| ~~[Paperless-AI](https://github.com/clusterzx/paperless-ai)~~ | Docker Compose (`services-stack`) | ⏸️ Commented out |
| [Paperless-GPT](https://github.com/icereed/paperless-gpt) | Docker Compose (`services-stack`) | ✅ Functional |
| [NextExplorer](https://github.com/nxzai/explorer) | Docker Compose (`services-stack`) | 🚧 Deployed |
| ~~[Ollama](https://ollama.com/)~~ | ~~Dedicated NixOS VM (`ollama-node`)~~ | ❌ Deprecated |
| [llama-swap](https://github.com/mostlygeek/llama-swap) | Native NixOS service (`gpu-worker`) | ✅ Functional |
| [Parakeet](https://github.com/achetronic/parakeet) | Docker Compose (`services-stack`) | 🚧 Deployed |
| ~~[Kestra](https://kestra.io/)~~ | Docker Compose (`services-stack`) | ❌ Removed |
| [Hindsight](https://github.com/vectorize-io/hindsight) | Docker Compose (`services-stack`) | 🚧 Deployed |
| Hermes Chat | Native service (`hermes-node`) | 🚧 Deployed |
| [nvtop](https://github.com/Syllo/nvtop) | Native NixOS package (`gpu-worker`) | ✅ Deployed |

### Supporting Infrastructure & Databases

Several application workloads are supported by dedicated background containers:

| Container | Stack | Purpose |
|---|---|---|
| `postgres` (v18) | `services-stack` (`paperless.compose.yml`) | Relational database for Paperless-ngx |
| `redis` (v8) | `services-stack` (`paperless.compose.yml`) | Message broker and task caching for Paperless celery workers |
| `gotenberg` (v8.25) | `services-stack` (`paperless.compose.yml`) | Document conversion engine (HTML, Office, EML to PDF) |
| `tika` | `services-stack` (`paperless.compose.yml`) | Apache Tika text & metadata extraction engine |
| `grimmory-db` (MariaDB) | `services-stack` (`docker-compose.yml`) | Backend SQL database for Grimmory |

### File Sharing & Ingestion

The `services-node` runs declarative **Samba (SMB)** and **WSDD** services to expose ingestion directories directly to local network clients (macOS, Windows, mobile):
- **`paperless-consume`**: Mounted to `/home/stefan/paperless-consume`, automatically ingested by Paperless-ngx.
- **`grimmory-bookdrop`**: Mounted to `/mnt/data/grimmory/bookdrop`, for dropping digital books directly into Grimmory.

### Paperless AI Integrations

> [!NOTE]
> **Paperless-GPT** is the sole active AI document processor running alongside Paperless-ngx. It handles document parsing, tagging, and metadata extraction via the `gpu-worker`'s llama-swap backend.
>
> **Paperless-AI** has been commented out of the stack — it did not provide enough additional benefit to justify running alongside Paperless-GPT.

See [home-assistant.md](home-assistant.md) for the full Home Assistant ecosystem details.
