{ config, pkgs, pkgs-unstable, lib, ... }:

let
  llama-cpp-cuda = pkgs-unstable.llama-cpp.override { cudaSupport = true; };
  llama-server = "${llama-cpp-cuda}/bin/llama-server";
in
{
  # Use the llama-swap module from nixpkgs-unstable (has listenAddress option)
  disabledModules = [ "services/networking/llama-swap.nix" ];
  imports = [ "${pkgs-unstable.path}/nixos/modules/services/networking/llama-swap.nix" ];

  services.llama-swap = {
    enable = true;
    package = pkgs-unstable.llama-swap;
    listenAddress = "100.90.253.20";
    port = 8080;
    openFirewall = true;
    settings = {
      healthCheckTimeout = 120;
      models = {
        "qwen3-vl-8b" = {
          cmd = "${llama-server} --port \${PORT} --model /var/lib/models/Qwen3-VL-8B-Instruct-Q4_K_M.gguf --mmproj /var/lib/models/mmproj-Qwen3VL-8B-Instruct-F16.gguf --n-gpu-layers 99 --ctx-size 51200";
          aliases = [
            "qwen3-vl"
            "vision"
          ];
          ttl = 300;
        };
        "qwen3.5-9b" = {
          cmd = "${llama-server} --port \${PORT} --model /var/lib/models/Qwen3.5-9B-UD-Q4_K_XL.gguf --n-gpu-layers 99 --ctx-size 16384";
          aliases = [
            "qwen3.5"
            "chat"
          ];
          ttl = 300;
        };
        "glm-ocr" = {
          cmd = "${llama-server} --port \${PORT} --model /var/lib/models/GLM-OCR-f16.gguf --mmproj /var/lib/models/mmproj-GLM-OCR-Q8_0.gguf --n-gpu-layers 99 --ctx-size 16384";
          aliases = [
            "glm"
          ];
          ttl = 300;
        };
        "gemma4" = {
          cmd = "${llama-server} --port \${PORT} --model /var/lib/models/gemma-4-E4B-it-Q4_K_M.gguf --mmproj /var/lib/models/mmproj-gemma-4-E4B-F16.gguf --n-gpu-layers 99 --ctx-size 32768 --image-min-tokens 1024 --image-max-tokens 2240";
          aliases = [
            "gemma4-e4b"
          ];
          ttl = 300;
        };
        "mineru" = {
          cmd = "${llama-server} --port \${PORT} --model /var/lib/models/MinerU2.5-Pro-2604-1.2B.f16.gguf --mmproj /var/lib/models/MinerU2.5-Pro-2604-1.2B.mmproj-f16.gguf --n-gpu-layers 99 --ctx-size 16384";
          aliases = [
            "mineru"
            "miner-u"
          ];
          ttl = 300;
        };
      };
    };
  };
}
