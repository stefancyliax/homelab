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

### LLM Backend (llama-swap)

[llama-swap](https://github.com/mostlygeek/llama-swap) runs as a native NixOS service (`services.llama-swap`) with CUDA-accelerated [llama.cpp](https://github.com/ggerganov/llama.cpp) as the inference backend. It provides an OpenAI-compatible API and automatically manages model loading/unloading.

- Declared in `modules/llama-swap.nix` (uses `pkgs-unstable` for both `llama-swap` and `llama-cpp`)
- `llama-cpp` is overridden with `cudaSupport = true` for GPU acceleration
- Listens on `0.0.0.0:8080` (firewall opened via `openFirewall = true`)
- Access restricted to Tailscale network via `listenAddress` binding

**Current models:** 
- [Qwen3-VL-8B-Instruct](https://huggingface.co/unsloth/Qwen3-VL-8B-Instruct-GGUF) (`Q4_K_M` quantization) — a vision-language model supporting both text and image inputs. Ideal for document processing (Paperless-AI/GPT) and general chat via Open-WebUI.
- [Qwen3.5-9B](https://huggingface.co/unsloth/Qwen3.5-9B-GGUF) (`Q4_K_XL` quantization) — standard text/chat model.

| Model | Context size | GPU layers | TTL | Vision projector |
|---|---|---|---|---|
| Qwen3-VL-8B | 16,384 tokens | 99 (full) | 300s | `mmproj-Qwen3VL-8B-Instruct-F16.gguf` |
| Qwen3.5-9B | 16,384 tokens | 99 (full) | 300s | N/A |

**Model files** must be downloaded manually to `/home/stefan/data/models/` on the gpu-worker:

```bash
mkdir -p /home/stefan/data/models
wget -O /home/stefan/data/models/Qwen3-VL-8B-Instruct-Q4_K_M.gguf \
  "https://huggingface.co/unsloth/Qwen3-VL-8B-Instruct-GGUF/resolve/main/Qwen3-VL-8B-Instruct-Q4_K_M.gguf"
wget -O /home/stefan/data/models/mmproj-Qwen3VL-8B-Instruct-F16.gguf \
  "https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF/resolve/main/mmproj-Qwen3VL-8B-Instruct-F16.gguf"
wget -O /home/stefan/data/models/Qwen3.5-9B-UD-Q4_K_XL.gguf \
  "https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/Qwen3.5-9B-UD-Q4_K_XL.gguf"
```

**Adding more models:** Edit `modules/llama-swap.nix` and add entries to `settings.models`. llama-swap will automatically swap between them on demand — only one model is loaded at a time (unless a `matrix` is defined).

**Integration:** Open-WebUI and other services on the Services Node can connect to this instance's API at `http://<gpu-worker-ip>:8080`.

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
