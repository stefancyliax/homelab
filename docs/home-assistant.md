# Home Assistant

This document details the smart home layer of the homelab, built around Home Assistant.

## Architecture

Unlike other services which run as Docker containers on NixOS VMs, Home Assistant runs as a dedicated **HAOS (Home Assistant Operating System) Virtual Machine** on Proxmox. This grants it direct Supervisor access and native Add-on support.

| Aspect | Detail |
|---|---|
| Status | ✅ Actively running |
| VM Type | Dedicated HAOS VM |
| Network | Attached to the IoT VLAN |
| Migration | Pending — config and data need to be migrated from the legacy instance |

## Supporting Tools

While Home Assistant runs autonomously, several peripheral services support its data and physical capabilities:

### ESPHome

Manages firmware for smart switches and physical microcontrollers (ESP32/ESP8266). ESPHome devices connect to Home Assistant over the local network.

### InfluxDB

Dedicated long-term time-series storage for offloading Home Assistant sensor metrics. The built-in Home Assistant recorder has limited retention — InfluxDB provides high-resolution historical data.

### Grafana

Visualization and dashboards built on top of InfluxDB metrics. Used for analyzing trends in temperature, energy usage, and other sensor data over time.

See [monitoring.md](monitoring.md) for the broader monitoring stack that also uses Grafana and InfluxDB.

### Frigate

Security and CCTV integration with AI-powered object detection. Frigate processes camera feeds and sends detection events to Home Assistant for automations (e.g., notifications, recording triggers).

## IoT VLAN

The HAOS VM is attached to a dedicated IoT VLAN managed by the Unifi controller. This isolates IoT device traffic from the main network. The routing of service traffic across this VLAN boundary is still being defined.
