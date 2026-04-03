# 06 - GPU Worker Provisioning

This document outlines the required setup steps and application stack for the dedicated AI/GPU workstation attached to the homelab.

## 💻 Hardware Context
* **Role:** Dedicated physical machine for executing AI inferences and heavy analytical pipelines. This machine is *not* expected to be always online in order to save power.
* **OS:** NixOS
* **GPU:** Nvidia RTX 5060 Ti 16GB

## 🛠️ Required Setup & Tools

To prepare this node for operational AI inference, we must configure both the hardware drivers and the application stack.

### 1. Base OS & Drivers
* **Nvidia Drivers:** Proprietary Nvidia drivers must be declared in the NixOS config (`nodes/gpu-worker/configuration.nix`) to allow for CUDA and Tensor core utilization.
* **Container Tooling:** The Docker engine must be configured with Nvidia Container Toolkit (`nvidia-container-toolkit`) passthrough enabled so that AI workloads deployed via containers can natively access the GPU.

### 2. Application Stack
#### LLM Studio / Ollama
* **Purpose:** Provides a backend server and graphical/API interface for downloading and running Large Language Models locally.
* **Deployment Route:** Can be installed natively via Nix packages, or deployed as a containerized stack alongside a frontend UI (e.g., running `Open-WebUI` + `Ollama`).

### 3. Workstation Tools & Packages
Because this node also serves as a workstation and not just an inference backend, the following tools, applications, and CLI utilities should be provisioned:

* **User Management:** Configure 2 active users.
* **AI & Creative:** ComfyUI, Bambu Studio, LLM Studio.
* **General Desktop:** Chrome, Spotify, Obsidian, Bitwarden, Signal, Steam.
* **Development & CLI Utilities:**
  - `git`, `gh` (GitHub CLI)
  - `docker`, `docker-compose`, `docker-buildx`, `docker-completion`
  - `neovim`, `ghostty` (terminal emulator)
  - `yazi`, `fzf`, `tree`
  - `walker`
  - `gemini-cli`
  - `lazyssh`, `lazydocker`, `lazyjournal`

## 🚀 Deployment Checklist

> [!WARNING]
> **TODO:** Once this node is fully integrated, document the specific steps for waking the device automatically (e.g., via Wake-on-LAN from a network request) when services are needed, and suspending it when idle to reduce power draw.

### Implementation Steps
- [ ] Add `nvidia` to `services.xserver.videoDrivers` in the NixOS config.
- [ ] Enable `hardware.nvidia` specific property settings (`modesetting`, `open = false`, etc.).
- [ ] Deploy utilizing `colmena apply --on gpu-worker` and confirm `nvidia-smi` successfully reads the RTX 5060 Ti.
- [ ] Install and configure LLM Studio or the Ollama backend to accept API requests from the primary homelab network.
- [ ] **(Integration goal):** Connect these AI models back to `Paperless-ai` or `Paperless-gpt` running on the primary Services VM.
