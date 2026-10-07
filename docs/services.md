# Services

This document describes the user-facing services and applications that the homelab provides. Services are deployed as Docker containers via the `services-stack/` Docker Compose files, orchestrated by Dockhand/Hawser (see [deployment.md](deployment.md)).

Some services run on dedicated VMs or specialized hardware — these are noted below. For why a service is Docker, a native NixOS service or its own VM, see [Workload Placement](architecture.md#workload-placement).

## Services

| Service | Type | Status |
|---|---|---|
| [Home Assistant](https://www.home-assistant.io/) | Dedicated HAOS VM | ✅ Running |
| [ntfy](https://ntfy.sh/) | Docker Compose (`infra-stack`) | ✅ Functional |
| [ZeroByte](https://github.com/nicotsx/zerobyte) | Docker Compose (`services-stack`) | ✅ Functional |
| [Paperless-ngx](https://docs.paperless-ngx.com/) | Docker Compose (`services-stack`) | ✅ Functional |
| Samba & WSDD | Native NixOS service (`services-node`) | ✅ Functional |
| [Jellyfin](https://jellyfin.org/) | Docker Compose (`storage-stack`, `storage-node` on `vault`) | 🔲 Planned |
| [Frigate](https://frigate.video/) | Docker Compose (`frigate-stack`, `frigate-node` on `phil`) | 🔲 Planned |
| NAS shares (Samba/NFS) | Native NixOS service (`storage-node`) | 🔲 Planned |
| [Garage](https://garagehq.deuxfleurs.fr/) S3 | Native NixOS service (`agent-tools-node`) | 🔲 Planned |
| Artifact hosting (Claude/Gemini) | Garage website bucket (`agent-tools-node`) + Caddy route | 🔲 Planned |
| [Proxmox Datacenter Manager](https://pdm.proxmox.com/docs/) | Appliance VM (`phil`) | ✅ Running |
| Scanner service (HP ScanJet Pro 2600 f1) | Docker Compose (`services-node`) | ✅ Running — 🔲 move to `storage-node` planned |
| ~~[n8n](https://n8n.io/)~~ | Docker Compose (`services-stack`) | ❌ Removed |
| [NocoDB](https://nocodb.com/) | Docker Compose (`services-stack`) | 🚧 Deployed — 🔲 move to `agent-tools-node` planned |
| ~~[Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF)~~ | Docker Compose (`services-stack`) | ❌ Dropped |
| [Grimmory](https://github.com/grimmory-tools/grimmory) | Docker Compose (`services-stack`) | 🚧 Deployed |
| [Open-WebUI](https://github.com/open-webui/open-webui) | Docker Compose (`services-stack`) | 🚧 Deployed — 🔲 move to `agent-tools-node` planned |
| ~~[ESPHome](https://esphome.io/)~~ | ~~Docker Compose (`services-stack`)~~ | ❌ Dropped |
| ~~[Tududi](https://github.com/chrisvel/tududi)~~ | Docker Compose (`services-stack`) | ❌ Dropped |
| [BamBuddy](https://bambuddy.cool/index.html) | Docker Compose (`storage-stack`, `storage-node` on `vault`) | 🔲 Planned |
| ~~[Paperless-AI](https://github.com/clusterzx/paperless-ai)~~ | Docker Compose (`services-stack`) | ❌ Dropped |
| [Paperless-GPT](https://github.com/icereed/paperless-gpt) | Docker Compose (`services-stack`) | ✅ Functional |
| [NextExplorer](https://github.com/nxzai/explorer) | Docker Compose (`storage-stack`, `storage-node` on `vault`) | 🚧 Deployed |
| ~~[Ollama](https://ollama.com/)~~ | ~~Dedicated NixOS VM (`ollama-node`)~~ | ❌ Deprecated |
| [llama-swap](https://github.com/mostlygeek/llama-swap) | Native NixOS service (`gpu-worker`) | ✅ Functional |
| [Parakeet](https://github.com/achetronic/parakeet) | Docker Compose (`services-stack`) | 🚧 Deployed — 🔲 move to `agent-tools-node` planned |
| ~~[Kestra](https://kestra.io/)~~ | Docker Compose (`services-stack`) | ❌ Removed |
| [Hindsight](https://github.com/vectorize-io/hindsight) | Docker Compose (`services-stack`) | 🚧 Deployed — 🔲 move to `agent-tools-node` planned |
| [Hindsight](https://github.com/vectorize-io/hindsight) (work instance) | Docker Compose (`work-tools-stack`, `work-tools-node` on `phil`) | 🚧 Deployed |
| pilot | To be defined (`agent-tools-node`) | 🔲 Planned |
| Hermes Chat | Native service (`hermes-node`) | 🚧 Deployed — 🔲 move to `agent-node` planned |
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
> **Paperless-AI** has been dropped — it did not provide enough additional benefit to justify running alongside Paperless-GPT. Its commented-out block in the compose file is still to be removed.

See [home-assistant.md](home-assistant.md) for the full Home Assistant ecosystem details.
