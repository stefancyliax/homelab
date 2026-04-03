# 09 - Home Assistant Ecosystem

This document details the architecture of the Smart Home layer, which is built around Home Assistant.

## 🏢 Architecture Overview
Unlike standard isolated services which run as Docker containers on NixOS VMs, Home Assistant runs as a dedicated **HAOS (Home Assistant Operating System) Virtual Machine**. This grants it direct supervisor access and native Add-on support.

* **Status:** Actively running.
* **Network:** Attached securely to the dedicated IoT VLAN.

## 🛠️ Supporting Tools

While HA runs autonomously, several peripheral services are mapped out to support its data and physical capabilities:

* **ESPHome:** Manages firmware mapping for smart switches and physical microcontrollers.
* **InfluxDB:** Dedicated long-term time-series storage for offloading Home Assistant sensor metrics.
* **Grafana:** Visualization and dashboards built natively on top of the InfluxDB metrics.
* **Frigate:** Security and CCTV integration featuring AI object detection.

## 🚀 Deployment Checklist
- [x] Provision HAOS Virtual Machine on Proxmox.
- [ ] Migrate configuration, databases, and Z-Wave/Zigbee integrations from the legacy setup to this new instance.
- [ ] Ensure HAOS correctly bridges with the IoT VLAN via Unifi controller settings.
- [ ] Deploy InfluxDB + Grafana (Likely utilizing the Services Stack docker-compose) and configure HA's `recorder` to push data.
- [ ] Stand up the ESPHome control panel.
