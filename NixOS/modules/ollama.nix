{ config, pkgs, pkgs-unstable, ... }:

{
  # Enable the native Ollama service (from nixpkgs-unstable for latest version)
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama;
    host = "0.0.0.0";
    port = 11434;
    openFirewall = true;
  };
}
