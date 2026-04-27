# GPU Worker

This document outlines the setup and provisioning of the dedicated AI worker node. This node is a physical machine (not a Proxmox VM) and is not always online to save power. It serves exclusively as an AI inference backend — no desktop environment is installed.

**Current status:** ✅ Functional.

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

> [!NOTE]
> This node was originally considered as a dual-purpose workstation/AI worker, but the decision was made to keep it as a dedicated AI inference node only. No desktop environment is installed.

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
- [GLM-OCR](https://huggingface.co/ggml-org/GLM-OCR-GGUF) (`f16` quantization) — an alternative vision model optimized specifically for OCR tasks.
- [Gemma 4 E4B](https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF) (`Q4_K_M` quantization) — highly efficient text model optimized for edge devices, ideal for fast parallel tagging.
- [MinerU 2.5 Pro](https://huggingface.co/mradermacher/MinerU2.5-Pro-2604-1.2B-GGUF) (`f16` quantization) — specialized multimodal model for document parsing and structure extraction.
- [MiniCPM-V 2.6](https://huggingface.co/openbmb/MiniCPM-V-2_6-gguf) (`Q4_K_M` quantization) — a highly capable 8B multimodal model, excellent alternative for OCR and visual reasoning.
- [MiniCPM-V 4.5](https://huggingface.co/openbmb/MiniCPM-V-4_5-gguf) (`Q4_K_M` quantization) — the bleeding-edge iteration of MiniCPM-V, boasting better OCR accuracy.
- [Nemotron-Nano-12B-VL](https://huggingface.co/Vastined/NVIDIA-Nemotron-Nano-12B-v2-VL-BF16-GGUF) (`Q5_K_M` quantization) — NVIDIA's 12B multimodal model with strong OCR capabilities.
- **GLM-OCR CPU** (`f16` quantization) — the same GLM-OCR model, but executed entirely on the CPU (`-ngl 0`) via `llama-swap`. Useful for saving VRAM.

| Model | Context size | GPU layers | TTL | Vision projector |
|---|---|---|---|---|
| Qwen3-VL-8B | 51,200 tokens | 99 (full) | 300s | `mmproj-Qwen3VL-8B-Instruct-F16.gguf` |
| Qwen3.5-9B | 51,200 tokens | 99 (full) | 300s | N/A |
| GLM-OCR | 16,384 tokens | 99 (full) | 300s | `mmproj-GLM-OCR-Q8_0.gguf` |
| Gemma4 E4B | 32,768 tokens | 99 (full) | 300s | `mmproj-gemma-4-E4B-F16.gguf` |
| MinerU 2.5 | 16,384 tokens | 99 (full) | 300s | `MinerU2.5-Pro-2604-1.2B.mmproj-f16.gguf` |
| MiniCPM-V 2.6 | 16,384 tokens | 99 (full) | 300s | `minicpm-v-2.6-mmproj-f16.gguf` |
| MiniCPM-V 4.5 | 16,384 tokens | 99 (full) | 300s | `minicpm-v-4.5-mmproj-f16.gguf` |
| Nemotron-Nano 12B | 16,384 tokens | 99 (full) | 300s | `NVIDIA-Nemotron-Nano-12B-v2-VL-BF16-mmproj.gguf` |
| GLM-OCR (CPU) | 16,384 tokens | 0 (CPU only) | 300s | `mmproj-GLM-OCR-Q8_0.gguf` |

**Model files** must be downloaded manually to `/var/lib/models/` on the gpu-worker. Since `/var/lib` is owned by root, use `sudo`:

```bash
sudo mkdir -p /var/lib/models
sudo wget -O /var/lib/models/Qwen3-VL-8B-Instruct-Q4_K_M.gguf \
  "https://huggingface.co/unsloth/Qwen3-VL-8B-Instruct-GGUF/resolve/main/Qwen3-VL-8B-Instruct-Q4_K_M.gguf"
sudo wget -O /var/lib/models/mmproj-Qwen3VL-8B-Instruct-F16.gguf \
  "https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF/resolve/main/mmproj-Qwen3VL-8B-Instruct-F16.gguf"
sudo wget -O /var/lib/models/Qwen3.5-9B-UD-Q4_K_XL.gguf \
  "https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/Qwen3.5-9B-UD-Q4_K_XL.gguf"
sudo wget -O /var/lib/models/GLM-OCR-f16.gguf \
  "https://huggingface.co/ggml-org/GLM-OCR-GGUF/resolve/main/GLM-OCR-f16.gguf"
sudo wget -O /var/lib/models/mmproj-GLM-OCR-Q8_0.gguf \
  "https://huggingface.co/ggml-org/GLM-OCR-GGUF/resolve/main/mmproj-GLM-OCR-Q8_0.gguf"
sudo wget -O /var/lib/models/gemma-4-E4B-it-Q4_K_M.gguf \
  "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_K_M.gguf"
sudo wget -O /var/lib/models/mmproj-gemma-4-E4B-F16.gguf \
  "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/mmproj-F16.gguf"
sudo wget -O /var/lib/models/MinerU2.5-Pro-2604-1.2B.f16.gguf \
  "https://huggingface.co/mradermacher/MinerU2.5-Pro-2604-1.2B-GGUF/resolve/main/MinerU2.5-Pro-2604-1.2B.f16.gguf"
sudo wget -O /var/lib/models/MinerU2.5-Pro-2604-1.2B.mmproj-f16.gguf \
  "https://huggingface.co/mradermacher/MinerU2.5-Pro-2604-1.2B-GGUF/resolve/main/MinerU2.5-Pro-2604-1.2B.mmproj-f16.gguf"
sudo wget -O /var/lib/models/minicpm-v-2.6-Q4_K_M.gguf \
  "https://huggingface.co/openbmb/MiniCPM-V-2_6-gguf/resolve/main/ggml-model-Q4_K_M.gguf"
sudo wget -O /var/lib/models/minicpm-v-2.6-mmproj-f16.gguf \
  "https://huggingface.co/openbmb/MiniCPM-V-2_6-gguf/resolve/main/mmproj-model-f16.gguf"
sudo wget -O /var/lib/models/minicpm-v-4.5-Q4_K_M.gguf \
  "https://huggingface.co/openbmb/MiniCPM-V-4_5-gguf/resolve/main/ggml-model-Q4_K_M.gguf"
sudo wget -O /var/lib/models/minicpm-v-4.5-mmproj-f16.gguf \
  "https://huggingface.co/openbmb/MiniCPM-V-4_5-gguf/resolve/main/mmproj-model-f16.gguf"
sudo wget -O /var/lib/models/NVIDIA-Nemotron-Nano-12B-v2-VL-Q5_K_M.gguf \
  "https://huggingface.co/Vastined/NVIDIA-Nemotron-Nano-12B-v2-VL-BF16-GGUF/resolve/main/NVIDIA-Nemotron-Nano-12B-v2-VL-Q5_K_M.gguf"
sudo wget -O /var/lib/models/NVIDIA-Nemotron-Nano-12B-v2-VL-BF16-mmproj.gguf \
  "https://huggingface.co/Vastined/NVIDIA-Nemotron-Nano-12B-v2-VL-BF16-GGUF/resolve/main/NVIDIA-Nemotron-Nano-12B-v2-VL-BF16-mmproj.gguf"
```

**Adding more models:** Edit `modules/llama-swap.nix` and add entries to `settings.models`. llama-swap will automatically swap between them on demand — only one model is loaded at a time (unless a `matrix` is defined).

**Integration:** Open-WebUI and other services on the Services Node can connect to this instance's API at `http://<gpu-worker-ip>:8080`.

### System Tools

The following CLI tools are provisioned on the GPU Worker for administration and diagnostics:

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

## Wake-on-LAN

To reduce power draw, this node should be suspended when idle and woken automatically when its AI endpoints are queried. Wake-on-LAN integration is planned but not yet designed.
