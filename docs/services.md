# Services

This document describes the user-facing services and applications that the homelab provides. Services are deployed as Docker containers via the `services-stack/` Docker Compose files, orchestrated by Dockhand/Hawser (see [deployment.md](deployment.md)).

Some services run on dedicated VMs or specialized hardware — these are noted below. For why a service is Docker, a native NixOS service or its own VM, see [Workload Placement](architecture.md#workload-placement).

## Services

| Service | Type | Status |
|---|---|---|
| [Home Assistant](https://www.home-assistant.io/) | Dedicated HAOS VM | ✅ Running |
| [ntfy](https://ntfy.sh/) | Docker Compose (`infra-stack`) | ✅ Functional |
| [Pi-hole](https://pi-hole.net/) | Docker Compose (`infra-stack`) | 🚧 Configured — opt-in per device |
| [ZeroByte](https://github.com/nicotsx/zerobyte) | Docker Compose (`services-stack`) | ✅ Functional |
| [Paperless-ngx](https://docs.paperless-ngx.com/) | Docker Compose (`services-stack`) | ✅ Functional |
| Samba & WSDD | Native NixOS service (`services-node`) | ✅ Functional |
| [Jellyfin](https://jellyfin.org/) | Docker Compose (`storage-stack`, `storage-node` on `vault`) | ✅ Running |
| [Frigate](https://frigate.video/) | Docker Compose (`frigate-stack`, `frigate-node` on `phil`) | 🔲 Planned |
| NAS shares (Samba/NFS) | Native NixOS service (`storage-node`) | 🔲 Planned |
| [Garage](https://garagehq.deuxfleurs.fr/) S3 | Native NixOS service (`agent-tools-node`) | ✅ Running |
| Artifact hosting (Claude/Gemini) | Garage website bucket (`agent-tools-node`) + Caddy route | ✅ Running |
| [Proxmox Datacenter Manager](https://pdm.proxmox.com/docs/) | Appliance VM (`phil`) | ✅ Running |
| Scanner service (HP ScanJet Pro 2600 f1) | Docker Compose (`storage-stack`, `storage-node` on `vault`) | ✅ Functional |
| ~~[n8n](https://n8n.io/)~~ | Docker Compose (`services-stack`) | ❌ Removed |
| [NocoDB](https://nocodb.com/) | Docker Compose (`agent-tools-stack`, `agent-tools-node` on `vault`) | ✅ Running |
| ~~[Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF)~~ | Docker Compose (`services-stack`) | ❌ Dropped |
| [Grimmory](https://github.com/grimmory-tools/grimmory) | Docker Compose (`services-stack`) | ✅ Functional |
| [Open-WebUI](https://github.com/open-webui/open-webui) | Docker Compose (`agent-tools-stack`, `agent-tools-node` on `vault`) | 🚧 Deployed |
| ~~[ESPHome](https://esphome.io/)~~ | ~~Docker Compose (`services-stack`)~~ | ❌ Dropped |
| ~~[Tududi](https://github.com/chrisvel/tududi)~~ | Docker Compose (`services-stack`) | ❌ Dropped |
| [BamBuddy](https://bambuddy.cool/index.html) | Docker Compose (`storage-stack`, `storage-node` on `vault`) | 🔲 Planned |
| ~~[Paperless-AI](https://github.com/clusterzx/paperless-ai)~~ | Docker Compose (`services-stack`) | ❌ Dropped |
| [Paperless-GPT](https://github.com/icereed/paperless-gpt) | Docker Compose (`services-stack`) | ✅ Functional |
| [NextExplorer](https://github.com/nxzai/explorer) | Docker Compose (`storage-stack`, `storage-node` on `vault`) | 🚧 Deployed |
| ~~[Ollama](https://ollama.com/)~~ | ~~Dedicated NixOS VM (`ollama-node`)~~ | ❌ Deprecated |
| [llama-swap](https://github.com/mostlygeek/llama-swap) | Native NixOS service (`gpu-worker`) | ✅ Functional |
| [Parakeet (STT)](https://github.com/achetronic/parakeet) | Docker Compose (`agent-tools-stack`, `agent-tools-node` on `vault`) | ✅ Running |
| ~~[Kestra](https://kestra.io/)~~ | Docker Compose (`services-stack`) | ❌ Removed |
| [Hindsight](https://github.com/vectorize-io/hindsight) | Docker Compose (`agent-tools-stack`, `agent-tools-node` on `vault`) | 🚧 Deployed |
| [Hindsight](https://github.com/vectorize-io/hindsight) (work instance) | Docker Compose (`work-tools-stack`, `work-tools-node` on `phil`) | 🚧 Deployed |
| pilot | To be defined (`agent-tools-node`) | 🔲 Planned |
| Embedding Service (`google/embeddinggemma-2`) | Docker Compose (`agent-tools-stack`, `agent-tools-node` on `vault`) | 🚧 Deployed |
| Extraction SLM (Gemma 4 E2B) | Docker Compose (`agent-tools-stack`, `agent-tools-node` on `vault`) | 🚧 Deployed |
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

### Pi-hole (DNS)

Pi-hole v6 runs in the `infra-stack` on `infra-node` (`10.1.23.184`) and serves DNS on port 53 (TCP/UDP). The admin UI is not published directly; it is reached through Caddy at `pihole.home.stefancyliax.de` behind Authelia.

- **Configuration:** declared through `FTLCONF_*` environment variables in `infra-stack/docker-compose.yml`. Settings set this way are read-only in the web UI; blocklists, local records and groups are managed in the UI and live in the `pihole_data` volume.
- **Upstreams:** Cloudflare (`1.1.1.1`, `1.0.0.1`).
- **Homelab domain:** `*.home.stefancyliax.de` resolves locally to `10.1.23.184` via a dnsmasq `address=` line, so LAN clients don't depend on the public Porkbun record.
- **Listening mode `all`:** needed in Docker bridge mode, because queries arrive from the LAN, the IoT VLAN and Tailscale (via the subnet router), never from the container's own subnet. Port 53 is not forwarded from the WAN.
- **Password:** `PIHOLE_PASSWORD` is set as a stack environment variable in Dockhand (like `GRAFANA_ADMIN_PASSWORD`). Homepage gets the same value as `HOMEPAGE_VAR_PIHOLE_PASSWORD` for its Pi-hole widget.

**Opt-in per device:** Unifi DHCP keeps handing out its own DNS, so the network as a whole doesn't depend on Pi-hole. Only selected devices use it:

- **Manual DNS on the device:** set `10.1.23.184` as the only DNS server in the device's network settings (macOS/iOS per Wi-Fi network, Windows per adapter). Don't add a public resolver as second server: the device picks either one and bypasses blocking. Android has no manual DNS for DHCP Wi-Fi; use a static IP there or the Tailscale route below.
- **Separate Unifi network (optional):** if more devices should use it, create a VLAN/SSID whose DHCP hands out `10.1.23.184` and move those devices onto it.
- **Remote devices:** Tailscale DNS is tailnet-wide, so it is not a per-device switch. Leave it unchanged unless all tailnet devices should be filtered.

Test after deploying: `dig @10.1.23.184 example.com` and `dig @10.1.23.184 grafana.home.stefancyliax.de`.

> [!NOTE]
> If `infra-node` is down, only the opted-in devices lose DNS. Switching such a device back to automatic DNS restores it. The servers and the rest of the network keep using Unifi.

### File Sharing & Ingestion

The `services-node` runs declarative **Samba (SMB)** and **WSDD** services to expose ingestion directories directly to local network clients (macOS, Windows, mobile):
- **`paperless-consume`**: Mounted to `/home/stefan/paperless-consume`, automatically ingested by Paperless-ngx. `storage-node` mounts this share at `/mnt/paperless-consume` as the output directory of the scanner service.
- **`grimmory-bookdrop`**: Mounted to `/mnt/data/grimmory/bookdrop`, for dropping digital books directly into Grimmory.

### Paperless AI Integrations

> [!NOTE]
> **Paperless-GPT** is the sole active AI document processor running alongside Paperless-ngx. It handles document parsing, tagging, and metadata extraction via the `gpu-worker`'s llama-swap backend.
>
> **Paperless-AI** has been dropped — it did not provide enough additional benefit to justify running alongside Paperless-GPT.

See [home-assistant.md](home-assistant.md) for the full Home Assistant ecosystem details.
