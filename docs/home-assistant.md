# Home Assistant

This document details the smart home layer of the homelab, built around Home Assistant.

## Architecture

Unlike other services which run as Docker containers on NixOS VMs, Home Assistant runs as a dedicated **HAOS (Home Assistant Operating System) Virtual Machine** on Proxmox. This grants it direct Supervisor access and native Add-on support.

| Aspect | Detail |
|---|---|
| Status | ✅ Actively running |
| VM Type | Dedicated HAOS VM |
| Network | Attached to the IoT VLAN |
| URL | `https://homeassistant.home.stefancyliax.de` (via Caddy proxy to HAOS VM `10.1.23.162:8123` on Proxmox) |

### Reverse Proxy Configuration (Caddy)

When accessing Home Assistant through Caddy (`https://homeassistant.home.stefancyliax.de`), Home Assistant's built-in HTTP security requires Caddy's IP (`10.1.23.184`) to be explicitly trusted in Home Assistant's `configuration.yaml`. Without this, Home Assistant rejects proxied requests with HTTP `400 Bad Request`.

Add the following to `configuration.yaml` inside the HAOS VM (`10.1.23.162`) and restart Home Assistant:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.1.23.184 # Caddy reverse proxy (infra-node)
```

## Supporting Tools

While Home Assistant runs autonomously, several peripheral services support its data and physical capabilities:

### ESPHome

Manages firmware for smart switches and physical microcontrollers (ESP32/ESP8266). ESPHome devices connect to Home Assistant over the local network.

### VictoriaMetrics

Dedicated long-term time-series storage for offloading Home Assistant sensor metrics. The built-in Home Assistant recorder has limited retention — VictoriaMetrics provides high-resolution historical data with long retention (36 months) and superior compression. Home Assistant streams metrics either via its `influxdb` integration (to `http://10.1.23.184:8428/write`) or via the native `prometheus:` integration.

### Grafana

Visualization and dashboards built on top of VictoriaMetrics metrics. Used for analyzing trends in temperature, energy usage, and other sensor data over time.

See [monitoring.md](monitoring.md) for the broader monitoring stack that also uses Grafana and VictoriaMetrics.

### Frigate

Security and CCTV integration with AI-powered object detection. Frigate processes camera feeds and sends detection events to Home Assistant for automations (e.g., notifications, recording triggers).

Planned as a dedicated `frigate-node` VM on `phil`, next to HAOS, with the Iris Xe iGPU and a dedicated 512 GB SSD. See [architecture.md](architecture.md#frigate-node-nixos-vm).

## Commute Travel Time

Two sensors from the **Google Maps Travel Time** integration track the drive to work and back: `sensor.travel_time_to_work` and `sensor.travel_time_nach_hause`. Their values land in VictoriaMetrics as `min_value` (travel time in minutes) and `min_distance` (km) and feed the Commute Time dashboard in Grafana.

To stay in Google's free tier, the Google Cloud project behind the API key has a per-day request quota of about 165 requests (APIs & Services → the Maps API → Quotas & System Limits). The quota resets at midnight Pacific time, which is 08:00 or 09:00 German time depending on daylight saving time. Once it's used up, the sensors go unavailable until the reset.

The updates are scheduled so they fit inside that quota:

- **Polling is off** for both integration entries (Settings → Devices & services → Google Maps Travel Time → ⋮ → System options → "Enable polling for updates").
- **The automation "Commute travel time updates"** refreshes both sensors every 15 minutes from 03:00 until 23:00: 2 × 80 = 160 requests per day.

```yaml
alias: Commute travel time updates
triggers:
  - trigger: time_pattern
    minutes: /15
conditions:
  - condition: time
    after: "03:00:00"
    before: "23:00:00"
actions:
  - action: homeassistant.update_entity
    target:
      entity_id:
        - sensor.travel_time_to_work
        - sensor.travel_time_nach_hause
mode: single
```

## IoT VLAN

The HAOS VM is attached to a dedicated IoT VLAN managed by the Unifi controller. This isolates IoT device traffic from the main network. The routing of service traffic across this VLAN boundary is still being defined.
