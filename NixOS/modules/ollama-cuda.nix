{ config, pkgs, pkgs-unstable, ... }:

{
  # Ollama LLM service with CUDA GPU acceleration (from nixpkgs-unstable)
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-cuda;
    host = "0.0.0.0";
    port = 11434;
    openFirewall = true;
    acceleration = "cuda";
  };
}
