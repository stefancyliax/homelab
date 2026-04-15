# GPU Worker

This document outlines the setup and provisioning of the dedicated AI/GPU workstation. This node is a physical machine (not a Proxmox VM) and is not always online to save power.

**Current status:** 🚧 Config defined, not yet provisioned.

## Hardware

| Component | Spec |
|---|---|
| GPU | Nvidia RTX 5060 Ti 16 GB |
| OS | NixOS |
| Deployment | Comin (pull model — fetches config from Git on boot) |

## Base Setup

### Nvidia Drivers

Proprietary Nvidia drivers are declared in `nodes/gpu-worker/configuration.nix`:

- `services.xserver.videoDrivers = [ "nvidia" ]`
- `hardware.nvidia.open = false` (proprietary for full CUDA/Tensor support)
- `hardware.nvidia.modesetting.enable = true`
- `hardware.graphics.enable = true` for GPU acceleration
- Verify with `nvidia-smi` after deployment.

### Container Toolkit

The Docker engine is configured with `nvidia-container-toolkit` passthrough (`hardware.nvidia-container-toolkit.enable = true`) so containerized AI workloads can access the GPU natively.

### Desktop Environment

This node doubles as a daily workstation. A desktop environment needs to be selected and provisioned via NixOS (e.g., KDE Plasma, GNOME, or Hyprland).

**Status:** 🔲 Not yet configured — CLI-only for now.

## Application Stack

### LLM Backend (Ollama)

Ollama runs as a native NixOS service with CUDA acceleration enabled (`services.ollama.acceleration = "cuda"`). The package is sourced from `nixpkgs-unstable` for the latest version.

- Listens on `0.0.0.0:11434` (firewall opened)
- Open-WebUI on the Services Node can connect to this instance as well

**Integration goal:** Connect the local AI models to services running on the main homelab (e.g., Paperless-AI on the Services Node).

### Workstation Tools

Since this node is also a workstation, the following should be provisioned:

**User Management:** 2 active user accounts.

**Applications (require desktop environment):**
- AI & Creative: ComfyUI, Bambu Studio, LLM Studio
- General: Chrome, Spotify, Obsidian, Bitwarden, Signal, Steam

**CLI & Development (✅ configured):**

| Tool | Source | Notes |
|---|---|---|
| `git`, `gh` | `configuration.nix` | Version control & GitHub CLI |
| `docker`, `docker-compose` | `common.nix` | Container runtime |
| `docker-buildx` | `configuration.nix` | Multi-platform builds |
| `neovim` | `configuration.nix` | Editor |
| `fzf`, `yazi`, `tree` | `common.nix` / `configuration.nix` | File navigation |
| `lazydocker` | `configuration.nix` | Docker TUI |
| `nvtop` | `configuration.nix` | GPU monitoring TUI |
| `pciutils` | `configuration.nix` | `lspci` for hardware diagnostics |

**Not yet packaged in nixpkgs / require further setup:**
- `ghostty` — terminal emulator (may need overlay or custom derivation)
- `walker` — application launcher (needs desktop environment)
- `gemini-cli` — Google AI CLI
- `lazyssh`, `lazyjournal` — newer lazy* tools, check nixpkgs availability

## Wake-on-LAN

To reduce power draw, this node should be suspended when idle and woken automatically when its AI endpoints are queried. Wake-on-LAN integration is planned but not yet designed.
