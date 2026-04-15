# GPU Worker

This document outlines the setup and provisioning of the dedicated AI/GPU workstation. This node is a physical machine (not a Proxmox VM) and is not always online to save power.

**Current status:** 🔲 Not yet provisioned.

## Hardware

| Component | Spec |
|---|---|
| GPU | Nvidia RTX 5060 Ti 16 GB |
| OS | NixOS |
| Deployment | Comin (pull model — fetches config from Git on boot) |

## Base Setup

### Nvidia Drivers

Proprietary Nvidia drivers must be declared in the NixOS config (`nodes/gpu-worker/configuration.nix`) to enable CUDA and Tensor core utilization:

- Add `nvidia` to `services.xserver.videoDrivers`.
- Enable `hardware.nvidia` settings (`modesetting`, `open = false`, etc.).
- Verify with `nvidia-smi` after deployment.

### Container Toolkit

The Docker engine must be configured with `nvidia-container-toolkit` passthrough so that containerized AI workloads can access the GPU natively.

### Desktop Environment

This node doubles as a daily workstation. A desktop environment needs to be selected and provisioned via NixOS (e.g., KDE Plasma, GNOME, or Hyprland).

## Application Stack

### LLM Backend (Ollama)

Provides a backend server for downloading and running Large Language Models locally. Can be deployed natively via Nix packages or as a containerized stack (e.g., Ollama + Open-WebUI).

**Integration goal:** Connect the local AI models to services running on the main homelab (e.g., Paperless-AI on the Services Node).

### Workstation Tools

Since this node is also a workstation, the following should be provisioned:

**User Management:** 2 active user accounts.

**Applications:**
- AI & Creative: ComfyUI, Bambu Studio, LLM Studio
- General: Chrome, Spotify, Obsidian, Bitwarden, Signal, Steam

**CLI & Development:**
- `git`, `gh` (GitHub CLI)
- `docker`, `docker-compose`, `docker-buildx`
- `neovim`, `ghostty` (terminal emulator)
- `yazi`, `fzf`, `tree`
- `walker`
- `gemini-cli`
- `lazyssh`, `lazydocker`, `lazyjournal`

## Wake-on-LAN

To reduce power draw, this node should be suspended when idle and woken automatically when its AI endpoints are queried. Wake-on-LAN integration is planned but not yet designed.
