{ config, pkgs, pkgs-unstable, lib, ... }:

let
  llama-cpp-cuda = pkgs-unstable.llama-cpp.override { cudaSupport = true; };
  llama-server = "${llama-cpp-cuda}/bin/llama-server";
in
{
  services.llama-swap = {
    enable = true;
    package = pkgs-unstable.llama-swap;
    listenAddress = "0.0.0.0";
    port = 8080;
    openFirewall = true;
    settings = {
      healthCheckTimeout = 120;
      models = {
        "qwen3-vl-8b" = {
          cmd = "${llama-server} --port \${PORT} --model /data/models/Qwen3-VL-8B-Instruct-Q4_K_M.gguf --mmproj /data/models/mmproj-Qwen3-VL-8B-Instruct-f16.gguf --n-gpu-layers 99 --ctx-size 16384";
          aliases = [
            "qwen3-vl"
            "vision"
          ];
          ttl = 300;
        };
      };
    };
  };
}
